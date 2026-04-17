#!/usr/bin/env bash
# Claude Code PreToolUse hook: block edits to sensitive files (secrets, lockfiles).
#
# Exits 2 with rationale on stderr to block the tool call. User/Claude can
# override by being explicit in a follow-up. Exits 0 otherwise.
#
# Matches basename and tail segments — portable, no hardcoded paths.

set -u

input=$(cat || true)
[ -z "$input" ] && exit 0

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
    d=json.loads(sys.stdin.read())
    ti=d.get("tool_input",{}) or {}
    print(ti.get("file_path") or ti.get("path") or (ti.get("edits",[{}])[0].get("file_path") if ti.get("edits") else "") or "")
except Exception: pass
' <<<"$input"
    fi
}

file=$(extract_path)
[ -z "$file" ] || [ "$file" = "null" ] && exit 0

base=$(basename -- "$file")
tail2=$(echo "$file" | awk -F/ '{ if (NF>=2) print $(NF-1)"/"$NF; else print $0 }')

block() {
    printf 'Blocked: %s matches secret/lockfile guard (%s).\n' "$file" "$1" >&2
    printf 'If this edit is intentional, tell Claude explicitly what the change is and re-run.\n' >&2
    exit 2
}

# Secrets / keys
case "$base" in
    .env|.env.*|.envrc|credentials.json|credentials.*.json|*.pem|*.key|id_rsa|id_rsa.pub|id_ed25519|id_ed25519.pub|id_dsa|id_ecdsa|*.p12|*.pfx|.netrc|.pgpass|.aws-credentials)
        block "secret file" ;;
esac

# SSH config in home
case "$tail2" in
    .ssh/config|.ssh/authorized_keys|.ssh/known_hosts)
        block "ssh config" ;;
esac

# Lockfiles (Claude rarely needs to edit these directly; package managers do)
case "$base" in
    package-lock.json|yarn.lock|pnpm-lock.yaml|bun.lock|bun.lockb|Cargo.lock|Gemfile.lock|composer.lock|poetry.lock|Pipfile.lock|uv.lock|go.sum)
        block "lockfile (use the package manager instead)" ;;
esac

exit 0
