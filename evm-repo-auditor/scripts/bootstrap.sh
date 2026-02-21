#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/bootstrap.sh --repo <url-or-local-path> [options]

Options:
  --repo <value>         Git URL or local repo path (required)
  --branch <name>        Branch to checkout (default: repository default branch)
  --workspace <dir>      Clone destination root for URL inputs (default: .audit-workspace)
  --depth <n>            Clone depth for URL inputs (default: 1)
  --skip-install         Skip dependency installation
  --skip-verify          Skip build/test smoke checks
  --force-reclone        Reclone if target workspace directory already exists
  --help                 Show this message
EOF
}

REPO_INPUT=""
BRANCH=""
WORKSPACE="$PWD/.audit-workspace"
DEPTH="1"
SKIP_INSTALL="0"
SKIP_VERIFY="0"
FORCE_RECLONE="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      REPO_INPUT="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --workspace)
      WORKSPACE="${2:-}"
      shift 2
      ;;
    --depth)
      DEPTH="${2:-}"
      shift 2
      ;;
    --skip-install)
      SKIP_INSTALL="1"
      shift
      ;;
    --skip-verify)
      SKIP_VERIFY="1"
      shift
      ;;
    --force-reclone)
      FORCE_RECLONE="1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[ -n "$REPO_INPUT" ] || {
  usage
  die "--repo is required"
}

require_cmd git

REPO_DIR=""
if is_repo_url "$REPO_INPUT"; then
  mkdir -p "$WORKSPACE"
  WORKSPACE="$(abs_path "$WORKSPACE")"
  REPO_SLUG="$(repo_slug_from_url "$REPO_INPUT")"
  TARGET_DIR="$WORKSPACE/$REPO_SLUG"

  if [ -d "$TARGET_DIR" ] && [ "$FORCE_RECLONE" = "1" ]; then
    log "Removing existing clone at $TARGET_DIR (--force-reclone)"
    rm -rf "$TARGET_DIR"
  fi

  if [ -d "$TARGET_DIR/.git" ]; then
    log "Using existing clone at $TARGET_DIR"
  else
    log "Cloning $REPO_INPUT to $TARGET_DIR (depth=$DEPTH)"
    if [ -n "$BRANCH" ]; then
      git clone --depth "$DEPTH" --branch "$BRANCH" "$REPO_INPUT" "$TARGET_DIR"
    else
      git clone --depth "$DEPTH" "$REPO_INPUT" "$TARGET_DIR"
    fi
  fi
  REPO_DIR="$TARGET_DIR"
else
  [ -d "$REPO_INPUT" ] || die "Local path does not exist: $REPO_INPUT"
  REPO_DIR="$(abs_path "$REPO_INPUT")"
fi

if [ -n "$BRANCH" ] && [ -d "$REPO_DIR/.git" ]; then
  log "Checking out branch $BRANCH"
  git -C "$REPO_DIR" checkout "$BRANCH"
fi

META_DIR="$REPO_DIR/.audit-meta"
SUBMISSION_DIR="$REPO_DIR/submission"
LOG_DIR="$REPO_DIR/logs"
ENV_FILE="$META_DIR/env.sh"
mkdir -p "$META_DIR" "$SUBMISSION_DIR" "$LOG_DIR"

FRAMEWORK="$(detect_framework "$REPO_DIR")"
IFS='|' read -r PACKAGE_MANAGER INSTALL_CMD <<< "$(detect_package_manager "$REPO_DIR")"

BUILD_CMD=""
TEST_CMD=""
case "$FRAMEWORK" in
  foundry)
    BUILD_CMD="forge build"
    TEST_CMD="forge test --allow-failure"
    ;;
  hardhat)
    if [ "$PACKAGE_MANAGER" != "none" ] && has_package_script "$REPO_DIR" "compile"; then
      BUILD_CMD="$(js_script_cmd "$PACKAGE_MANAGER" "compile")"
    else
      BUILD_CMD="npx hardhat compile"
    fi
    if [ "$PACKAGE_MANAGER" != "none" ] && has_package_script "$REPO_DIR" "test"; then
      TEST_CMD="$(js_script_cmd "$PACKAGE_MANAGER" "test")"
    else
      TEST_CMD="npx hardhat test"
    fi
    ;;
  truffle)
    if [ "$PACKAGE_MANAGER" != "none" ] && has_package_script "$REPO_DIR" "compile"; then
      BUILD_CMD="$(js_script_cmd "$PACKAGE_MANAGER" "compile")"
    else
      BUILD_CMD="npx truffle compile"
    fi
    if [ "$PACKAGE_MANAGER" != "none" ] && has_package_script "$REPO_DIR" "test"; then
      TEST_CMD="$(js_script_cmd "$PACKAGE_MANAGER" "test")"
    else
      TEST_CMD="npx truffle test"
    fi
    ;;
  *)
    if [ "$PACKAGE_MANAGER" != "none" ] && has_package_script "$REPO_DIR" "build"; then
      BUILD_CMD="$(js_script_cmd "$PACKAGE_MANAGER" "build")"
    fi
    if [ "$PACKAGE_MANAGER" != "none" ] && has_package_script "$REPO_DIR" "test"; then
      TEST_CMD="$(js_script_cmd "$PACKAGE_MANAGER" "test")"
    fi
    ;;
