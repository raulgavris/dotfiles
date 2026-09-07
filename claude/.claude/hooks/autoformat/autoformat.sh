#!/usr/bin/env bash
# Claude Code PostToolUse hook: auto-format edited files.
#
# Triggers on Edit/Write/MultiEdit. Detects project root and tooling from
# config files (biome.json, .eslintrc*, go.mod, pyproject.toml). Non-blocking:
# always exits 0. Failures emit a short warning to stderr.
#
# Dependencies: jq (optional; falls back to python3 if absent), bash 4+.

set -u
exec 2> >(while IFS= read -r l; do printf '[autoformat] %s\n' "$l" >&2; done)

# Read hook input JSON from stdin
input=$(cat || true)
[ -z "$input" ] && exit 0

# Extract file path — tool_input.file_path for Edit/Write, .edits[0].file_path for MultiEdit
extract_path() {
    if command -v jq >/dev/null 2>&1; then
        echo "$input" | jq -r '
          .tool_input.file_path
          // .tool_input.path
          // (.tool_input.edits[0].file_path // empty)
        ' 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
    ti = d.get("tool_input", {}) or {}
    print(ti.get("file_path") or ti.get("path") or (ti.get("edits",[{}])[0].get("file_path") if ti.get("edits") else "") or "")
except Exception:
    pass
' <<<"$input"
    fi
}

file=$(extract_path)
[ -z "$file" ] || [ "$file" = "null" ] && exit 0
[ ! -f "$file" ] && exit 0

# Walk up from $file to find project root (first ancestor with .git or a known manifest)
find_root() {
    local dir
    dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd -P) || return 1
    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        for m in .git biome.json package.json go.mod pyproject.toml Cargo.toml; do
            if [ -e "$dir/$m" ]; then echo "$dir"; return 0; fi
        done
        dir=$(dirname "$dir")
    done
    return 1
}
root=$(find_root) || exit 0

ext="${file##*.}"
warn() { printf '%s\n' "$*" >&2; }

run_timeout() {
    local secs="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$secs" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$secs" "$@"
    else
        "$@"
    fi
}

format_ts_js() {
    if [ -f "$root/biome.json" ] || [ -f "$root/biome.jsonc" ]; then
        if (cd "$root" && run_timeout 5 npx --no-install biome check --write --no-errors-on-unmatched "$file" >/dev/null 2>&1); then
            return 0
        fi
        warn "biome skipped or failed: $file"
        return 0
    fi
    if ls "$root"/.eslintrc* >/dev/null 2>&1 || [ -f "$root/eslint.config.js" ] || [ -f "$root/eslint.config.mjs" ]; then
        (cd "$root" && run_timeout 5 npx --no-install eslint --fix "$file" >/dev/null 2>&1) || warn "eslint skipped: $file"
    fi
    if [ -f "$root/.prettierrc" ] || [ -f "$root/.prettierrc.json" ] || [ -f "$root/.prettierrc.js" ] || [ -f "$root/prettier.config.js" ]; then
        (cd "$root" && run_timeout 5 npx --no-install prettier --write "$file" >/dev/null 2>&1) || warn "prettier skipped: $file"
    fi
}

format_go() {
    command -v gofmt >/dev/null 2>&1 && run_timeout 5 gofmt -w "$file" 2>/dev/null
    command -v goimports >/dev/null 2>&1 && run_timeout 5 goimports -w "$file" 2>/dev/null
}

format_py() {
    if [ -f "$root/ruff.toml" ] || grep -q 'tool.ruff' "$root/pyproject.toml" 2>/dev/null; then
        (cd "$root" && run_timeout 5 ruff format "$file" >/dev/null 2>&1) || warn "ruff format skipped: $file"
        (cd "$root" && run_timeout 5 ruff check --fix "$file" >/dev/null 2>&1) || true
        return 0
    fi
    if command -v black >/dev/null 2>&1; then
        (cd "$root" && run_timeout 5 black -q "$file") || warn "black skipped: $file"
    fi
}

format_rust() {
    command -v rustfmt >/dev/null 2>&1 && run_timeout 5 rustfmt --edition 2021 "$file" 2>/dev/null
}

case "$ext" in
    ts|tsx|js|jsx|mjs|cjs) format_ts_js ;;
    go)                    format_go ;;
    py)                    format_py ;;
    rs)                    format_rust ;;
    *)                     : ;;
esac

exit 0
