# ADR-0001: gdUnit4 6.2.2 as the single test entry point

## Status

Proposed

> Acceptance belongs to the user or `technical-director` (see
> `.claude/docs/templates/architecture-decision-record.md`). This ADR was
> authored by `devops-engineer` for epic W0-E1 and is not yet accepted.

## Date

2026-11-09

## Last Verified

2026-11-09

## Decision Makers

`devops-engineer` (author, W0-E1), `qa-lead` (epic owner). Acceptance pending
from `technical-director` or the user.

## Summary

The project declares gdUnit4 in its test standards but had no addon installed
and no test tree, so `project.yaml → commands.test` pointed at a missing runner.
This ADR records the decision to vendor gdUnit4 6.2.2 under
`addons/gdUnit4/`, to make one headless command the single entry point for every
test, and to require CI to fail on any non-zero exit code.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — Godot 4.7 post-dates the LLM cutoff (see `docs/engine-reference/godot/VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; vendored `addons/gdUnit4/plugin.cfg` and `src/core/runners/GdUnitTestSessionRunner.gd` |
| **Post-Cutoff APIs Used** | None in project code. The decision relies only on Godot's `--headless` and `-s` command-line flags and on gdUnit4's own CLI. |
| **Verification Required** | Run `commands.test` on a clean checkout; confirm exit `0` with tests present, exit `100` for a failing assertion, and exit `101` for orphan nodes. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | W0-E2 (port the four `tools/verify_*.gd` suites), W0-E4 (blocking CI) |
| **Blocks** | W0-E2, W0-E3 (regression protection), W0-E4 |
| **Ordering Note** | W0-E1 is the only epic allowed to edit `project.godot` in this phase. Later epics add autoloads and i18n there, but must not change the test entry point. |

## Context

### Problem Statement

The project's testing standards name gdUnit4 and gdUnit4's assertion style, but
the addon was not installed. `commands.test` invoked
`res://addons/gdUnit4/bin/GdUnitCmdTool.gd`, which did not exist, so the command
could only fail — and a command that always fails is indistinguishable from a
command that is not run at all. Every later epic needs a trustworthy red/green
signal before it can refactor.

### Current State

- No `addons/` directory, no `tests/` directory.
- Four throwaway `SceneTree` scripts (`tools/verify_facing.gd`,
  `verify_slice02.gd`, `verify_slice03.gd`, `verify_slice04.gd`) check behaviour
  by printing `PASS`/`FAIL` and quitting with `0`/`1`. Porting them is W0-E2.
- `commands.test` existed but pointed into the void.

### Constraints

- Vendor from the official GitHub release only; no homemade harness.
- Engine is Godot 4.7.2; the addon must support 4.7.
- No commit or push in this epic.
- CI (W0-E4) must be able to run the same command with no editor GUI.

### Requirements

- One command runs every suite under `tests/`.
- The process exit code distinguishes pass from fail without parsing output.
- Unit and integration suites live at fixed roots (`tests/unit/`,
  `tests/integration/`) per `.claude/rules/test-standards.md`.
- The addon is reproducible: version, source URL and checksum recorded.
- Reusable fixture for suites that need the real main scene.

## Decision

Vendor gdUnit4 **6.2.2** at `addons/gdUnit4/` from
`https://github.com/godot-gdunit-labs/gdUnit4/archive/refs/tags/v6.2.2.zip`
(tag commit `0127a55f4543dfc24746f6e5c7ba6f94105d51f2`, SHA-256
`ddb44730ffb9cd77fd70d283753450759b00c5016143d7572bf63625f64d5433`), record it
in `addons/gdUnit4/VENDOR.md`, and make this the single test entry point:

```text
"C:/Users/balthazar/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

`project.yaml → commands.test` holds exactly this string. The plugin is enabled
in `project.godot` (`[editor_plugins] enabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")`).

The previous command carried `-d --remote-debug tcp://127.0.0.1:0`. Godot 4.7
rejects port `0` ("The remote port number must be between 1 and 65535"), printing
two errors on every run. Both flags were removed: `-d` only enables debug-build
features the tests do not use, and a remote-debug client is meaningless in CI.

### Architecture Diagram

```text
project.yaml (commands.test)
        │  headless Godot 4.7.2 console
        ▼
addons/gdUnit4/bin/GdUnitCmdTool.gd  ──scans──▶  res://tests/
        │                                            ├── unit/*_test.gd
        │                                            ├── integration/*_test.gd
        │                                            └── fixtures/main_scene_fixture.gd
        ▼                                            (plain RefCounted: never collected)
 exit 0 / 100 / 101 / 103 / 104 / 105
```

### Key Interfaces

- **Suite**: a script under `tests/` extending `GdUnitTestSuite`. Naming per
  `.claude/rules/test-standards.md`: file `[system]_[feature]_test.gd`,
  function `test_[scenario]_[expected]`.
- **Fixture**: `tests/fixtures/main_scene_fixture.gd` (class `MainSceneFixture`).
  Referenced with `const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")`
  rather than a global `class_name`, so a suite runs on a fresh clone whose
  `.godot/global_script_class_cache.cfg` predates the helper. Exposes
  `instantiate(suite)`, `await_ready(suite, frames)`, `silence_waves(main)`.
- **Reports**: gdUnit4 writes `reports/report_<n>/results.xml` and
  `index.html`; `/reports/` is gitignored.

### Implementation Guidelines

- Tests must never be added under `addons/`; that tree is vendored and replaced
  wholesale on upgrade.
- A suite must release every node it creates — `auto_free()` in the suite, or
  `MainSceneFixture.instantiate(suite)` — or the run reports orphans (exit 101).
- `commands.test` must stay a single command; CI (W0-E4) invokes it verbatim.
- Upgrading the addon must update `addons/gdUnit4/VENDOR.md` in the same change.
- The addon directory must never be edited in place.

## Alternatives Considered

### Alternative 1: GUT (Godot Unit Test)
- **Description**: Another mature Godot testing addon.
- **Pros**: Widely used, GUI runner.
- **Cons**: The project's test standards and CI command are already written
  against gdUnit4's suite/assertion API; GUT would require rewriting the
  standards and every future suite.
- **Estimated Effort**: Medium now, high over the epic.
- **Rejection Reason**: Contradicts the committed standard; no functional gain.

### Alternative 2: Keep the `SceneTree` verify scripts
- **Description**: Continue adding `tools/verify_*.gd` scripts with manual
  `quit(0/1)`.
- **Pros**: No dependency; already works.
- **Cons**: No discovery (each script must be invoked by name), no shared
  assertions or fixtures, no reports, no orphan detection, and output must be
  parsed to know what failed.
- **Estimated Effort**: Low initially, high as the suite grows.
- **Rejection Reason**: It is the status quo the plan explicitly replaces; W0-E2
  ports these four scripts into gdUnit4 suites.

### Alternative 3: Bring in a test framework from the Asset Store
- **Description**: Install gdUnit4 through the Godot 4.7 Asset Store.
- **Pros**: One-click, version channel maintained by the editor.
- **Cons**: Not reproducible — nothing records what version was fetched; the
  plan requires a pinned, auditable source.
- **Estimated Effort**: Lower to install, higher to audit.
- **Rejection Reason**: GitHub tag + checksum is reproducible and reviewable.

## Consequences

### Positive
- One command, one exit code, one place for every suite.
- The framework is pinned and checksummed; upgrades are explicit.
- W0-E2 can port the verify scripts under a runner that already proves red.

### Negative
- 2.1 MB of third-party source enters the repository (516 files after Godot
  generated `.uid` sidecars).
- Upgrades are manual: re-download, replace, re-record, re-run.
- The runner requires Godot's script class cache to know gdUnit4's global
  classes. The cache is committed (`.gitignore` keeps
  `global_script_class_cache.cfg`), so a clone works; if it is ever regenerated
  stale, run `godot --headless --path . --import` once before testing.

### Neutral
- `reports/` appears at the project root after a run and is gitignored.

## Risks

- **Upstream incompatibility with a future Godot version** — mitigated by
  re-running the suite after any engine upgrade; the VENDOR record makes the
  exact version under test explicit.
- **Headless limitations** — gdUnit4 warns that UI input events are not
  transported in headless mode. Suites must not assert on simulated input;
  visual/feel evidence stays in `production/qa/evidence/` per the coding
  standards.
- **Orphan nodes** — a suite that forgets `auto_free` exits 101 rather than 0;
  CI (W0-E4) must treat every non-zero code as a failure, not only 100.
- **Malicious or corrupted download** — mitigated by HTTPS from `github.com`,
  the recorded tag commit and the recorded archive SHA-256.

## GDD Requirements Addressed

Foundational — no GDD requirement. Enables: W0-E2 (ported verify suites),
W0-E3 (data refactor protected by tests), W0-E4 (blocking CI), and every later
epic that needs a red/green signal.

## Performance Implications

- **CPU**: Test runs only; no runtime cost in the game.
- **Memory**: No runtime cost.
- **Load Time**: No runtime cost; headless suite of 2 tests completes in ~0.3 s.
- **Network**: Only at vendoring/upgrade time.

## Migration Plan

No project code changes. `commands.test` was corrected; `tests/` was created;
the addon was vendored. W0-E2 ports the four `tools/verify_*.gd` scripts into
`tests/` and deletes them.

**Rollback plan**: remove `addons/gdUnit4/`, `tests/` and the
`[editor_plugins]` entry, and restore the previous (broken) `commands.test`
only if replacing the framework; otherwise delete the tests.

## Validation Criteria

- `commands.test` exits `0` with 2/2 cases passing, 0 errors, 0 orphans.
- A deliberately false assertion exits `100` with the failing expectation in
  the report.
- Exit codes `101`, `103`, `104`, `105` mean orphan/warning, headless not
  supported, unsupported Godot version and script errors respectively; CI must
  fail on all of them.
- W0-E4 fails the build when zero suites are executed.

## Related

- `production/plans/drastic-upgrade-plan.md` — W0-E1, W0-E2, W0-E4.
- `.claude/rules/test-standards.md` — naming and arrange/act/assert.
- `.claude/docs/coding-standards.md` — Godot CI command.
- `addons/gdUnit4/VENDOR.md` — provenance and upgrade steps.
- `tests/fixtures/main_scene_fixture.gd` — reusable scene fixture.
