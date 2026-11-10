# ADR-0008: Weapon evolutions — one declarative step per weapon, one per run

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-10

## Last Verified

2026-11-10

## Decision Makers

- `game-designer` — what an evolution promises and how the player learns it
- `systems-designer` — condition shape, level retention, and the raised cap
- `lead-programmer` — where run-scoped evolution state lives, offer-priority path
- `godot-gdscript-specialist` — typed `Resource` references, null-safe chains, `StringName` catalyst tokens

## Summary

Lot 1 gave weapons a level axis; lot 2 gives ten of them a **destination**. Each
base weapon names its evolved form in data (`evolves_into`), declares when it
becomes available (`evolution_level`, optionally a catalyst `evolution_passive`),
and the run allows **one evolution in total** (`Inventory.evolved_weapon_id`).
When the condition is met the evolution is not a weighted candidate: it is the
**first row** of the level-up panel, tinted, announced by a ring, a dedicated
sound and a banner. The evolved weapon replaces its base in the same slot,
**keeps the level reached**, and climbs to its own higher cap (7). Content stays
declarative: ten base `.tres` point at ten evolved `.tres` that are never listed
in `Catalogue.weapons`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 stable |
| **Domain** | Gameplay / progression |
| **Layer** | Feature |
| **Knowledge Risk** | LOW — typed `Resource` references, `Array`, `StringName`, no post-cutoff engine API |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `design/gdd/weapons.md` §3.10 and F14, ADR-0005, ADR-0006 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Full suite green in `fr` and `--language en` (189 tests / 25 suites); retained screenshots of the evolution offer, the banner and the evolved HUD row |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0005 (weapon levels — the condition reads `level_of`), ADR-0006 (equipment passives — the two catalysts), `design/gdd/weapons.md` §3.10 |
| **Enables** | Lot 4 — the save format must serialise `evolved_weapon_id` alongside `weapon_levels` |
| **Blocks** | None |
| **Ordering Note** | Delivered between lot 3 and lot 4, per the avenant; the GDD and this ADR land in the same changeset as the code |

## Context

### Problem Statement

Weapon levels made a carried weapon grow, but every weapon grew the same way: a
number. The roguelite plan's lot 2 asks for **weapon identity through
transformation** — a build-defining moment in a run, gated by investment (a
level), optionally by a complementary piece of equipment, and rare enough to be
a story the player tells afterwards.

### Current State

- `WeaponData` carries `id`, `display_name`, `mechanic`, combat fields,
  localisation keys, and lot 1's `max_level` + three additive level steps.
- `Inventory.weapon_levels` maps a weapon `id` to a run-scoped level;
  `level_of`, `can_upgrade_weapon`, `upgrade_weapon` operate on it.
- `_build_offers` assembles weighted `Offer` candidates; `_pick_weighted`
  guarantees at most one weapon row per panel (A2).
- `Offer` has one static constructor per kind; `_apply_offer` dispatches by
  `kind`.
- The HUD renders the weapon column from the inventory every frame, and its
  largest label (`_wave_banner`) is reused by wave announcements.

### Constraints

- Content resources are shared by every run (`load()` caches them): a `.tres`
  must never carry run state — including "already evolved".
- An evolved weapon is content like any other but must not be offered as a new
  weapon; the catalogue therefore cannot list it (AC: the data test asserts it).
- Every gameplay value stays data-driven: the level required, the catalyst, the
  evolved cap and all feedback (colour, sound, banner text, duration) live in
  `.tres`/`RunConfig`, never in code.
- One evolution per run is a **rule**, not a UI convention: it must hold at the
  data layer so a forced call cannot bypass it.
- A panel built before a state change must not be able to act on a stale
  condition (the reroll path rebuilds the panel; a debug path might not).
- New player-facing strings go through `data/localization/strings.csv` (A6).
- `modes.workflow: full` requires this ADR and the GDD's 8 sections.

### Requirements

- A weapon declares `evolves_into` and a condition: required level (0 = own
  `max_level`) and optional catalyst passive.
- The condition met, the evolution appears in the **next** level-up panel, first
  row, visually distinct, exactly once.
- Taking it replaces the base in its slot, keeps the level, raises the cap.
- The base is never re-offered as an acquisition afterwards.
- The moment reads as a reward: ring, sound, banner, all tuned in `RunConfig`.
- After one evolution, no second evolution can be taken in the same run.

