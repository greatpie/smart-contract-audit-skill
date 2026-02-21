#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/audit.sh [options]

Options:
  --repo <url-or-path>    Repo URL or local path (required unless --repo-dir is provided)
  --repo-dir <path>       Already-bootstrapped local repo path
  --branch <name>         Branch for bootstrap
  --workspace <dir>       Workspace for URL cloning (default: .audit-workspace)
  --modes <csv>           detect,patch,exploit (default: detect,patch)
  --tx-script <path>      Optional tx script for exploit mode
  --skip-install          Pass-through to bootstrap
  --skip-verify           Pass-through to bootstrap
  --help                  Show this message
EOF
}

REPO_INPUT=""
REPO_DIR=""
BRANCH=""
WORKSPACE="$PWD/.audit-workspace"
MODES="detect,patch"
TX_SCRIPT=""
SKIP_INSTALL="0"
SKIP_VERIFY="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      REPO_INPUT="${2:-}"
      shift 2
      ;;
    --repo-dir)
      REPO_DIR="${2:-}"
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
    --modes)
      MODES="${2:-}"
      shift 2
      ;;
    --tx-script)
      TX_SCRIPT="${2:-}"
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
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

if [ -z "$REPO_DIR" ] && [ -z "$REPO_INPUT" ]; then
  usage
  die "Provide either --repo-dir or --repo"
fi

if [ -z "$REPO_DIR" ]; then
  BOOTSTRAP_ARGS=(--repo "$REPO_INPUT" --workspace "$WORKSPACE")
  if [ -n "$BRANCH" ]; then
    BOOTSTRAP_ARGS+=(--branch "$BRANCH")
  fi
  if [ "$SKIP_INSTALL" = "1" ]; then
    BOOTSTRAP_ARGS+=(--skip-install)
  fi
  if [ "$SKIP_VERIFY" = "1" ]; then
    BOOTSTRAP_ARGS+=(--skip-verify)
  fi

  BOOTSTRAP_OUTPUT="$("$SCRIPT_DIR/bootstrap.sh" "${BOOTSTRAP_ARGS[@]}")"
  printf '%s\n' "$BOOTSTRAP_OUTPUT"

  REPO_DIR="$(printf '%s\n' "$BOOTSTRAP_OUTPUT" | awk -F= '/^REPO_DIR=/{print $2}' | tail -n 1)"
  [ -n "$REPO_DIR" ] || die "Failed to parse repo path from bootstrap output."
fi

REPO_DIR="$(abs_path "$REPO_DIR")"
IFS=',' read -r -a MODE_LIST <<< "$MODES"

for mode in "${MODE_LIST[@]}"; do
  case "$mode" in
    detect)
      "$SCRIPT_DIR/run_detect.sh" --repo-dir "$REPO_DIR"
      ;;
    patch)
      "$SCRIPT_DIR/run_patch.sh" --repo-dir "$REPO_DIR"
      ;;
    exploit)
      if [ -n "$TX_SCRIPT" ]; then
        "$SCRIPT_DIR/run_exploit.sh" --repo-dir "$REPO_DIR" --tx-script "$TX_SCRIPT"
      else
        "$SCRIPT_DIR/run_exploit.sh" --repo-dir "$REPO_DIR"
      fi
      ;;
    *)
      die "Unsupported mode: $mode"
      ;;
  esac
done

log "Audit pipeline finished for $REPO_DIR"
