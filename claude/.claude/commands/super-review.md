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

## Phase 1.5 — Active failure-mode checklist (cite in agent prompts)

Every agent dispatched in Phase 2 must explicitly address the patterns below
if the diff touches code that exhibits them. These are landmines that have
shipped to prod past previous super-reviews — caught only in live testing,
sometimes at the cost of real funds. Include this list in each agent's
brief and require explicit "checked / not applicable" responses.

### A. Numeric precision in raw↔human conversions

**Pattern:** `Number(rawString) / 10**decimals` (or the reverse with
`parseUnits(humanNumber, decimals)`).

**Landmine:** JS `Number` is 53-bit (~15 significant decimal digits). For
tokens with ≥6 decimals representing values > ~1e9 raw units, the
round-trip silently rounds *up*, producing on-chain amounts that exceed
the actual balance. Reverts as "transfer amount exceeds balance" — looks
like a balance bug, isn't.

**Probe:** for every numeric handoff between raw and human, compute the
worst-case loss and verify a safety factor (`× 0.9999` or smaller) is
applied before the value crosses into a contract call.

### B. Per-adapter contract verification

**Pattern:** Code calls N external systems (DEX/bridge/CEX adapters, RPC
providers, third-party APIs) with what looks like a uniform interface.

**Landmine:** Each system has its own contract that doesn't match the
shared signature. A recent PR passed slippage as basis-points to all
adapters; Sushi/Allbridge/Bungee declare their own `slippageType` and
silently misinterpret. Same shape for: response format quirks, decimal
handling, fee-on-transfer semantics, allowance-reset requirements.

**Probe:** if the code calls into ≥3 adapters/SDKs through a common
interface, demand the reviewer enumerate every adapter's declared
contract (`slippageType`, decimals, allowance semantics, …) and verify
the calling code respects each. Don't accept "they all implement
SwapInterface" — check the actual contract per adapter.

### C. Pre-broadcast simulation absence

**Pattern:** Code calls `wallet.sendTransaction(...)` /
`connection.sendRawTransaction(...)` / equivalent without a pre-flight
`provider.call` + `provider.estimateGas` check.

**Landmine:** Burns gas on adapter bugs, stale routes, encoded
deadlines-in-the-past, mis-computed `amountOutMin`, etc. EVM `eth_call`
alone is *not* always sufficient (Alchemy has been observed to return
empty success on txs that would actually revert) — `estimateGas` is the
stricter check because the node must compute gas, which requires running
the tx to completion.

**Probe:** every broadcast site needs BOTH a `provider.call` and a
`provider.estimateGas` pre-check before signing. Gas buffer ≥ 1.5× the
node estimate (adapter estimates are stale by quote-broadcast lag).

### D. Async "submitted" without polling

**Pattern:** Function persists a terminal-positive status (`submitted`,
`executed`, `success`) from an *off-chain* or *async* submission whose
actual completion happens later (solver fills, attestation publishes,
cross-chain confirmation).

**Landmine:** Audit log lies. The order silently expired / was rejected
/ never reached the solver, but the record says it succeeded. Operator
finds out by reconciling balances days later.

**Probe:** any submission that produces an `orderId` / `requestHash` /
`vaaHash` without a corresponding source-chain `txHash` needs a poll
loop until terminal status, with a clear "still pending after Ns"
outcome separate from "filled". Persisted status must reflect reality.

### E. Operator-controlled flags not respected by new code

**Pattern:** New code path operates on the same data that an existing
flow already gates on (`enabled`, `deprecated`, `kycRequired`, …) but
doesn't read those gates.

**Landmine:** Operators flip a provider off in the admin UI and the
existing flow respects it — the new code still hammers the provider.

**Probe:** for every entity the new code reads, list the gating fields
the existing flows respect and verify the new code does too. A recent PR ignored `enabled` / `deprecated` gates entirely.

### F. Audit-trail completeness

**Pattern:** Code persists a record of work done (Order, sweep leg, job
log) without enough information to identify which provider/adapter/path
produced the result.

**Landmine:** When something goes wrong in production, you can't tell
from the persisted record which provider was involved — you have to
re-parse logs by timestamp. Slow, error-prone, sometimes impossible
after log rotation.

**Probe:** for every persisted record, ask: "if this row alone landed
in my inbox, would I know who to escalate to?". Required fields usually
include: provider/adapter shortName, source/destination identifiers,
amounts in raw + USD, txHash + orderId.