## Decision

### Data model

`WeaponData` gains three fields:

| Field | Type | Default | Meaning |
|---|---|---|---|
| `evolves_into` | `WeaponData` | `null` | The evolved form. A null or id-less target means no evolution (`has_evolution()` is false). |
| `evolution_level` | `int` | `0` | Level required; `0` delegates to this weapon's own `max_level`. |
| `evolution_passive` | `StringName` | `&""` | Optional catalyst token; empty means no catalyst. Known: `rage`, `level_up_heal`. |

`evolution_level_required()` returns `evolution_level` when positive, else
`max_level`. The evolved `WeaponData` is an ordinary weapon resource living in
`data/weapons/evolved/`, with its own `id`, name/description keys, combat
numbers and a higher `max_level` (7 in v1). It carries `evolves_into = null`, so
an evolution cannot chain, and it is **not** listed in `Catalogue.weapons` — it
is reachable only through its base's field.

### Where the rules live

- `Inventory.evolved_weapon_id: String` — the id of the base that evolved, or
  `""`. This is the run's one-evolution latch and lives with the other
  run-scoped state (`weapon_levels`), not on the shared resource.
- `Inventory.evolution_ready(weapon) -> bool` — carried, `has_evolution()`,
  latch empty, level ≥ `evolution_level_required()`, and (when a catalyst is
  named) `passive_total(catalyst) > 0.0`. The catalyst is read from what is
  equipped **now**, so removing the piece withdraws the offer.
- `Inventory.evolve_weapon(weapon) -> bool` — revalidates `evolution_ready`,
  finds the slot by `id`, erases the base's level entry, writes the same level
  under the evolved `id`, swaps the slot, sets the latch. Returns `false` and
  changes nothing when any check fails.
- `Inventory.has_evolved_from(weapon) -> bool` — true for the base that evolved;
  the offer builder keeps that resource out of the acquisition pool for the rest
  of the run.
- `Inventory.setup_starting` clears `evolved_weapon_id` with `weapon_levels`: the
  evolution is run state, not an unlock.

### Offer priority

`_evolution_offer()` returns at most one `Offer` — `Inventory.evolution_ready`
already refuses every candidate once the latch is set. In `_build_offers`:

