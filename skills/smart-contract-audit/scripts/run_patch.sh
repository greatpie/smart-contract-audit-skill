#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/run_patch.sh --repo-dir <path> [--strict]

Options:
  --repo-dir <path>   Target repository path (required)
  --strict            Fail if build/test checks fail
  --help              Show this message
EOF
}

REPO_DIR=""
STRICT="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-dir)
      REPO_DIR="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT="1"
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

[ -n "$REPO_DIR" ] || {
  usage
  die "--repo-dir is required"
}

REPO_DIR="$(abs_path "$REPO_DIR")"
[ -d "$REPO_DIR" ] || die "Repo path does not exist: $REPO_DIR"

ENV_FILE="$REPO_DIR/.audit-meta/env.sh"
[ -f "$ENV_FILE" ] || die "Missing bootstrap metadata: $ENV_FILE. Run scripts/bootstrap.sh first."
source "$ENV_FILE"

mkdir -p "$AUDIT_SUBMISSION_DIR" "$AUDIT_LOG_DIR"

BUILD_STATUS="skipped"
if [ -n "${AUDIT_BUILD_CMD:-}" ]; then
  log "Running build check for patch validation"
  if (cd "$AUDIT_REPO_DIR" && bash -lc "$AUDIT_BUILD_CMD" > "$AUDIT_LOG_DIR/patch-build.log" 2>&1); then
    BUILD_STATUS="ok"
  else
    BUILD_STATUS="failed"
    warn "Build failed. See $AUDIT_LOG_DIR/patch-build.log"
  fi
fi

TEST_STATUS="skipped"
if [ -n "${AUDIT_TEST_CMD:-}" ]; then
  log "Running test check for patch validation"
  if (cd "$AUDIT_REPO_DIR" && bash -lc "$AUDIT_TEST_CMD" > "$AUDIT_LOG_DIR/patch-test.log" 2>&1); then
    TEST_STATUS="ok"
  else
    TEST_STATUS="failed"
    warn "Tests failed. See $AUDIT_LOG_DIR/patch-test.log"
  fi
fi

AGENT_DIFF="$AUDIT_SUBMISSION_DIR/agent.diff"
CHANGED_FILES="$AUDIT_SUBMISSION_DIR/changed-files.txt"
DIFF_STATUS="skipped"

if [ -d "$AUDIT_REPO_DIR/.git" ]; then
  BASE_REF="${AUDIT_BASE_COMMIT:-}"
  if [ -n "$BASE_REF" ] && git -C "$AUDIT_REPO_DIR" rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    log "Exporting unified diff from baseline $BASE_REF"
    git -C "$AUDIT_REPO_DIR" diff --binary "$BASE_REF" > "$AGENT_DIFF"
    git -C "$AUDIT_REPO_DIR" diff --name-only "$BASE_REF" > "$CHANGED_FILES"
  else
    warn "No valid baseline commit found. Exporting current working-tree diff only."
    git -C "$AUDIT_REPO_DIR" diff --binary > "$AGENT_DIFF"
    git -C "$AUDIT_REPO_DIR" status --porcelain | awk '{print $2}' > "$CHANGED_FILES"
  fi
  DIFF_STATUS="ok"
else
  warn "Not a git repository; cannot export agent.diff"
fi

PATCH_SUMMARY="$AUDIT_SUBMISSION_DIR/patch-summary.md"
cat > "$PATCH_SUMMARY" <<EOF
# Patch Validation Summary

- Repository: \`$AUDIT_REPO_DIR\`
- Baseline commit: \`${AUDIT_BASE_COMMIT:-N/A}\`
- Build status: \`$BUILD_STATUS\`
- Test status: \`$TEST_STATUS\`
- Diff status: \`$DIFF_STATUS\`
- Diff path: \`$AGENT_DIFF\`
- Changed files list: \`$CHANGED_FILES\`

## Notes

- \`agent.diff\` contains all changes against the baseline commit.
- Validate each fix against exploitability, not just test pass/fail.
EOF

if [ "$STRICT" = "1" ]; then
  if [ "$BUILD_STATUS" = "failed" ] || [ "$TEST_STATUS" = "failed" ]; then
    die "Patch validation failed in strict mode."
  fi
fi

log "Patch artifacts written to $AUDIT_SUBMISSION_DIR"