esac

INSTALL_STATUS="skipped"
if [ "$SKIP_INSTALL" = "0" ] && [ -f "$REPO_DIR/package.json" ] && [ -n "$INSTALL_CMD" ]; then
  if command -v "$PACKAGE_MANAGER" >/dev/null 2>&1; then
    log "Installing dependencies with $PACKAGE_MANAGER"
    if (cd "$REPO_DIR" && bash -lc "$INSTALL_CMD" > "$LOG_DIR/install.log" 2>&1); then
      INSTALL_STATUS="ok"
    else
      INSTALL_STATUS="failed"
      warn "Dependency installation failed. See $LOG_DIR/install.log"
    fi
  else
    INSTALL_STATUS="missing-$PACKAGE_MANAGER"
    warn "Package manager '$PACKAGE_MANAGER' is not installed."
  fi
fi

BUILD_STATUS="skipped"
if [ "$SKIP_VERIFY" = "0" ] && [ -n "$BUILD_CMD" ]; then
  log "Running build command"
  if (cd "$REPO_DIR" && bash -lc "$BUILD_CMD" > "$LOG_DIR/build.log" 2>&1); then
    BUILD_STATUS="ok"
  else
    BUILD_STATUS="failed"
    warn "Build command failed. See $LOG_DIR/build.log"
  fi
fi

TEST_STATUS="skipped"
if [ "$SKIP_VERIFY" = "0" ] && [ -n "$TEST_CMD" ]; then
  log "Running test command"
  if (cd "$REPO_DIR" && bash -lc "$TEST_CMD" > "$LOG_DIR/test.log" 2>&1); then
    TEST_STATUS="ok"
  else
    TEST_STATUS="failed"
    warn "Test command failed. See $LOG_DIR/test.log"
  fi
fi

BASE_COMMIT=""
if [ -d "$REPO_DIR/.git" ]; then
  BASE_COMMIT="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || true)"
fi

{
  printf 'export AUDIT_REPO_DIR=%q\n' "$REPO_DIR"
  printf 'export AUDIT_FRAMEWORK=%q\n' "$FRAMEWORK"
  printf 'export AUDIT_PACKAGE_MANAGER=%q\n' "$PACKAGE_MANAGER"
  printf 'export AUDIT_INSTALL_CMD=%q\n' "$INSTALL_CMD"
  printf 'export AUDIT_BUILD_CMD=%q\n' "$BUILD_CMD"
  printf 'export AUDIT_TEST_CMD=%q\n' "$TEST_CMD"
  printf 'export AUDIT_BASE_COMMIT=%q\n' "$BASE_COMMIT"
  printf 'export AUDIT_META_DIR=%q\n' "$META_DIR"
  printf 'export AUDIT_SUBMISSION_DIR=%q\n' "$SUBMISSION_DIR"
  printf 'export AUDIT_LOG_DIR=%q\n' "$LOG_DIR"
  printf 'export AUDIT_INSTALL_STATUS=%q\n' "$INSTALL_STATUS"
  printf 'export AUDIT_BUILD_STATUS=%q\n' "$BUILD_STATUS"
  printf 'export AUDIT_TEST_STATUS=%q\n' "$TEST_STATUS"
} > "$ENV_FILE"

cat > "$META_DIR/bootstrap-summary.md" <<EOF
# Bootstrap Summary

- Repo: \`$REPO_DIR\`
- Framework: \`$FRAMEWORK\`
- Package manager: \`$PACKAGE_MANAGER\`
- Base commit: \`${BASE_COMMIT:-N/A}\`
- Install status: \`$INSTALL_STATUS\`
- Build status: \`$BUILD_STATUS\`
- Test status: \`$TEST_STATUS\`
- Env file: \`$ENV_FILE\`
EOF

log "Bootstrap finished."
printf 'REPO_DIR=%s\n' "$REPO_DIR"
printf 'ENV_FILE=%s\n' "$ENV_FILE"
