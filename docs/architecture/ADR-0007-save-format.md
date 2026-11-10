# ADR-0007: Meta save format — ConfigFile at `user://meta.cfg`

## Status

Proposed

## Date

2026-11-10

## Last Verified

2026-11-10

## Decision Makers

- `game-designer` — what must survive a run, and what must never be bought with it
- `economy-designer` — ink balance, unlock costs, failure economics
- `lead-programmer` — `ProfileData` / `MetaStore` / `MetaSave` split, autoload wiring
- `godot-gdscript-specialist` — `ConfigFile`, `FileAccess` and `DirAccess` usage on Godot 4.7.2

## Summary

The meta-progression system needs a small, durable, local profile — ink, purchased
unlocks, start selections and records — that can never stop the game from starting.
This ADR decides **`user://meta.cfg` written with Godot's `ConfigFile`**, versioned
with an explicit `version` key and forward-only ordered migrations, wrapped by a
testable `ProfileData` / `MetaStore` / autoload `MetaSave` split, with `.bak`
recovery and default-profile fallback on every failure path.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 stable |
| **Domain** | Core / persistence |
| **Layer** | Foundation |
| **Knowledge Risk** | LOW — `ConfigFile`, `FileAccess`, `DirAccess` and `user://` are stable pre-cutoff APIs; no post-cutoff engine API is used |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/breaking-changes.md` (`FileAccess.store_*` return `bool` since 4.4 — only relevant if a binary format is ever considered) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Round-trip, absent/corrupt/truncated/future-version fixtures, v0→v1 migration, `.bak` recovery, save-failure path; full suite green; home-screen screenshot at 0 ink |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | W7-E2 — `MetaSave`, home screen, unlock purchases, run-credit settlement |
| **Blocks** | W7-E2 stories until this ADR is `Accepted` |
| **Ordering Note** | This ADR ships with `design/gdd/meta-progression.md` in the same changeset. `design/gdd/systems-index.md` is updated by another agent and is not edited here. |

## Context

### Problem Statement

Nothing survives a run today. `main.gd` reloads the scene on `R` and every run
starts from zero; there is no `FileAccess`, `ConfigFile` or `user://` use anywhere
in `src/` (`prompts/ameliorations-roguelite.md` §26 records this as a constraint).
The meta-progression GDD introduces a persistent currency and four durable
unlocks, so the project now needs a save file — and it needs one that **cannot
stop a player from playing**. A malformed file must degrade to defaults, not to a
crash or a locked home screen.

The save is also **untrusted input**: it lives in `user://`, can be hand-edited,
copied between machines, truncated by a power loss or restored from a cloud
backup. The format decides how much damage a bad file can do.

### Current State

- No save system, no autoload, no player profile.
- All run state lives in scene objects and is destroyed on reload.
- `data/` holds shared `.tres` resources loaded from `res://`; none of them is
  writable per player.
- The game has no settings store yet; W6-E2 plans a `SettingsStore` autoload,
  which is a separate lifecycle from the meta profile.
- `project.godot` currently starts directly on the run scene; the meta GDD adds a
  home screen and therefore a new startup scene.

### Constraints

- Godot 4.7.2, GDScript; gameplay values are data-driven and must not live in the
  save file.
- The save must load before the home screen renders, once per launch; never on
  the frame loop.
- Tests must be able to point the store at a temporary path — no test may read or
  write the real `user://meta.cfg`.
- A new player with no file must be able to launch and finish a full run.
- A save written by a newer build must not be silently downgraded by an older
  build.
- `modes.workflow: full` — the ADR carries the full template, and the GDD's
  acceptance criteria depend on this contract.
- The localization standard requires every new player-facing string, including
  the save-error banner, to go through `strings.csv` with a French fallback.

### Requirements

- R1 — Persist `version`, ink balance, lifetime ink, purchased unlock ids, class /
  arena / difficulty selections, and four informational records.
- R2 — Absent, truncated, corrupt or wrongly-typed files must load a default
  profile, log discreetly, and never crash or block Play.
- R3 — A file from an older version migrates forward through explicit, ordered,
  pure migration steps.
- R4 — A file from a newer version is loaded read-only and never overwritten.
- R5 — A failed write keeps the previous good file and never corrupts it.
- R6 — The save contains state only; costs, rates, multipliers and `ink_value`
  stay in `res://data/`.
