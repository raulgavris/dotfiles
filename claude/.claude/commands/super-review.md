---
description: Heavyweight PR review — parallel subagents, dev-server E2E probe, optional fix-loop for your own PRs.
argument-hint: <pr-number | branch-name> [--fix-loop] [--no-dev-server] [--max-iterations 3]
---

# Super Review

Review a PR with the full treatment: parallel specialist subagents, empirical E2E verification via the dev server, and — if the PR is yours — an iterative fix-loop until either the review is clean or the iteration budget is spent.

Arguments: `$ARGUMENTS`

## Phase 1 — Collect the facts

1. Parse `$ARGUMENTS` to determine target. Accepts:
   - PR number (e.g. `1234`) → `gh pr view 1234 --json …`
   - Branch name (e.g. `feat/something`) → resolve to PR via `gh pr list --head <branch>`, or review the branch directly if no PR exists yet.
   - Flags: `--fix-loop` (force fix-loop even if PR isn't yours), `--no-fix-loop`, `--no-dev-server`, `--max-iterations N`.
2. In the current repo, fetch:
   ```bash
   git fetch origin
   ```
3. Gather PR metadata (base branch, author, title, body, CI status) via `gh pr view --json`.
4. Read these before reviewing:
   - `CLAUDE.md` at repo root
   - `AGENTS.md` if present
   - `.github/pull_request_template.md`
   - Repo-local `.claude/commands/review-pr.md` or `.claude/commands/review-branch.md` if they exist — **honor the project's scoreboard and severity guide if one is defined**. Otherwise use the generic scoreboard below.
5. Compute the diff:
   ```bash
   base=$(gh pr view <N> --json baseRefName -q .baseRefName)
   git diff origin/$base...origin/<head-ref>
   ```

## Phase 2 — Dispatch parallel reviewers

In **one** assistant turn, spawn **all applicable** agents with `Agent` tool calls:

| Agent | When to include |
|---|---|
| `backend-reviewer` | Always |
| `ai-slop-hunter` | Always. Grumpy, by-the-book reviewer dedicated to finding AI-generated slop, fake robustness, design laziness. |
| `pr-review-toolkit:silent-failure-hunter` | If diff adds/modifies `try/catch`, error returns, `.catch(...)`, or fallback logic |
| `pr-review-toolkit:type-design-analyzer` | If new or modified types (TS `interface`/`type`, Go `struct`, dataclasses) |
| `pr-review-toolkit:pr-test-analyzer` | Always when code is non-trivial |
| `pr-review-toolkit:comment-analyzer` | If diff touches comments or docstrings |
| `feature-dev:code-reviewer` | Always (independent second opinion) |

Each agent gets a prompt containing: the base ref, head ref, the full diff (or a ref to it), and instruction to cite `CLAUDE.md` conventions.

**If `superpowers:dispatching-parallel-agents` skill is available, invoke it** for the dispatch — it handles prompt framing and result aggregation.

## Phase 3 — Empirical E2E probe

Unless `--no-dev-server` was passed:

1. Invoke the `dev-server-tester` subagent. Prompt it with:
   - Target directory: the repo root.
   - Feature path to probe: derived from the diff's changed files (e.g. if `src/services/order/actions/quote.ts` changed, probe the quote endpoint; if `app/profile/page.tsx` changed in a Next.js app, probe `/profile`).
   - Specific inputs to use if the PR description or commits mention test cases.
2. Wait for its report. Incorporate findings into the final review.

If a Playwright MCP tool is available and the project has `playwright.config.*`, ask the dev-server-tester to use Playwright for UI flows; otherwise it will use `curl`.

## Phase 4 — Aggregate & score

Combine every agent's output into one review. Use the project's scoreboard if `CLAUDE.md` or a project command defines one. Otherwise:

```markdown
## Super-Review: `<pr-or-branch>`

### Summary
<what the PR does, in 2-3 lines>

### Scoreboard
| Category | Score | Notes |
|---|---|---|
| Code Quality | X/10 | |
| Human Feel (AI-slop check) | X/10 | From ai-slop-hunter; 10 = looks like a careful senior wrote it |
| Type Safety | X/10 | |
| Security | X/10 | |
| Robustness | X/10 | |
| Test Coverage | X/10 | |
| Performance | X/10 | |
| Architecture Fit | X/10 | |
| E2E Verification | X/10 | From dev-server probe |
| Review Confidence | X/10 | |

**Overall: X/10** — one-line verdict.

### High-severity findings
…

### Medium
…

### Low
…

### E2E probe result
<brief — link to details>

### Positive
…
```

## Phase 5 — Fix-loop (conditional)

Enter the fix-loop if:
- `--fix-loop` was passed, **OR**
- The PR author matches the current git user (`git config user.email` or `gh api user --jq .login`), **AND** `--no-fix-loop` was NOT passed.

Loop (bounded by `--max-iterations`, default 3):

1. For each **High**-severity finding with a concrete suggested fix, apply it with `Edit` or `Write`. Skip findings marked "requires design discussion".
2. Run the project's narrowest verification for the changed files:
   - Tests: `npm test -- -t <name>` / `vitest run <file>` / `go test ./... -run <name>` / `pytest -k <name>`.
   - Type-check: `npm run typecheck` / `npx tsc --noEmit` / `go vet ./...` / `mypy <file>`.
   - Lint: `npm run lint` / `biome check` / `ruff check`.
3. Re-invoke `dev-server-tester` if any fix touched a code path the probe exercised.
4. Re-score the previously failing categories. If clean, break.
5. Commit the fixes as a **new commit** on the PR branch, with a message like `fix: address super-review findings (auto)`. **Do not amend or force-push** without the user's explicit OK.

## Phase 6 — Hand-off

Output the final review. Ask the user:
- "Post this as a PR comment?" (only `gh pr comment` after they say yes)
- If fix-loop exited with iterations remaining and findings open: list what's left.
- If fix-loop committed changes: summarize the commits and ask before pushing.

## Rules

- Parallel dispatch is mandatory — one turn, many `Agent` calls. Do not serialize.
- Honor the project's `review-pr` or `review-branch` command format if one exists.
- Never force-push, never amend commits pushed upstream.
- Never post to PR without explicit user approval.
- If the dev server can't start (missing secrets, broken build), continue with static-only review and note "E2E: skipped" in the scoreboard.
- Integration tests that hit real external services are expected — don't flag them.
- Don't invent MCP tools. If `log-analyst` is needed and no observability MCP is configured, either skip it or ask the user.
