---
description: Investigate a bug from a symptom, error, or ticket — systematically, with evidence.
argument-hint: <symptom | error-id | ticket-id | order-id | timestamp>
---

# Investigate Bug

Starts from a symptom, works toward a root cause with evidence, produces a minimal reproduction and a suggested fix.

Target: `$ARGUMENTS`

## Procedure

1. **Invoke the `superpowers:systematic-debugging` skill** if available — it defines the discipline. Follow it.

2. **Load project context.**
   - Read `CLAUDE.md` / `AGENTS.md` at the repo root.
   - Identify the service(s) likely involved from the symptom.

3. **Pull evidence — delegate to `log-analyst` subagent.**
   - Prompt it with: the symptom, any IDs (ticket, order, request), and the inferred time window.
   - It will return timeline + hypothesis using whatever observability tooling is wired up.
   - If there is no observability tooling (no Sentry/Loki/metrics MCP), fall back to grepping container logs, PM2 logs, and recent git history.

4. **Form a focused hypothesis.**
   - From the log-analyst's output, identify the single most-likely cause.
   - Write it down: "Because X happens at Y, we observe Z."
   - Rate confidence: low / medium / high.

5. **Seek a minimal repro.**
   - If the bug is in a function: write a failing test that demonstrates it, without committing. Run the test. Confirm it fails for the expected reason.
   - If the bug is in a service: craft the minimal curl/GraphQL call that triggers it.
   - If you can't reproduce locally (e.g., requires prod data), say so and suggest a proxy repro.

6. **Suggest a fix.**
   - Point to the exact file:line.
   - Describe the fix in 2-4 lines of code (not a full rewrite).
   - List adjacent tests to update.
   - Note any migration / backward-compat concerns.

7. **Output.**

```markdown
## Bug investigation: <short label>

**Symptom:** <user-visible or system-visible>
**Window:** <start> – <end>

### Evidence
<log-analyst summary, abbreviated>

### Hypothesis
<cause → effect → symptom, confidence>

### Repro
```<lang>
<minimal code or curl command>
```
Expected: <what should happen>
Observed: <what happens>

### Suggested fix
- File: `path/to/file.ext:LINE`
- Change: <2-4 lines>
- Adjacent tests to update: …
- Migration / compat: <if any>

### Open questions
<anything that would increase confidence if answered>
```

## Rules

- **Evidence before opinion.** Every claim needs a log line, metric, or code reference.
- **Don't fix in this flow.** Produce the plan; the user decides whether to apply. If they want, they can run `/super-review` on a branch where the fix is applied.
- If the symptom is ambiguous (multiple services could explain it), list alternatives with differentiating questions before going deep.
- Redact any secrets that appear in logs.
- Never modify production data. Queries only.