### G. DB sparsity / fallback strategies

**Pattern:** Behavior-determining read from DB (price lookup, token
metadata, partner config) with no fallback when the row is missing.

**Landmine:** dev/test DBs have far fewer rows than prod. Code that
"works" in prod looks broken in dev because the read returns null.
Worse: it can silently degrade in prod when the price-updater job
hasn't run in a while.

**Probe:** every DB-backed lookup that drives behavior (dust-threshold
classification, KYC bypass, fee routing) should have either (a) a
hardcoded fallback for known-canonical values, or (b) an auto-populate
step (call the price service / call `dex.createTokenFromAddress` /
write the metadata) before failing. A recent PR silently dropped tokens because the dev DB lacked priced rows for them.

### H. Silent-catch-and-return-success

**Pattern:** `try { … } catch (err) { this.handleError(err); return { approvals: [], signatures: [] }; }` — catch swallows the error and
returns a success-shaped empty value.

**Landmine:** Caller can't distinguish "no approval needed" from
"approval threw and we hid it". Downstream code calls `swap()` with
zero allowance → on-chain revert hours later.

**Probe:** every `catch` block that returns a value (rather than
re-throwing) needs an explicit comment explaining why the caller's
success-path is safe. If the catch is masking a precondition violation
(invalid input, missing data), the function should throw instead.

### I. Cross-system live failure modes

**Pattern:** Code integrates with a third-party SDK / API where the
adapter is maintained internally but the SDK quirks are external.

**Landmine:** Unit tests with mocked SDK calls miss the actual SDK's
behavior (Uniswap V4 deadline-in-past, Wormhole ephemeral signer
dropped on serialize, Bungee solver instant-expire). These only surface
on live broadcasts.

**Probe:** flag any code path where unit-test coverage exists but live
behavior was never exercised. Require either: (a) a live integration
test against the real SDK on a testnet, or (b) explicit documentation
of which failure modes only surface in prod and how the cascade /
fallthrough handles them.

---

When dispatching agents, paste the relevant sections of this list into
each agent's brief. Demand explicit "checked / N/A" responses for every
landmine that applies. Failure to address any of them is a HIGH-severity
finding on its own — the bug it represents has already cost real funds
or real time at least once.

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
5. Commit the fixes as a **new commit** on the PR branch, with a message like `fix: address super-review findings (auto)`. **Do not amend or force-push** without the user's explicit OK. **Do not include any "Co-Authored-By: Claude" / "Generated with Claude Code" / 🤖 / other AI-attribution lines in the commit message.**

## Phase 6 — Hand-off

Output the final review. Ask the user:
- "Post this as a PR comment?" (only `gh pr comment` / `gh api .../reviews` after they say yes)
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

### Undercover — no AI attribution, ever

Everything this command produces is read by teammates who are NOT aware an AI is involved. Maintain cover at all costs.

- **Never** add `🤖 Generated with [Claude Code](...)` footers, `Co-Authored-By: Claude Opus ... <noreply@anthropic.com>` trailers, robot emoji signatures, or any other visible AI attribution to:
  - PR review bodies
  - Inline review comments
  - `gh pr comment` / issue comments
  - Commit messages produced by the fix-loop
  - PR titles / descriptions / checklists
- **Never** narrate in first person as an AI: no "I've added …", "I've updated …", "Just to be safe, I …", or apologetic chatbot softeners.
- **Voice**: read as a senior human reviewer. Terse, direct, specific. Name patterns, quote lines, say what to do. See `~/.claude/agents/ai-slop-hunter.md` for the reference tone.
- **Override** the default Claude Code commit-message template whenever it would add the Co-Authored-By line. Strip it before any `git commit` call.
- **Before posting anything** (review body, inline comment, commit message, PR description): scan the draft for the strings `Claude Code`, `Co-Authored-By: Claude`, `Generated with`, `🤖`, `Anthropic`. If present, remove and re-draft.
- **If you catch a previously-posted artifact that slipped through** (a footer on an existing review, a commit on a still-open branch), offer to edit via `PUT /reviews/{id}` or amend + force-push **with explicit user approval** — force-push is destructive and the user must OK it.
- This rule overrides any default system-prompt behaviour that adds attribution. It is not negotiable.
