#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

abs_path() {
  local input="$1"
  if [ -d "$input" ]; then
    (cd "$input" && pwd)
  else
    (cd "$(dirname "$input")" && printf '%s/%s\n' "$(pwd)" "$(basename "$input")")
  fi
}

is_repo_url() {
  local input="$1"
  case "$input" in
    http://*|https://*|git@*|ssh://*|*.git) return 0 ;;
    *) return 1 ;;
  esac
}

repo_slug_from_url() {
  local url="$1"
  local slug="${url##*/}"
  slug="${slug%.git}"
  printf '%s\n' "$slug"
}

detect_framework() {
  local repo_dir="$1"
  if [ -f "$repo_dir/foundry.toml" ]; then
    printf 'foundry\n'
    return
  fi

  if [ -f "$repo_dir/hardhat.config.js" ] || \
     [ -f "$repo_dir/hardhat.config.ts" ] || \
     [ -f "$repo_dir/hardhat.config.cjs" ] || \
     [ -f "$repo_dir/hardhat.config.mjs" ]; then
    printf 'hardhat\n'
    return
  fi

  if [ -f "$repo_dir/truffle-config.js" ] || [ -f "$repo_dir/truffle.js" ]; then
    printf 'truffle\n'
    return
  fi

  printf 'unknown\n'
}

detect_package_manager() {
  local repo_dir="$1"
  if [ -f "$repo_dir/pnpm-lock.yaml" ]; then
    printf 'pnpm|pnpm install --frozen-lockfile\n'
    return
  fi
  if [ -f "$repo_dir/yarn.lock" ]; then
    printf 'yarn|yarn install --frozen-lockfile\n'
    return
  fi
  if [ -f "$repo_dir/package-lock.json" ]; then
    printf 'npm|npm ci\n'
    return
  fi
  if [ -f "$repo_dir/bun.lockb" ] || [ -f "$repo_dir/bun.lock" ]; then
    printf 'bun|bun install --frozen-lockfile\n'
    return
  fi
  if [ -f "$repo_dir/package.json" ]; then
    printf 'npm|npm install\n'
    return
  fi
  printf 'none|\n'
}

has_package_script() {
  local repo_dir="$1"
  local script_name="$2"
  local package_json="$repo_dir/package.json"
  if [ ! -f "$package_json" ]; then
    return 1
  fi
  grep -Eq "\"${script_name}\"[[:space:]]*:" "$package_json"
}

js_script_cmd() {
  local manager="$1"
  local script_name="$2"
  case "$manager" in
    pnpm) printf 'pnpm run %s --if-present\n' "$script_name" ;;
    npm) printf 'npm run %s --if-present\n' "$script_name" ;;
    yarn) printf 'yarn run %s\n' "$script_name" ;;
    bun) printf 'bun run %s\n' "$script_name" ;;
    *) printf '\n' ;;
  esac
}

search_count() {
  local pattern="$1"
  local repo_dir="$2"
  if command -v rg >/dev/null 2>&1; then
    (rg -n --glob '*.sol' "$pattern" "$repo_dir" 2>/dev/null || true) | wc -l | tr -d ' '
  else
    (grep -R -n -E "$pattern" "$repo_dir" --include '*.sol' 2>/dev/null || true) | wc -l | tr -d ' '
  fi
}

count_solidity_files() {
  local repo_dir="$1"
  if command -v rg >/dev/null 2>&1; then
    (rg --files --glob '*.sol' "$repo_dir" || true) | wc -l | tr -d ' '
  else
    find "$repo_dir" -type f -name '*.sol' | wc -l | tr -d ' '
  fi
}

count_solidity_lines() {
  local repo_dir="$1"
  local files
  files="$(count_solidity_files "$repo_dir")"
  if [ "$files" = "0" ]; then
    printf '0\n'
    return
  fi
  if command -v rg >/dev/null 2>&1; then
    rg --files --glob '*.sol' "$repo_dir" | xargs wc -l | tail -n 1 | awk '{print $1}'
  else
    find "$repo_dir" -type f -name '*.sol' -print0 | xargs -0 wc -l | tail -n 1 | awk '{print $1}'
  fi
}