- R7 — The store is unit-testable without an autoload or a scene tree, with an
  injected path.
- R8 — Writing happens on discrete events (purchase, selection change, run
  settlement), never per frame.

## Decision

### 1. Format: `ConfigFile` at `user://meta.cfg`

The profile is a plain-text, INI-style file written and read with Godot's
`ConfigFile`, which returns typed Variants and an `Error` code instead of
throwing. It is not a `Resource`, so loading it never instantiates a script or a
sub-resource named inside the file. A `.tres` save would go through
`ResourceLoader`, which **can** reference and instantiate `res://` scripts from a
user-writable file — an unnecessary code-execution surface and a fragile failure
mode for a 1–2 KB profile.

The chosen format also gives, for free: human-readable sections, per-key defaults,
partial recovery (one bad key does not discard the file), and a schema that can be
diffed in a bug report.

### 2. Schema (version 1)

```ini
[meta]
version=1

[ink]
balance=284
lifetime=1342

[unlocks]
purchased=PackedStringArray("fourth_slot", "second_class")

[selection]
class="chevalier"
arena="default"
difficulty="conte"

[records]
runs=12
wins=4
best_wave=10
best_ink=284
```

| Section | Key | Type | Default when absent | Validation |
|---|---|---|---|---|
| `meta` | `version` | int | `0` | `< 0` or non-int → `0` + warning; `> CURRENT_VERSION` → read-only mode (R4) |
| `ink` | `balance` | int | `0` | clamped to `≥ 0` |
| `ink` | `lifetime` | int | `0` | clamped to `≥ balance` (repair, warning) |
| `unlocks` | `purchased` | `PackedStringArray` | empty | canonical writer type; loader also accepts a plain `Array` and coerces string elements; duplicates removed; empty entries dropped; unknown ids preserved on same-version saves |
| `selection` | `class` | String | `"chevalier"` | must be a known, unlocked class; otherwise default + warning |
| `selection` | `arena` | String | `"default"` | must be a known, unlocked arena; otherwise default + warning |
| `selection` | `difficulty` | String | `"conte"` | must be a known, unlocked difficulty; otherwise `"conte"` + warning |
| `records` | `runs` | int | `0` | `≥ 0` |
| `records` | `wins` | int | `0` | clamped to `0 … runs` |
| `records` | `best_wave` | int | `0` | clamped to `0 … total_waves` |
| `records` | `best_ink` | int | `0` | `≥ 0` |

**Never in the file:** unlock costs, victory/defeat rates, difficulty multipliers,
`ink_value`, XP values, weapon or class stats, settings (audio, input, locale),
run-in-progress state, or any `res://` path that a designer could mistake for
tuning data. The file is state; the rules are content.

`records` are informational only: they never gate an unlock, a selection or a
purchase. `wins` and `runs` are updated at settlement together with the ink
credit, so a crash between the two writes loses at most the last record — not the
ink (the ink is written first in the same save).

### 3. Architecture: pure data, testable store, thin autoload

```text
MetaConfig (.tres, res://)            ProfileData (RefCounted)
├─ victory_rate = 1.00                ├─ version: int
├─ defeat_rate = 0.70                 ├─ ink: int
├─ difficulties[]                    ├─ ink_lifetime: int
└─ unlocks[] (ordered UnlockData)     ├─ purchased: PackedStringArray
                                      ├─ class_id / arena_id / difficulty_id
UnlockData (.tres, res://)            └─ records: Dictionary
├─ id, cost, requires, capability
└─ name_key, description_key         MetaStore (RefCounted, injected path)
                                      ├─ load() -> LoadResult
                                      ├─ save(profile) -> Error
                                      └─ migrate(dict, from, to) -> dict

                                     MetaSave (autoload Node)
                                      ├─ owns one MetaStore at user://meta.cfg
                                      ├─ exposes ink / is_unlocked / purchase
                                      ├─ credit_run(...) -> int
                                      ├─ selection setters (validated)
                                      └─ signals: ink_changed, unlock_purchased,
                                                  save_failed, profile_recovered
```

- `ProfileData` is a plain `RefCounted` with defaults, `to_dict()` and
  `from_dict(dict)`. It performs no file I/O and knows no engine path.
- `MetaStore` owns one path and the load/save/migration algorithms. It is
  constructed with a path; the default `user://meta.cfg` is chosen **only** by the
  autoload. Tests pass a temporary path.
