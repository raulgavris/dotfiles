---
description: Generate tests for a file, matching the project's existing test patterns and framework.
argument-hint: <file-path> [--unit | --integration | --e2e] [--framework <name>]
---

# Generate Test

Reads the target file, detects the project's test framework, finds a nearby existing test for style, and writes a new test file (or extends an existing one).

Target: `$ARGUMENTS`

## Procedure

1. **Parse args.** First positional: the file to test. Optional flags specify test layer and override auto-detection.

2. **Detect framework.**
   - Read `package.json`, `pyproject.toml`, `go.mod`.
   - TS/JS: look for `vitest`, `jest`, `node:test`, `bun:test` in deps.
   - Python: `pytest`, `unittest`.
   - Go: stdlib `testing`; check for `testify`.
   - Rust: stdlib `#[test]` or `insta` / `proptest`.
   - If multiple are present, prefer the one the project uses in `test/`/`__tests__/`/`*_test.go`.

3. **Find a style exemplar.**
   - Walk up from the target file to the nearest test directory.
   - Read a test for a **similar** source file (same folder, similar shape). Prefer tests that use the same imports (mocks, fixtures, helpers).
   - Match: file naming pattern, describe/it style, mock setup conventions, assertion style.

4. **Read the target file.**
   - Identify exports: functions, classes, default export.
   - For each export, catalogue: input types, branches (if/else, early-return, try/catch), side effects (I/O, db, network), error conditions.

5. **Invoke `superpowers:test-driven-development` skill** if available. It informs what to test and what to skip.

6. **Draft the tests.**
   - One test per branch × one per error path × at least one happy-path integration.
   - Use fixtures and helpers from the existing suite if they fit.
   - Use descriptive test names that read as sentences.
   - For async code: test both success and rejection.
   - For timing-dependent code: use fake timers where the framework supports it.

7. **Write the test file.**
   - Place at the conventional path for this project (e.g., `__tests__/` sibling, `test/unit/<mirror>`, `<name>_test.go`).
   - Don't create a duplicate — if a test file already exists, extend it and preserve its imports.

8. **Run the new tests.**
   - Narrow command: `vitest run <new-test-file>` / `npx jest <file>` / `go test -run <Name>` / `pytest <file>`.
   - Report pass/fail. If something fails, decide: is the test wrong, or did we find a real bug? Don't paper over with `expect.any(...)`.

9. **Output.**

```markdown
## Test generation: <source file>

**Framework:** <vitest/jest/pytest/go/rust>
**Test layer:** unit / integration / e2e
**Test file:** <path>

### Tests written
| Name | Covers |
|---|---|
| … | … |

### Run result
<pass/fail summary>

### Caveats
- <e.g., needed a stub for X; real-service integration test suggested separately>
```

## Rules

- Match the project's existing style — don't introduce a new test framework or assertion library.
- Never mock the unit under test. Mock its collaborators when needed.
- Never skip or `xit` a test as a workaround. If you can't test something, say so.
- If the source file has no branches worth testing (e.g., pure re-export), say "no tests needed" rather than padding with trivial coverage.
- If you find a real bug while writing the test, **stop and report**. Don't silently fix it.
