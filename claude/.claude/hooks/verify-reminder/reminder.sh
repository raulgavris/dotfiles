#!/usr/bin/env bash
# Claude Code Stop hook: remind about verification when the session edited code
# but never ran tests / typecheck / lint.
#
# Non-blocking: always exits 0. Emits a one-line <system-reminder> style
# message to stderr, which Claude will see on the next turn if the session
# continues, or which the user will see in the transcript.
#
# The hook reads the session transcript (JSONL) from stdin input shape:
#   { "transcript_path": "/path/to/session.jsonl", ... }

set -u

input=$(cat || true)

path=""
if command -v jq >/dev/null 2>&1; then
    path=$(echo "$input" | jq -r '.transcript_path // .session.transcript_path // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
    path=$(python3 -c '
import json,sys
try:
    d=json.loads(sys.stdin.read())
    print(d.get("transcript_path") or (d.get("session") or {}).get("transcript_path") or "")
except Exception: pass
' <<<"$input")
fi

[ -z "$path" ] || [ ! -f "$path" ] && exit 0

# Heuristic: did the session contain Edit/Write/MultiEdit AND NOT any test/type/lint bash?
edits=$(grep -c '"name":"\(Edit\|Write\|MultiEdit\)"' "$path" 2>/dev/null || echo 0)
[ "$edits" -eq 0 ] && exit 0

verified=$(grep -cE '"name":"Bash".*(npm (test|run (test|typecheck|lint|build))|vitest|jest|pytest|go test|cargo test|biome check|tsc|mypy|ruff)' "$path" 2>/dev/null || echo 0)

if [ "$verified" -eq 0 ]; then
    printf '%s\n' "<system-reminder>Session edited $edits file(s) but did not run tests/typecheck/lint. Consider verifying with the project's test or type-check command before concluding.</system-reminder>" >&2
fi

exit 0