- `MetaSave` is the autoload façade the scenes talk to. It loads once in
  `_ready()`, keeps the profile in memory, validates selections against
  `MetaConfig` and the loaded content, and writes on discrete events.
- `MetaConfig` and `UnlockData` are shared `.tres` resources under `res://data/meta/`;
  they are never written and never copied into the save.

### 4. Load algorithm and failure matrix

1. If `user://meta.cfg` does not exist → default profile, status `fresh`, no error,
   no file created. The first write creates it.
2. `ConfigFile.load(main)`:
   - on success → parse and validate keys (step 4);
   - on failure → try `user://meta.cfg.bak`; if it loads, use it, emit
     `profile_recovered`, log one warning;
   - if both fail → default profile, log one warning, best-effort rename of the
     main file to `user://meta.corrupt-<unix>.cfg` so the next save does not
     destroy the evidence.
3. Read `meta/version`; if it is greater than `CURRENT_VERSION`, set
   `read_only = true` and continue with the recognised keys only.
4. Read each key **individually** with its expected type and default; collect
   warnings; validate values and selections; repair `lifetime` and `wins` as
   described in the schema.
5. If `version < CURRENT_VERSION`, apply ordered migrations to the raw dictionary
   first, then rebuild the profile and save the migrated file (after a backup).
   A migration failure quarantines the file and falls back to defaults.
6. Loading never throws, never blocks the home screen and never retries in a loop.

| Condition | Detection | Behaviour | File effect |
|---|---|---|---|
| Absent | `FileAccess.file_exists` false | defaults, `fresh` | none until first save |
| Truncated / unparsable | `ConfigFile.load` ≠ `OK` | try `.bak`, else defaults + quarantine | main untouched until next save |
| Valid but bad key | per-key type/value check | replace that key, warn, keep the rest | rewritten on next save |
| Older version | `version < CURRENT` | migrate then save | rewritten after backup |
| Newer version | `version > CURRENT` | read-only, warn, Play still enabled | **never written** |
| Write failure | `Error` from save/rename | keep in memory, emit `save_failed`, warn | previous good file preserved |

### 5. Save algorithm: temp file, verification, backup

1. Serialize `ProfileData` into a **fresh** `ConfigFile`.
2. Write to `user://meta.cfg.tmp`; abort on `Error`.
3. Re-load the temp file into a scratch `ConfigFile` and verify that `version` and
   the required keys parse; abort if not (this catches a bad serialization before
   it replaces a good file).
4. If `user://meta.cfg` exists, copy it to `user://meta.cfg.bak` — best-effort; a
   failed backup does not abort the save, because the temp file has already been
   verified.
5. Replace the main file: remove the existing main, then rename the temp to main
   with `DirAccess` on absolute paths. There is no portable atomic-replace
   guarantee in Godot; the `.bak` covers the small window between remove and
   rename.
6. On any failure: best-effort remove the temp, return the `Error`, emit
   `save_failed`; the in-memory profile stays authoritative for the session.

Saves happen on: purchase, selection change, and run settlement (one write per
event). Records and ink are written together at settlement. Never per frame.

### 6. Version and migration policy

- `CURRENT_VERSION = 1` in this ADR. The first shipped build writes v1.
- **v0** means a file with no `version` key (hand-edited or a pre-release build).
  v0→v1 sets `version = 1` and keeps every recognised key. Because v0 never
  shipped, no player data depends on it; the path is still tested because it is
  the natural "missing version" case.
- Migrations are **pure functions** `Dictionary -> Dictionary`, ordered by version,
  applied one step at a time. A migration must be additive (new keys with
  defaults) or a documented transform; it must never silently delete a key.
- Each version bump requires: a fixture of the previous version, a unit test that
  migrates it, and a note in this ADR's `Last Verified` / a new ADR if the change
  is structural.
- A newer file is **read-only**. The current build never migrates down and never
  overwrites keys it does not understand. If the player relaunches on the newer
  build, nothing is lost.
- If a migration fails, the file is quarantined and the player continues on
  defaults with one warning. Losing meta is preferable to not playing.

### 7. Key interfaces

