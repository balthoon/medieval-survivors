# ADR-0005: Weapon levels as run state

## Status

Proposed

## Date

2026-11-10

## Last Verified

2026-11-10

## Decision Makers

- `game-designer` — the level curve and what the panel promises
- `systems-designer` — multiplier order, the 4-level budget
- `lead-programmer` — where the level state lives, offer plumbing
- `godot-gdscript-specialist` — typed level parameters through the weapon system

## Summary

A carried weapon can now be levelled from 1 to `max_level = 4` by level-up
offers. The level is **run state**, not content: it lives in
`Inventory.weapon_levels` keyed by the weapon's stable `id`, so the shared
`.tres` never carries a per-run value. The level step is **additive on the
base stat** and applies **before** the player's global multipliers (level 4 =
×1.75 damage, ×1.15 cadence). A level is offered as a new `Offer` kind,
`weapon_upgrade`, decorated with the numbers of the level it targets. Acquisitions
and upgrades share **one weapon row per panel** (A2); their candidates compete
by weight inside that row, and at `weapon_upgrade_weight = 1.4` the weapon share
of the panel is independent of the loadout.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 stable |
| **Domain** | Gameplay / progression |
| **Layer** | Systems |
| **Knowledge Risk** | LOW — no post-cutoff engine API; plain `Resource`, `Dictionary` and typed GDScript |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `design/gdd/weapons.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Full suite green (140 tests / 21 suites); retained screenshot of a level offer and the HUD level readout; harness run (`tools/weapon_upgrade_sim.gd`) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | `design/gdd/weapons.md` §3.1/§3.8/§4.13/§7/§8 (amended for levels, A7) |
| **Enables** | Lot 2 — weapon evolutions, which need a level axis to hang on |
| **Blocks** | None |
| **Ordering Note** | The GDD amendment lands in the same changeset as this ADR, before the lot 2 work begins |

## Context

### Problem Statement

Once the three weapon slots are full, a level-up panel can only offer stats,
equipment and rerolls. Stats hit their ceilings, and the run's power curve
flattens even though a weapon sits at a fixed power level all run. The
roguelite plan (`prompts/ameliorations-roguelite.md`) asks for weapon levels as
lot 1: a carried weapon must be able to grow, and the offer pool must stay
meaningful once the loadout is complete.

### Current State

- `WeaponData` is a shared `Resource`: every run that loads
  `data/weapons/dague.tres` gets the same object (`load()` caches resources).
- `Inventory` owns the three slots and already keys duplicate checks by
  `WeaponData.id`.
- `Stats.weapon_damage`, `weapon_attacks_per_second` and `weapon_range` read the
  base stats and multiply by the player's global multipliers.
- `_build_offers` builds stat, equipment and weapon rows; a carried weapon can
  never reappear because `has_weapon` filters it out.
- The HUD shows each weapon's name and cooldown but not a level.

### Constraints

- The `.tres` files stay shared; writing a level onto `WeaponData` would leak
  across runs and across scene reloads.
- Gameplay values are data-driven: the level count and steps belong to
  `WeaponData`, not to a script constant.
- Every public method must stay unit-testable without a scene tree.
- A2 fixes the panel shape: `max_level = 4`, and never more than one weapon
  offer per panel.
- A1 fixes the cadence step at +5 % per level.
- The localization standard requires new player-facing strings to go through
  `data/localization/strings.csv` with a French fallback (A6).

### Requirements

- A carried weapon below its max level is offered as an upgrade.
- A weapon at max level is never offered for upgrade.
- The upgrade shows the level it targets and the effective numbers at that
  level.
- A level-up must not reset the weapon's cooldown or reroll the run.
- A new weapon enters at level 1; replacing a weapon forgets the old level.
- One weapon row per panel, acquisition or upgrade (A2).
- The upgrade weight is chosen from measurement on the real offer path.

## Decision

### 1. The level is run state in `Inventory`, keyed by weapon id

`Inventory.weapon_levels: Dictionary` maps `WeaponData.id -> int`. It is cleared
by `setup_starting()`, reset to 1 by `add_weapon` and `replace_weapon`, and read
through `level_of(weapon)` which clamps anything below 1 to 1. `upgrade_weapon`
returns `false` for a weapon not carried or already at `max_level`.

`WeaponData` carries the **rules**, not the state: `max_level` (default 4) and
three steps, `level_damage_step = 0.25`, `level_cadence_step = 0.05`,
`level_range_step = 0.05`.

### 2. The level step is additive, and applies before the global multipliers

`Stats.level_*_multiplier(weapon, level)` returns
`1.0 + (clamp(level, 1, max) - 1) * step`. The effective stat is:

```text
damage      = weapon.damage              * level_damage_multiplier  * damage_mult
cadence     = weapon.attacks_per_second  * level_cadence_multiplier * attack_speed_mult
range       = weapon.range_px            * level_range_multiplier   * range_mult
```

Additive keeps the level-4 budget at ×1.75 damage and ×1.15 cadence, inside the
reference DPS table (§4.14) and the safe ranges of the tuning knobs. A
multiplicative step (`1.25^3 = 1.95`) would push every weapon past the tuned
ceiling at max level.

Every combat entry point takes the level **explicitly**: `DamageCalc.roll(stats,
weapon, rng, level)`, `weapon_damage(weapon, level)`, etc. Defaults to 1 keep
legacy call sites compiling, and a shot already in flight keeps the level it was
fired at (GDD E19). `WeaponSystem` resolves the level once per weapon per step
and passes it to the projectile, the swing, the chain and the censer detonation.

### 3. `Offer.for_weapon_upgrade` is a distinct kind

```text
Offer.kind          = "weapon_upgrade"
Offer.weapon        = carried WeaponData
Offer.target_level  = next level (clamped to at least 1)
Offer.title         = "↑ <name> +1 (niv. N)"        via Loc.format
Offer.description   = "niv. N-1 → N" + the mechanism line + numbers at level N
```

The numbers are decorated by `_write_weapon_description(offer, weapon, level,
is_upgrade)`, which reuses `_weapon_numbers` so the upgrade shows the same
mechanic-specific figures as an acquisition, evaluated at the target level.

### 4. One weapon row per panel (A2)

`_build_offers` appends **all** acquisition candidates (capped at
`free_weapon_slots()`, Fisher-Yates with the run RNG) and **all** upgrade
candidates (one per carried weapon below max), each with its own weight. The
weighted draw keeps them all; when it picks one, `_pick_weighted` removes every
other weapon row from the remaining pool. So the panel shows one weapon row at
most, while the row's weight is the sum of the candidates' weights — which is
what F13 models.

The acquisition cap is load-bearing: without it, the row's share would scale
with the size of the catalogue. With it, and with both weights equal to 1.4,
`W_weapon` is exactly `3 × 1.4 = 4.2` for any loadout until a weapon maxes out.

The boss-loot override (`boss_loot_weapon_weight = 3.0`) replaces **both**
weights, so a boss panel weights a level exactly like a new weapon.

### 5. The upgrade weight is chosen by simulation

`tools/weapon_upgrade_sim.gd` plays 200 runs × 15 panels × 2 policies (random,
greedy) per candidate weight on the real `_build_offers` / `_apply_offer` path.
At 1.4:

| Policy | Acquisitions | Levels gained | Weapon rows / 15 | Dead panels | Avg level | All max |
|---|---|---|---|---|---|---|
| random | 1.40 | 2.10 | 10.40 | 4.59 | 1.87 | 2.0 % |
| greedy | 1.99 | 7.23 | 9.22 | 5.61 | 3.42 | 13.5 % |

`measure_panels.gd` models the same loop analytically and agrees on the share.
1.4 wins over 1.2 because it makes the weapon share loadout-independent
(§3.8, F13) and gives greedy players 7.2 levels over a run instead of 6.9 —
enough for a focused build to approach max without making all-max the norm.

### Architecture Diagram

```text
WeaponData (.tres, shared)          Inventory (per run)
├─ max_level = 4                    ├─ weapons: Array[WeaponData]
├─ level_damage_step = 0.25         └─ weapon_levels: Dictionary[id -> int]
├─ level_cadence_step = 0.05              ▲
└─ level_range_step = 0.05                │ level_of / upgrade_weapon
                                          │
