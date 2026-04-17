---
description: Audit a Claude Code setup and recommend targeted workflow improvements. Shareable — works on any machine.
argument-hint: [projects-root (default $HOME)] [--apply]
---

# Streamline Claude

Audit the current Claude Code setup (`~/.claude/` + your projects tree) and produce a prioritized plan of targeted improvements: hooks, slash commands, subagents, memory seeding, plugin pruning, permission cleanup.

Runs anywhere. No hardcoded paths. Honors whatever projects layout the user has (`$HOME/Sites`, `$HOME/projects`, `$HOME/work`, a custom arg).

Args: `$ARGUMENTS`

## Procedure

1. **Parse args.**
   - First positional: projects root (default `$HOME`). Expand `~` and `$HOME`.
   - Flags: `--apply` (actually write recommended files; otherwise plan-only), `--focus <area>` (limit to one of: hooks, review, bug, test, memory, plugins, permissions, claude-md).

2. **Invoke `claude-code-setup:claude-automation-recommender` skill** if available — its reference tables guide recommendations.

3. **Discover the setup.**
   - Read `~/.claude/settings.json` — hooks, plugins, permissions, MCP servers, statusline.
   - Read `~/.claude/projects/*/memory/MEMORY.md` if present — summarize what's stored (don't dump full contents).
   - List `~/.claude/commands/`, `~/.claude/agents/`, `~/.claude/hooks/`, `~/.claude/skills/` contents.
   - List enabled plugins.

4. **Survey the projects.**
   - In parallel, launch 1-3 Explore subagents over the projects root.
   - For each sub-project, gather: stack (package.json / go.mod / pyproject.toml), `CLAUDE.md` presence, `.claude/` contents, test framework, CI config, key SDK usage.
   - Cap depth at 3 to keep it fast.

5. **Identify gaps.**
   - **Hooks**: any productive `PostToolUse` for format/lint? Any `PreToolUse` guard for secrets? Any `Stop` verify-reminder?
   - **Review**: does `~/.claude/commands/` have review commands? Are project-level review commands propagated across repos?
   - **Memory**: is memory empty or stale?
   - **Plugins**: what's enabled but unused? What's missing for the detected stacks?
   - **Permissions**: any malformed entries (bash comments, one-off paths, newline artifacts)?
   - **CLAUDE.md coverage**: which projects are missing a CLAUDE.md?

6. **Produce the plan.**
   - Organize findings into tiers by impact and risk.
   - Each recommendation has: what to do, where to write it, why it matters for *this* setup, and a rough effort estimate.
   - Cite concrete evidence from the audit (e.g., "40+ manual `biome check` invocations in your allow-list").

7. **Ask priorities.**
   - Use `AskUserQuestion` with 2-4 targeted questions: which workflow to prioritize, how aggressive to prune plugins, how broad the memory seed should be, permission cleanup appetite.

8. **Write the plan.**
   - Path: `~/.claude/plans/streamline-<YYYYMMDD-HHMMSS>.md`.
   - Include: context, tiers, per-tier files to create/modify, existing assets to reuse, verification steps, execution order.

9. **If `--apply`** (and only if):
   - Create the hook scripts, agent files, command files as dictated by the plan.
   - Seed memory files (ask before writing individual memories if they contain project-specific details).
   - Prune plugins and permissions in `settings.json`. **Always backup first** to `settings.json.backup-streamline-<timestamp>`.
   - Do NOT delete user data. If there's any ambiguity, stop and ask.

10. **Output** a short summary + path to the plan file. Call `ExitPlanMode` if in plan mode.

## Rules

- **Portable.** No hardcoded usernames, hostnames, IPs. Use `$HOME`, `git rev-parse --show-toplevel`, config-file detection.
- **Safe.** Read-only by default. `--apply` still asks for confirmation on destructive changes (plugin disables, permission removals).
- **Evidence-driven.** Every recommendation must cite something concrete from the audit — not "best practice says…".
- **Respect existing work.** If the user already has a working hook / command / agent, don't propose to replace it. Propose additive improvements only.
- **Keep it tight.** Top 1-2 recommendations per category by default. More only if the user asks.

## Sharing with colleagues

A colleague can run this command after cloning a dotfiles repo that contains this command. It won't touch their setup unless they pass `--apply`. The command works regardless of their projects layout — it'll adapt.