```gdscript
# src/meta/profile_data.gd
class_name ProfileData
extends RefCounted

static func defaults() -> ProfileData
static func from_dict(data: Dictionary) -> ProfileData
func to_dict() -> Dictionary

# src/meta/meta_store.gd
class_name MetaStore
extends RefCounted

func _init(path: String = "user://meta.cfg") -> void
func load_profile() -> LoadResult      # profile + status + warnings
func save_profile(profile: ProfileData) -> Error
static func migrate(data: Dictionary, from_version: int, to_version: int) -> Dictionary

# src/meta/meta_save.gd (autoload "MetaSave")
func ink() -> int
func lifetime_ink() -> int
func is_unlocked(id: StringName) -> bool
func purchase(id: StringName) -> PurchaseResult
func credit_run(run_ink: int, outcome: StringName, difficulty_id: StringName) -> int
func set_class(id: StringName) -> bool
func set_arena(id: StringName) -> bool
func set_difficulty(id: StringName) -> bool
func current_selection() -> Dictionary
```

`LoadResult` carries the profile, a status (`fresh`, `loaded`, `recovered_backup`,
`migrated`, `corrupt_default`, `read_only_future`) and the warning list — the home
screen can surface a discreet banner without parsing logs. `PurchaseResult` is an
enum plus the resulting balance, so the UI can show the exact refusal reason.

### 8. Implementation guidelines

- **Must** construct `MetaStore` with an explicit path; the autoload is the only
  place that hardcodes `user://meta.cfg`.
- **Must** treat every key read as untrusted: expected type, default, validation,
  warning. `ConfigFile.get_value` returns a Variant; a cast that assumes the type
  is a bug.
- **Must** keep `ProfileData` free of file I/O and of `MetaConfig` lookups; the
  autoload validates selections against content before writing them.
- **Must** write the file on discrete events only; no `_process`/`_physics_process`
  save loop.
- **Must never** load a player file through `ResourceLoader`, under any extension.
- **Must never** store a tuning value, a `res://` path or a scene reference in the
  profile.
- **Must never** overwrite a file whose `version > CURRENT_VERSION`.
- **Must** keep the `.bak` write best-effort and non-fatal; a missing backup is
  not a save failure.
- **Must** route the save banner and every home-screen string through
  `data/localization/strings.csv` (`meta.save.unavailable`,
  `meta.save.read_only_future`), with the French literal as fallback.
- **Must** register the autoload and the home scene in `project.godot` in one
  changeset, respecting the file-collision sequence in
  `production/plans/drastic-upgrade-plan.md`.

## Alternatives Considered

### Alternative 1: A `Resource` saved as `user://meta.tres`

- **Description**: define a `MetaProfile extends Resource` with exported fields
  and save it with `ResourceSaver.save()`; load it with `ResourceLoader.load()`.
- **Pros**: typed fields, inspector support, one file, familiar `.tres` workflow.
- **Cons**: `ResourceLoader.load()` on a user-writable file instantiates whatever
  `script` the file names — a tampered save can reference a `res://` script and
  execute its `_init`/property accessors. A malformed file is a coarse load
  failure with poor diagnostics, partial recovery is not practical, and `load()`
  caches resources (mitigable but an extra footgun). The schema is tied to a class,
  so a field rename is a code change plus a migration with no per-key fallback.
- **Estimated Effort**: low to write, high to harden.
- **Rejection Reason**: unnecessary code-execution surface and weaker failure
  recovery for a profile that must never block the game. `.cfg` is safer by
  construction because it is not a Resource.

### Alternative 2: JSON at `user://meta.json`

- **Description**: serialize a `Dictionary` with `JSON.stringify()` /
  `JSON.parse_string()`.
- **Pros**: portable, human-readable, tooling outside Godot, simple to inspect.
- **Cons**: Godot's JSON parser turns every number into a float, so `int` fields
  (ink, version, costs) come back as floats and need manual coercion; there are no
  sections, no typed Variants and no built-in per-key error reporting; schema
  validation is entirely manual; duplicate/absent keys are easy to miss.
- **Estimated Effort**: low.
- **Rejection Reason**: `ConfigFile` gives the same readability with native typing
  and error codes. JSON is the fallback if the profile ever has to be read outside
  Godot, but that is not a requirement.

### Alternative 3: Binary `FileAccess.store_var` or an encrypted save

- **Description**: store a Variant dictionary with `FileAccess.store_var()`, or
  encrypt it with `FileAccess.open_encrypted_with_pass()`.
- **Pros**: compact; encryption hides the contents from casual editing.
- **Cons**: opaque — a bug report cannot show the state, a human cannot repair a
  file, and a version change silently mis-reads fields. Encryption adds key
  management and a false sense of security (the key ships with the game) with no
  threat model: the game is single-player and offline, so cheating the save harms
  no one else.