main.gd ── _build_offers ──► Offer ("weapon_upgrade", target_level)
   │                              │
   │ _apply_offer                └─ _decorate_offer → numbers at target level
   ▼
_weapon_system.refresh()      Stats.level_*_multiplier → DamageCalc.roll
```

### Key Interfaces

```gdscript
# src/classes/inventory.gd
func level_of(weapon: WeaponData) -> int
func can_upgrade_weapon(weapon: WeaponData) -> bool
func upgrade_weapon(weapon: WeaponData) -> bool

# src/classes/stats.gd
static func level_damage_multiplier(weapon: WeaponData, level: int = 1) -> float
static func level_cadence_multiplier(weapon: WeaponData, level: int = 1) -> float
static func level_range_multiplier(weapon: WeaponData, level: int = 1) -> float
func weapon_damage(weapon: WeaponData, level: int = 1) -> float
func weapon_attacks_per_second(weapon: WeaponData, level: int = 1) -> float
func weapon_range(weapon: WeaponData, level: int = 1) -> float

# src/classes/damage_calc.gd
static func roll(stats: Stats, weapon: WeaponData, rng: RandomNumberGenerator, level: int = 1) -> Dictionary

# src/classes/offer.gd
static func for_weapon_upgrade(carried: WeaponData, level: int) -> Offer

