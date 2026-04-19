# claude — Stow package for Claude Code

Portable global Claude Code configuration: slash commands, subagents, and productive hooks. Designed to be shareable across machines and team members.

**No hardcoded paths, usernames, hostnames, or internal tooling.** Everything adapts to the project you run it in (reads `CLAUDE.md`, detects stack from config files).

## What's in this package

```
.claude/
├── commands/
│   ├── super-review.md        # Multi-agent PR review + dev-server E2E + fix-loop
│   ├── investigate-bug.md     # Systematic bug investigation with evidence
│   ├── gen-test.md            # Generate tests matching project conventions
│   └── streamline-claude.md   # Audit & improve any Claude Code setup (shareable)
├── agents/
│   ├── backend-reviewer.md    # Generalist backend code reviewer (reads CLAUDE.md)
│   ├── dev-server-tester.md   # Starts dev server, probes endpoints, collects logs
│   ├── log-analyst.md         # Correlates symptoms with logs/errors/metrics
│   └── biome-fixer.md         # Narrow lint/format worker
├── hooks/
│   ├── autoformat/autoformat.sh  # PostToolUse: auto-format edited files (biome/eslint/gofmt/ruff)
│   ├── verify-reminder/reminder.sh # Stop: remind to run tests if none ran
│   └── secret-guard/guard.sh  # PreToolUse: block edits to .env, lockfiles, keys
├── skills/
└── settings.template.json     # Hook registrations, merged into your ~/.claude/settings.json by install.sh

state/plugins/                 # NOT stowed — seeded into ~/.claude/plugins/ by install.sh
├── installed_plugins.json     # List of installed Claude Code plugins (with __HOME__ tokens)
└── known_marketplaces.json    # Configured plugin marketplaces
```

**peon-ping** (sound effects + desktop notifications) is installed separately by `install.sh` via its upstream installer (`brew` on macOS, `curl | bash` on Linux). Its hook files and sound packs live outside this stow package — run `peon-ping-setup` to (re)install them.

## Installation

If you use this dotfiles repo's `install.sh`, the `claude` package is stowed automatically along with the rest.

Manual install:

```bash
cd ~/Sites/dotfiles           # or wherever you cloned this repo
stow claude -t "$HOME" --no-folding
```

Then merge the hook registrations into your existing `~/.claude/settings.json`:

```bash
tmp=$(mktemp)
jq -s '.[0] * .[1]' ~/.claude/settings.json ~/.claude/settings.template.json > "$tmp"
mv "$tmp" ~/.claude/settings.json
chmod +x ~/.claude/hooks/*/*.sh
```

`install.sh` does this automatically.

`--no-folding` is important — without it, Stow would symlink the whole `.claude/` directory, which would clobber `~/.claude/sessions/`, `~/.claude/todos/`, and other runtime state Claude Code writes.

## MCP servers registered automatically

`install.sh` will register these user-scoped MCP servers if they're not already present (via `claude mcp add`):

- **chrome-devtools** — drives a local Chrome instance for front-end debugging (console, network, DOM inspection, screenshots). Handy for `/super-review` when verifying UI changes. Run `claude mcp remove chrome-devtools` to disable.

No project-specific MCPs are auto-registered. If you rely on an internal observability/Jira MCP, register it yourself.

## Hook behavior

All three hooks are **non-blocking** by design (except `secret-guard`, which *should* block):

- **autoformat.sh** (PostToolUse): runs biome/eslint/prettier/gofmt/goimports/ruff/black/rustfmt on the file Claude just edited, based on project config. Timeouts at 5s. Any failure is a warning, not an error.
- **verify-reminder.sh** (Stop): if the session edited files but never ran tests, lint, or typecheck, emit a one-line reminder. Nothing more.
- **secret-guard.sh** (PreToolUse): blocks `Edit`/`Write` on `.env`, `credentials.json`, `*.pem`, SSH keys, and lockfiles (`package-lock.json`, `yarn.lock`, etc.). Claude can justify and retry with explicit intent, or the user can temporarily disable the hook.

## Commands — how they adapt

Every command in this package reads the current repo's `CLAUDE.md` / `AGENTS.md` to learn project conventions before acting. None of them assume a specific framework, directory layout, or host.

Examples:
- `/super-review` detects the stack (package.json scripts, docker-compose files) to pick the right dev server command.
- `/gen-test` finds a neighbor test file in the project and matches its style.
- `/investigate-bug` discovers available observability tooling (MCP tools, log files, `docker compose logs`) at runtime.

## Adding project-specific context

The commands here are intentionally generic. For project-specific rules (e.g., "always use arrow functions", "don't mock the database", "feature branches merge into develop"), write them into the project's own `CLAUDE.md`. The commands will honor them.

If a project needs its own review command with hard-coded team conventions, create a project-level `.claude/commands/review.md` — Claude Code loads project-level commands in addition to global ones.

## Sharing with colleagues

A colleague cloning this dotfiles repo and running `install.sh` will get the same commands and hooks. None of them reference specific projects, usernames, or internal infrastructure, so they work out of the box.

If a colleague wants to audit and tailor their own Claude Code setup, they can run `/streamline-claude` after install.

## What's explicitly NOT in this package

On purpose, to keep it clean:

- **`settings.json`** — your accumulated permissions and plugin list are personal to your workflow. Only the hook registrations template is here.
- **`memory/`** — your personal memory store.
- **Personal skills** — e.g., project-specific knowledge lives in `~/.claude/skills/` outside Stow, or in the project's own `.claude/` directory.
- **`hooks/peon-ping`** and other personal notification setups — not everyone wants audio cues on every tool call.

## Troubleshooting

**Hook didn't run**: check `chmod +x ~/.claude/hooks/*/*.sh` and that `~/.claude/settings.json` has the hook registered with an absolute path (it should say `$HOME/.claude/hooks/...`).

**autoformat didn't format**: it silently skips if the project has no config (`biome.json`, `.eslintrc*`, etc.). That's by design — it doesn't impose tooling.

**secret-guard blocked a legitimate edit**: tell Claude explicitly what you're doing (e.g., "update the VITE_PUBLIC_* vars in .env") — Claude can re-attempt with context, and if the file really should be editable, you can temporarily comment the hook.

**Commands not showing up**: `claude --help` should list them under "Available commands" or `/help` should show them. If not, check `ls ~/.claude/commands/` — the symlinks should be present after stow.