- **Estimated Effort**: low.
- **Rejection Reason**: unreadable, version-fragile and not solving a real threat.
  If tamper-evidence is ever wanted, a checksum is an additive v2 key, not
  encryption.

### Alternative 4: One `settings.cfg` for settings and meta

- **Description**: one profile file for audio, input, locale and meta state.
- **Pros**: one file, one store.
- **Cons**: settings and meta have different lifecycles, write frequencies and
  failure tolerances; a corrupt audio setting should not cost the player their
  unlocks, and a meta migration should not touch input bindings. W6-E2 already
  plans a separate `SettingsStore`.
- **Estimated Effort**: low.
- **Rejection Reason**: couples two independent failure domains; the separation is
  the resilience feature.

### Alternative 5: SQLite or a third-party persistence addon

- **Description**: a small database for the profile.
- **Pros**: queries, transactions, multi-profile support.
- **Cons**: an external dependency for a 1–2 KB single-row profile; adds build,
  export and test complexity, and a native binary to ship.
- **Estimated Effort**: high.
- **Rejection Reason**: massively over-scoped; the profile is smaller than the
  code that would manage the database.

## Consequences

### Positive

- Loading a save cannot execute code: `ConfigFile` parses text and returns
  Variants; no `ResourceLoader` is involved.
- One bad key does not discard the whole profile; the loader repairs and warns.
- A power loss during a save leaves either the verified temp/backup or the
  previous good file, never a half-written main profile in the normal path.
- A newer build's file is never downgraded by an older build.
- `ProfileData` and `MetaStore` are testable with an injected path; tests never
  touch the real profile.
- The format is readable in a bug report, and a player can be told exactly which
  file to delete to reset their meta.

### Negative

- The schema is validated by hand; GDScript does not give compile-time types to
  the file contents. Every new key needs a validation case and a test.
- `PackedStringArray` serialization is a Godot text-format detail; the loader must
  also accept a plain array to survive a hand edit.
- Two files on disk (`meta.cfg` and `meta.cfg.bak`) and a small non-atomic window
  between removing the main file and renaming the temp.
- Last-write-wins if two game instances run at once.
- No encryption or checksum: a determined player can edit the profile. Accepted —
  there is no competitive context.

### Neutral

- `version` is maintained manually; a schema change is a version bump plus a
  migration, not an automatic diff.
- Records are stored but not displayed by this ADR; the home screen owns their
  presentation.
- Settings remain out of scope; W6-E2's `SettingsStore` will be a separate file
  with its own policy.

## Risks

- **A key is renamed without a migration.** Mitigation: version bump policy, a
  fixture per shipped version, and a load test that asserts every schema key is
  present after migration.
- **A truncated write replaces a good profile.** Mitigation: write to `.tmp`,
  verify it parses, back up the main file, then replace; the `.bak` path is tested
  by deliberately corrupting the main file.
- **A future-version file is overwritten by an older build.** Mitigation:
  `read_only` on `version > CURRENT_VERSION`; `save()` refuses; the file's bytes
  are asserted unchanged in the test.
- **Two instances corrupt each other.** Mitigation: each write is a complete
  verified file, so the result is one of the two profiles, never a merge; the
  limitation is documented for a local solo game.
- **Tests touch the real save.** Mitigation: `MetaStore` requires a path; the
  autoload is the only default-path construction; tests use `user://tests/` and
  clean up.
- **A bad profile silently hides progress.** Mitigation: the home screen shows a
  discreet `meta.save.unavailable` or `meta.save.read_only_future` banner; the log
  records the recovery status, and the quarantined file is named.
- **Schema drifts from `MetaConfig` and `EnemyData`.** Mitigation: the save stores
  ids, never values; `MetaConfig` validation rejects unknown unlock/class/arena/
  difficulty ids, and the data tests own the id lists.
- **A migration deletes an unknown key.** Mitigation: migrations are pure,
  additive, and tested with a fixture containing an unknown key; unknown unlock
  ids are preserved on same-version saves.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `meta-progression.md` §3.1 | State survives the run; tuning values do not live in the save | Schema holds ids and counters only; `MetaConfig` / `UnlockData` stay in `res://data/`. |