# src/systems/weapon_system.gd
func refresh() -> void          # passes inventory.level_of(weapon) to the view and the orbit
func step(delta: float) -> void # resolves each weapon's level once, then passes it down
```

### Implementation Guidelines

- Read the level **once per step** in `WeaponSystem.step()` and pass it down;
  do not re-read the inventory mid-resolution.
- Thread the level as an explicit parameter through `_swing`, `_fire_projectile`,
  `_throw_censer`, `_resolve_chain` and the pending-hit dictionary; a default of
  1 keeps a call site that has no level (tests, debug tools) compiling.
- `_apply_offer("weapon_upgrade")` calls `_upgrade_weapon`, which returns early
  when `upgrade_weapon` refuses, then calls `_weapon_system.refresh()`. Refresh
  rebuilds views but does not touch `_cooldowns`, so a level-up never grants a
  free attack.
- New strings go through `Loc.format` and `data/localization/strings.csv`; the
  fallback is the French literal, so a missing key never shows a raw key.
- Update `_refresh_hud` and `Hud.update_weapons` together; the HUD reads
  `weapon_levels` through `main._weapon_levels()`.

## Alternatives Considered

### Alternative 1: Store the level on `WeaponData`

- **Description**: add `var level: int = 1` to the resource and mutate it.
- **Pros**: no dictionary, no lookup.
- **Cons**: `load()` caches resources, so the level would leak across runs and
  across scene reloads; the `.tres` would stop being content.
- **Estimated Effort**: low.
- **Rejection Reason**: violates the data/content split the project enforces.

### Alternative 2: Multiplicative level step

- **Description**: multiply damage by `1.25` per level (`1.25^3 = 1.95`).
- **Pros**: levels feel sharper at the top end.
- **Cons**: pushes every weapon past the tuned reference DPS at level 4 and
  compounds with `damage_mult`; the tuning table would need a full rebalance.
- **Estimated Effort**: low.
- **Rejection Reason**: breaks the §4.14 reference budget; additive keeps the
  level-4 ceiling at ×1.75.

### Alternative 3: Two weapon rows per panel

- **Description**: show an acquisition and an upgrade side by side.
- **Pros**: the player sees both axes at once.
- **Cons**: A2 caps the panel at one weapon offer, so a full loadout would show
  three upgrade rows plus two other offers; the panel becomes a weapon menu.
- **Estimated Effort**: low.
- **Rejection Reason**: rejected by the design decision A2, and the extra rows
  crowd out stats and equipment.

### Alternative 4: Levels bought with a separate currency

- **Description**: weapon XP or upgrade shards spent at a shop.
- **Pros**: decouples levelling from level-up panels.
- **Cons**: adds a system (currency, UI, economy) outside lot 1's scope and
  delays the answer to "the panel is flat once slots are full".
- **Estimated Effort**: high.
- **Rejection Reason**: over-scoped; the offer loop already has the decision
  point.

## Consequences

### Positive

- The level-up panel keeps a meaningful weapon choice for the whole run.
- The shared `.tres` stays content; every run starts from level 1.
- The HUD shows the level, so the progression is legible.
- The offer shows the level it targets, so the choice is informed.
- The weight decision is backed by 6,000 simulated runs on the real code path.

### Negative

- A second offer kind to decorate and localize.
- Combat call sites gained a level parameter; the default hides it, so a new
  call site can silently fire at level 1. Mitigated by the weapon system
  resolving the level once per step and by the regression suite.
- The panel shows at most one weapon row, so an acquisition and a level cannot
  be compared side by side.

### Neutral

- `WeaponData.max_level` defaults to 4, so a new `.tres` is playable without
  setting it; the ten shipped `.tres` set it explicitly.
- The upgrade row keeps the weapon's cooldown: `refresh()` rebuilds views but
  not cooldowns.

## Risks

- **A level leaks across runs** — prevented by `weapon_levels` living on
  `Inventory` and being cleared by `setup_starting`; covered by
  `test_new_run_clears_the_previous_levels`.
- **A shot in flight uses the new level** — prevented by snapshotting the level
  at fire time and storing it in the pending hit / projectile; covered by
  `test_damage_roll_uses_the_requested_level`.
- **The weapon row crowds out the panel** — bounded by the acquisition cap and
  by the 1.4 weight; measured at 69 % of panels in the random policy, with the
  other two rows still available.
- **A localized string shows a raw key** — mitigated by `Loc.text`'s fallback
  and by regenerating the `.translation` files in the same changeset.
- **The free-slot cap is dropped later** — the harness and
  `test_panel_carries_at_most_one_weapon_row` would not catch a catalogue-share
  drift alone; the F13 invariance is the guard.

## GDD Requirements Addressed

- `design/gdd/weapons.md` §3.1 — a carried weapon is re-offered as a level, not
  as a duplicate.
- §3.8 — level offers, one weapon row per panel (A2), acquisition cap, reroll
  and boss-loot behaviour.
- §4.13 (F13) — upgrade terms in the offer probability and the loadout
  invariance.
- §5 — E21–E25 (max level, single row, cooldown, replacement, new run).
- §7 — `RunConfig.weapon_upgrade_weight` with its safe range.
- §8 — AC12–AC16.

## Performance Implications

- **CPU**: three multiplications per weapon per step plus one dictionary lookup;
  no allocation. The harness plays 6,000 runs in a few seconds headless.
- **Memory**: one `int` per carried weapon in `Inventory.weapon_levels`.
- **Rendering**: none; the HUD label gains a localized suffix.

## Migration Plan

- No save system exists yet, so there is nothing to migrate. If one lands, a
  missing `weapon_levels` entry reads as level 1 through `level_of`.
- Old `.tres` files load unchanged: `max_level` defaults to 4 and the steps to
  their shipped values.
- Rollback: revert the lot 1 commit. Levels disappear; weapons read at level 1
  through the default parameters, so no other system needs a change.

## Validation Criteria

- `tests/unit/weapon_levels_test.gd` — 12 tests green.
- `tests/integration/weapon_upgrade_offers_test.gd` — 8 tests green.
- Full suite — 140 tests / 21 suites, exit 0.
- `tools/weapon_upgrade_sim.gd` — the table in §5 reproduced by a fresh run.
- Retained screenshot `production/qa/evidence/lot1-weapon-levels.png` — an
  upgrade offer next to a new-weapon offer, and the HUD level readout.

## Related

- `design/gdd/weapons.md`
- `prompts/ameliorations-roguelite.md` (lot 1, amendments A1/A2/A6/A7)
- `tests/unit/weapon_levels_test.gd`
- `tests/integration/weapon_upgrade_offers_test.gd`
- `tools/weapon_upgrade_sim.gd`, `tools/measure_panels.gd`