1. If an evolution is ready, **no** acquisition and **no** level row is built
   (the evolution owns the panel's single weapon row, A2).
2. The other kinds are assembled normally, then every weapon row is stripped
   from that pool — nothing can compete with or duplicate the evolution.
3. The panel is `[evolution] + _pick_weighted(rest, count - 1)`, so the
   evolution is row 0 whatever the draw.
4. If the stripped pool is empty, the fallback stat upgrade is appended, so a
   panel that has an evolution never opens short.

The evolution is not weighted: a weight would let terrible draws hide a reward
the player has invested a level (and possibly a build slot) to earn.

### Feedback

`_evolve_weapon(offer)` applies the swap, calls `WeaponSystem.refresh()`
(preserving in-flight cooldowns by slot), then emits three signals in the
`RunConfig.evolution_color`:

| Channel | Implementation | Tuning |
|---|---|---|
| Ring | `RingBurst.create(_player.position, _config.evolution_color)` | `evolution_color` |
| Sound | `Sfx.play(_config.evolution_sound)` | `evolution_sound = "evolution"` |
| Banner | `Hud.show_evolution_banner(Loc.format(key, fallback, [name]), color, seconds)` | `evolution_banner_key`, `evolution_banner_seconds = 2.2` |

`show_wave_banner` removes the banner's `font_color` override before writing a
wave, so the violet of an evolution never leaks into an ordinary announcement.
The panel itself tints the evolution row through `_style_option(index,
is_evolution, accent)`.

### Readability

- Title: `★ Épée longue → Lame du serment` (`offer.weapon_evolution`).
- Description: the evolved weapon's effective numbers at the kept level, then
  `niv. 4 conservé · max 7` (`offer.weapon_evolution_keeps`), so the player sees
  both that nothing is lost and that the ceiling opens.
- HUD: the evolved row reads `Lame du serment · niv. 4 PRÊTE`; the readiness
  marker is text, not colour alone.
- Every evolved weapon carries `weapon.<id>.name` / `weapon.<id>.desc`, present
  in both locale columns of `strings.csv`; the catalogue test asserts the key
  pattern for each of the ten forms, so a renamed field cannot ship silently.

### Key interfaces

```gdscript
# WeaponData
@export var evolves_into: WeaponData = null
@export var evolution_level: int = 0
@export var evolution_passive: StringName = &""
func has_evolution() -> bool
func evolution_level_required() -> int

# Inventory
var evolved_weapon_id: String = ""
func evolution_ready(weapon: WeaponData) -> bool
func evolve_weapon(weapon: WeaponData) -> bool
func has_evolved_from(weapon: WeaponData) -> bool

# Offer
var evolved_weapon: WeaponData = null
static func for_weapon_evolution(carried: WeaponData, evolved: WeaponData, level: int) -> Offer
```

### Implementation guidelines

- The evolution latch **must** live in `Inventory`, never on `WeaponData`: the
  evolved `.tres` files are shared by every run.
- `evolve_weapon` **must** revalidate its condition; the offer panel is a
  client, not the authority.
- A catalyst **must** be compared as a `StringName` total against the worn
  pieces, never by display name.
- An evolved weapon **must** stay out of `Catalogue.weapons`; its presence there
  would let it be acquired directly and double the run's evolution budget.
- The evolution row **must** be first and the panel **must** carry no other
  weapon row while it waits; both are asserted, not left to the draw.
- Adding an evolution **must not** require a code change: a new base `.tres`
  pointing at a new evolved `.tres`, plus its localisation keys.

## Alternatives Considered

### Alternative 1: Make the evolution a weighted offer like any other

- **Description**: Give the evolution a `weight` in `RunConfig` and let
  `_pick_weighted` decide when it appears.
- **Pros**: No special path in `_build_offers`; the pool stays uniform.
- **Cons**: A player can meet the condition and never see the offer — the
  investment is not reliably rewarded; tuning the weight becomes a tuning of
  disappointment.
- **Estimated Effort**: Lower.
- **Rejection Reason**: A reward that can be silently missed is not a reward.
  The plan's requirement is "dedicated, highlighted offer"; priority is the
  simplest honest reading.

### Alternative 2: Store the evolution on the inventory as a separate weapon

- **Description**: `evolve_weapon` adds the evolved weapon as a fourth carried
  weapon and removes the base; the slot count is not tied to the swap.
- **Pros**: No level migration: the evolved weapon starts at level 1.
- **Cons**: Violates "keeps the level" (A5) and lets the run dodge the
  three-slot rule; a player would feel punished for evolving.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Level retention is the promise that makes the moment
  read as an upgrade rather than a reset.

### Alternative 3: Chain evolutions (evolved weapon evolves further)

- **Description**: Do not forbid `evolves_into` on evolved resources; let the
  latch be per-weapon instead of per-run.
- **Pros**: More content depth later.
- **Cons**: The one-per-run rule becomes a per-weapon rule, inflating the number
  of transformations a build can express; balance would need a second cap axis
  before the first is played.
- **Estimated Effort**: Higher.
- **Rejection Reason**: Deferred until playtesting shows one evolution per run
  is too few. The data test enforces `has_evolution() == false` on evolved
  resources so the decision cannot drift by accident.

## Consequences

### Positive

- A build now has a destination the player can plan towards from the first
  level of a weapon.
- Lot 3's passives compose with lot 2: a catalyst turns equipment into half of
  an evolution condition, which is a real build decision.
- Content scales by data: a new evolution is two `.tres` files and their keys.
- The loud feedback makes the moment legible without a new screen or input.

### Negative

- A run can take at most one evolution, so a second qualifying weapon does not
  pay off in that run; the GDD states it, the panel shows the first found.
- The evolution path special-cases `_build_offers`, one more branch to keep
  correct as offer kinds grow.
- Evolved weapons need their own balance pass (level 4 → 7 curve) beyond the
  base ten.

### Neutral

- Ten base weapons each name an evolved form in v1; the catalogue counts stay
  at 10 base weapons because evolved forms are not listed.
- The latch is simple string state, compatible with the lot 4 save format.

## Risks

- **Shared resource mutated by a test or debug path.** Mitigation: the latch is
  on `Inventory`; `evolve_weapon` is the only writer, and no test touches
  `evolves_into`.
- **The base comes back through the acquisition pool.** Mitigation:
  `has_evolved_from` filters it for the rest of the run; the integration suite
  asserts it after an evolution with the slot reopened.
- **A stale panel bypasses the condition.** Mitigation: `evolve_weapon`
  revalidates `evolution_ready`; a failed call changes nothing.
- **The banner colour leaks into a wave announcement.** Mitigation:
  `show_wave_banner` clears the override; asserted in the suite.
- **Localisation drift on twenty new keys.** Mitigation: the catalogue test
  asserts each evolved weapon's key pattern, both locale columns are filled, and
  the full suite runs under `--language en` as well as French.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `weapons.md` §3.1, A5 | One evolution per run; evolved keeps the level and raises its own cap | `evolved_weapon_id` latch, level migration, evolved `max_level` |
| `weapons.md` §3.10 | Declarative condition: level and optional catalyst passive | `evolution_level`, `evolution_passive`, `evolution_level_required()` |
| `weapons.md` §3.10 | Dedicated, highlighted offer; one weapon row (A2) | First-row priority in `_build_offers`, tinted `_style_option`, no competing weapon row |
| `weapons.md` F14 | Condition and level formulas, worked example | `evolution_ready`, `evolve_weapon`, catalogue data rule |
| `weapons.md` §3.10 | Ring, sound, banner tuned in `RunConfig` | `_evolve_weapon` reads all four `evolution_*` fields |
| `weapons.md` E26–E33 | Determinism of the evolution edge cases | Unit and integration suites plus the catalogue test |
| `weapons.md` AC17–AC21 | Testable acceptance conditions | 12 unit + 11 integration + 13 catalogue tests, screenshots |

## Performance Implications

- **CPU**: One pass over at most three carried weapons when building a panel; one
  `refresh()` per evolution. Negligible.
- **Memory**: Three fields per base weapon and ten small evolved resources.
- **Load Time**: Ten extra `.tres` loads through their bases at catalogue load.
- **Network**: Not applicable.

## Migration Plan

1. Extend `WeaponData` with the three fields and the two helpers.
2. Add the ten evolved `.tres` files in `data/weapons/evolved/` and point each
   base at its form with its level and catalyst.
3. Extend `Inventory` with the latch and the three methods; clear it in
   `setup_starting`.
4. Add `Offer.for_weapon_evolution`, `_evolution_offer` and the priority branch
   in `_build_offers`; wire `_evolve_weapon`.
5. Add `evolution_*` fields to `RunConfig`/`data/run_config.tres`; add
   `assets/audio/sfx/evolution.wav`; add the strings in `fr` and `en`.
6. Extend the HUD (banner, row suffix, row tint).
7. Unit, integration and catalogue tests; capture the three screenshots.

**Rollback plan**: remove the priority branch and `_evolve_weapon`; clear
`evolves_into` in the ten base `.tres`. The latch and levels read as unused
fields, and no save format depends on them yet (lot 4 is not started).

## Validation Criteria

- Full suite green in French and English (189 tests / 25 suites).
- Below the required level, or without the catalyst, no evolution row exists;
  with both, exactly one, first row, no other weapon row.
- Taking it keeps the level (`level_of(evolved) == required`), swaps the slot,
  and the evolved weapon can still be levelled towards its cap of 7.
- A second evolution cannot be taken in the same run, and the base is never
  re-offered as an acquisition.
- The banner carries the evolved weapon's name, the `RunConfig` colour and
  duration, and a subsequent wave banner has no colour override.
- Retained screenshots show the highlighted first row, the banner and the
  evolved HUD row (`production/qa/evidence/lot2-*.png`).

## Related

- `design/gdd/weapons.md` — the contract this ADR implements (§3.10, F14, E26–E33, AC17–AC21)
- `docs/architecture/ADR-0005-weapon-levels.md` — the level axis the condition reads
- `docs/architecture/ADR-0006-equipment-identity.md` — the passives used as catalysts
- `docs/architecture/ADR-0007-save-format.md` — lot 4 must serialise the latch
- `src/data/weapon_data.gd`, `src/classes/inventory.gd`, `src/classes/offer.gd`,
  `src/main.gd`, `src/ui/hud.gd`, `src/data/run_config.gd`