| `meta-progression.md` §3.3 | Ink credited once at the end of a run, victory or defeat | `credit_run()` is a single in-memory transaction followed by one save; the settlement guard lives in `main.gd`. |
| `meta-progression.md` §3.4 | Four ordered unlocks bought with ink | `purchased` stores stable ids; order, costs and prerequisites live in `MetaConfig.unlocks`. |
| `meta-progression.md` §3.5 | Home screen always offers Play, even with no file | Default profile on every failure path; Play is never gated by the save. |
| `meta-progression.md` E1–E5 | Absent, corrupt, truncated, older and newer files | Load matrix in §4; backup recovery, quarantine, ordered migrations, read-only future mode. |
| `meta-progression.md` E12, E17 | Save failure and absurd values must not crash | In-memory session state + `save_failed`; per-key type/default/clamp validation. |
| `meta-progression.md` E21 | Two instances | Complete-file writes, last write wins, documented. |
| `meta-progression.md` AC1–AC4, AC7, AC9, AC16 | Round-trip, defaults, corruption, migration, no double credit, purchase persistence, suite green | Validation criteria below; `ProfileData` / `MetaStore` path injection makes each case a unit test. |
| `weapons.md` F13 (cross-system) | The fourth slot changes the weapon-offer budget | The save stores the `fourth_slot` id; the slot cap is resolved by the meta GDD and applied by `Inventory`, not by the save format. |

## Performance Implications

- **CPU**: one `ConfigFile.load` at startup (sub-millisecond for a < 2 KB file),
  one `save` per discrete event. No per-frame I/O, no polling.
- **Memory**: one `ProfileData` object and four short records; negligible.
- **Load Time**: below 5 ms on the target hardware; no scene or resource load.
- **Network**: none — the game is offline.

## Migration Plan

- **Greenfield v1.** No save exists today, so there is no player data to migrate
  at ship time. `version = 1` is written on the first save.
- **v0 path** (missing `version` key) is supported and tested as the "hand-edited /
  pre-release" case; it sets `version = 1` and preserves recognised keys.
- **Future bumps**: add a pure migration step, a previous-version fixture, a unit
  test, and a note here or in a superseding ADR. Never renumber or rename an
  existing key without a step.
- **Rollback**: remove the `MetaSave` autoload and the home scene, restore
  `run/main_scene` to `main.tscn`; `user://meta.cfg` remains on disk and is simply
  ignored by the reverted build. No gameplay system reads it, so rollback needs no
  data conversion.

## Validation Criteria

- `tests/unit/meta_profile_test.gd` — defaults, dictionary round-trip, validation
  and repair (`lifetime`, `wins`, negative ink), unknown-key preservation.
- `tests/unit/meta_store_test.gd` — save/load round-trip on an injected temporary
  path; absent file; truncated fixture; corrupt fixture; `.bak` recovery; migration
  v0→v1; future-version read-only with byte-for-byte unchanged file; save failure
  (read-only directory) returns an `Error` and leaves the old file intact.
- `tests/integration/meta_credit_test.gd` — `credit_run` values from
  `meta-progression.md` AC5; single settlement; death-plus-victory yields defeat;
  boss/summon accumulation from AC8.
- `tests/integration/meta_home_test.gd` — blank profile: Play enabled, four cards
  in order, zero ink, no banner; purchase persists across a reload.
- Full suite green, exit 0, no existing test removed or skipped.
- Retained screenshot `production/qa/evidence/w7-e1-meta-home.png` — home screen at
  0 ink with four unlock cards and the Play button; and one after a credited run
  showing `+N encre`.
- Manual resilience check on a copy of the real user directory: delete the file,
  truncate it at half length, corrupt one key, and hand-write a `version=2` file;
  in all four cases the game reaches the home screen and a run can start.
- File size stays below 2 KB for a fully unlocked profile.

## Related

- `design/gdd/meta-progression.md` — the model this format serves (same changeset).
- `design/gdd/classes.md` §4.5, §6.7 — simultaneous death rule and the class-unlock
  tension flagged in the meta GDD.
- `design/gdd/weapons.md` F13 — four-slot interaction flagged as an open decision.
- `prompts/ameliorations-roguelite.md` lot 3 / A3 — the source decisions.
- `production/plans/drastic-upgrade-plan.md` W7-E1 / W7-E2 — sequencing and file
  collisions.
- `docs/localization-standard.md` — keys and fallback for the save banners.
