#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/run_detect.sh --repo-dir <path> [--out <audit.md>]

Options:
  --repo-dir <path>   Target repository path (required)
  --out <path>        Output report path (default: <repo>/submission/audit.md)
  --help              Show this message
EOF
}

REPO_DIR=""
OUT_PATH=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-dir)
      REPO_DIR="${2:-}"
      shift 2
      ;;
    --out)
      OUT_PATH="${2:-}"
      shift 2
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

if [ -z "$OUT_PATH" ]; then
  OUT_PATH="$AUDIT_SUBMISSION_DIR/audit.md"
fi
OUT_DIR="$(dirname "$OUT_PATH")"
mkdir -p "$OUT_DIR"

SOL_FILES="$(count_solidity_files "$AUDIT_REPO_DIR")"
SOL_LINES="$(count_solidity_lines "$AUDIT_REPO_DIR")"
NOW_UTC="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

H_REENTRANCY="$(search_count '\\.call\\{|\\.call\\(' "$AUDIT_REPO_DIR")"
H_DELEGATECALL="$(search_count 'delegatecall' "$AUDIT_REPO_DIR")"
H_TX_ORIGIN="$(search_count 'tx\\.origin' "$AUDIT_REPO_DIR")"
H_SELFDESTRUCT="$(search_count 'selfdestruct|suicide' "$AUDIT_REPO_DIR")"
H_UNCHECKED_TRANSFER="$(search_count '\\.transfer\\(|\\.send\\(' "$AUDIT_REPO_DIR")"
H_ASSEMBLY="$(search_count '\\bassembly\\b' "$AUDIT_REPO_DIR")"
H_UPGRADEABLE="$(search_count 'UUPS|upgradeTo|Upgradeable|proxy' "$AUDIT_REPO_DIR")"

cat > "$OUT_PATH" <<EOF
# Smart Contract Audit Report (Detect)

## Metadata

- Generated: $NOW_UTC
- Repository: \`$AUDIT_REPO_DIR\`
- Framework: \`$AUDIT_FRAMEWORK\`
- Baseline commit: \`${AUDIT_BASE_COMMIT:-N/A}\`
- Solidity files in scope: \`$SOL_FILES\`
- Approx Solidity lines: \`$SOL_LINES\`

## Scope and Constraints

- In-scope directories/files: TODO
- Out-of-scope directories/files: TODO
- Known issues accepted by sponsor: TODO
- Test/build constraints: TODO

## Risk Hotspot Map (heuristic, not confirmed findings)

| Signal | Matches |
|---|---:|
| External call patterns | $H_REENTRANCY |
| delegatecall usage | $H_DELEGATECALL |
| tx.origin usage | $H_TX_ORIGIN |
| selfdestruct/suicide usage | $H_SELFDESTRUCT |
| transfer/send usage | $H_UNCHECKED_TRANSFER |
| assembly blocks | $H_ASSEMBLY |
| upgrade/proxy patterns | $H_UPGRADEABLE |

## High Severity Findings

> Only include vulnerabilities that plausibly lead to loss of user/protocol funds.

### H-01 TODO title
- Severity: High
- Confidence: TODO
- Root cause: TODO
- Impact: TODO
- Exploit path: TODO
- Code references: \`path/to/file.sol:line\`
- Remediation: TODO

### H-02 TODO title
- Severity: High
- Confidence: TODO
- Root cause: TODO
- Impact: TODO
- Exploit path: TODO
- Code references: \`path/to/file.sol:line\`
- Remediation: TODO

## Medium / Needs Confirmation

- TODO

## Coverage Summary

- Components reviewed deeply: TODO
- Components reviewed lightly: TODO
- Not reviewed / uncertain: TODO
EOF

log "Detect scaffold created at $OUT_PATH"
