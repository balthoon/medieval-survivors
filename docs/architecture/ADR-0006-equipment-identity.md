# ADR-0006: Equipment identity — passives and two-piece sets

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**

## Date

2026-11-10

## Last Verified

2026-11-10

## Decision Makers

- `game-designer` — what a set and a passive promise the player
- `systems-designer` — additivity, thresholds, and the price of the helmet pivot
- `lead-programmer` — where set and passive state lives, recompute path
- `godot-gdscript-specialist` — typed resources, `StringName` tokens, null-safe lookups

## Summary

Equipment was twelve flat stat sticks; lot 3 gives each piece an **identity**:
an optional passive rule (`passive_id` + `passive_value`) and an optional
membership in a two-piece set (`set_id`, resolved through `Catalogue.sets`).
Sets and passives are **derived state, never stored**: every equipment change
rebuilds `Stats` from the class base and re-applies pieces, completed sets once,
and the summed passives, so a bonus can never stack with itself. The rage
passive multiplies weapon damage below a `RunConfig` health threshold; the
amulet passive heals on every level gained.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 stable |
| **Domain** | Gameplay / progression |
| **Layer** | Feature |
| **Knowledge Risk** | LOW — plain `Resource`, `Dictionary`, `StringName` and typed GDScript; no post-cutoff engine API |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `design/gdd/equipment.md`, `design/gdd/weapons.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Full suite green in `fr` and `--language en` (165 tests / 23 suites); retained screenshot of the HUD equipment column, an offer carrying a set line, and the level-up heal title |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | `design/gdd/equipment.md` (data model, formulas, edge cases) |
| **Enables** | Lot 2 — weapon evolutions reuse the `passive_id`/`passive_value` pair; lot 4 — the save format must serialise run equipment |
| **Blocks** | None |
| **Ordering Note** | Delivered before lot 2, per the avenant; the equipment GDD and this ADR land in the same changeset as the code |

## Context

### Problem Statement

Equipment choices were interchangeable: every piece was one additive stat, so a
build was only the sum of its drops. The roguelite plan's lot 3 asks for
**equipment identity** — pieces the player can name a strategy after, and
decisions between pieces that compete for the same slot.

### Current State

- `EquipmentData` carries `id`, `display_name`, `slot`, `rarity`, `stat`,
  `amount`, `description`.
- `Inventory.apply_to` pushes each worn piece into `Stats._add_stat`; percent
  stats add to a multiplier, so two +10 % pieces give ×1.20.
- `Stats` is rebuilt from `_base_stats.clone()` whenever an upgrade or a piece
  changes; nothing is accumulated across rebuilds.
- The HUD lists one line per body slot with the piece's effect text.
- `_gain_equipment` equips immediately and recomputes; offers are decorated with
  the piece's effect and what it would replace.

### Constraints

- Content resources are shared by every run (`load()` caches them): a `.tres`
  must never carry run state.
- Gameplay values stay data-driven: set amounts and passive magnitudes live in
  `.tres`, the rage threshold in `RunConfig`.
- Stats remain additive, not compounding, and crit stays clamped to
  `Stats.CRIT_CAP = 0.75` (ADR-0005 and the existing stats rules are untouched).
- Every new rule must be unit-testable without a scene tree.
- New player-facing strings go through `data/localization/strings.csv` (A6).
- `modes.workflow: full` requires this ADR and the equipment GDD's 8 sections.

### Requirements

- A piece may carry a passive, belong to a set, both, or neither.
- A completed set grants its bonus **exactly once** per rebuild and stops
  granting it the moment a piece leaves the slot.
- A passive disappears with the piece that carries it, in the same recompute.
- No new input, screen, or button: identity must be visible in the existing HUD
  and offer text.

## Decision

### Data model

`EquipmentData` gains three pure-data fields:

| Field | Type | Default | Meaning |
|---|---|---|---|
| `passive_id` | `StringName` | `&""` | Stable token; empty means no passive. Known: `rage`, `level_up_heal`. |
| `passive_value` | `float` | `0.0` | Fraction for `rage`, hit points for `level_up_heal`. |
| `set_id` | `String` | `""` | Stable id of the set; empty means none. |

A new `EquipmentSetData` `Resource` holds `id`, `display_name`,
`required_pieces` (2 in v1, valid range 2–6), `stat`, `amount`, `description`,
and formats its effect through `EquipmentData.stat_text` so a set reads exactly
like a piece.

`Catalogue` gains `sets: Array[EquipmentSetData]` and `set_by_id(id) -> EquipmentSetData`.

### Where the rules live

- `Inventory.count_set_pieces(set_id) -> int` counts worn pieces by `set_id`,
  across `Inventory.SLOTS`; an empty id counts nothing.
- `Inventory.is_set_complete(set_data) -> bool` compares that count with
  `maxi(required_pieces, 1)`; a null set is never complete.
- `Inventory.passive_total(passive_id) -> float` sums `passive_value` over worn
  pieces carrying that token.
- `Stats` gains `rage_bonus`, `rage_hp_threshold` (default 0.5), `hp_ratio`
  (default 1.0) and `level_up_heal`, plus `apply_set_bonus(set_data)` which
  funnels into the same `_add_stat` as a piece.
- `Stats.rage_multiplier()` returns `1 + rage_bonus` **only** while
  `rage_bonus > 0` and `hp_ratio < rage_hp_threshold`; it returns exactly 1.0
  at the threshold and above.

### Recompute contract

`Main._recompute_stats` is the single writer:

1. clone `_base_stats`;
2. `Inventory.apply_to(derived)` — pieces only;
3. `_apply_set_bonuses(derived)` — every set `is_set_complete` reports, once;
4. `derived.rage_bonus = _inventory.passive_total(&"rage")`;
5. `derived.rage_hp_threshold = _config.rage_hp_threshold`;
6. `derived.level_up_heal = _inventory.passive_total(&"level_up_heal")`;
7. `derived.hp_ratio = _player.hp / maxf(derived.max_hp, 0.001)`.

A set or passive is therefore **never stored** on the inventory or the
resource: it is a function of what is worn right now. `_process` refreshes
`hp_ratio` every frame so the rage multiplier reads a health fraction at most
one frame old at hit resolution.

`_check_level_up` pays `_player.heal(stats.level_up_heal)` after consuming the
level and before opening the panel, so the bar behind the panel is already
correct.

### Damage order

`Stats.weapon_damage` computes:

```
damage = base × (1 + level_step × (level - 1)) × damage_mult × rage_multiplier()
```

The rage multiplier is last and conditional. It composes with global damage
rather than replacing it (GDD equipment F3).

### Readability

- An equipment offer's description appends the passive line, then a set line:
  progress (`Ensemble Duelliste (1/2)`) or completion
  (`Ensemble Duelliste complet : +12 % critique`).
- The set line counts the piece being offered as worn **after** the swap, and
  does not count a duplicate when the offered piece replaces a same-set piece
  in that slot.
- The HUD keeps one set summary line above the equipment rows
  (`Ensembles : ◆ Colosse 2/2 · Coureur des bois 1/2`), built by `Main` from the
  catalogue and the worn pieces. It is hidden while no worn piece belongs to a
  set, so early runs are not cluttered. A worn piece of a complete set is also
  prefixed with `◆`.
- The rage state is written on the carrying piece's row (`· ACTIF`), never shown
  by colour alone; the marker follows `Stats.rage_multiplier() > 1.0`.
- The level-up panel title names the health actually restored
  (`Montée de niveau · Soin +8 PV`), measured around the heal, so a full-health
  level-up reads `+0` instead of the amulet's nominal 8.
- All new strings go through CSV keys `equipment.passive_rage`,
  `equipment.passive_level_heal`, `equipment.set_progress`,
  `equipment.set_complete`, `equipment.set_summary`,
  `equipment.rage_active` and `hud.level_up_heal_title`; `stat_text` remains the
  shared French-fallback formatter for raw stat values.

### Key interfaces

```gdscript
class EquipmentSetData extends Resource:
    @export var id: String
    @export var display_name: String
    @export var required_pieces: int = 2
    @export var stat: String
    @export var amount: float
    @export var description: String
    func bonus_text() -> String

# Inventory
func count_set_pieces(set_id: String) -> int
func is_set_complete(set_data: EquipmentSetData) -> bool
func passive_total(passive_id: StringName) -> float

# Stats
func apply_set_bonus(set_data: EquipmentSetData) -> void
func rage_multiplier() -> float

# Catalogue
func set_by_id(id: String) -> EquipmentSetData
```

### Implementation guidelines

- The recompute path **must** rebuild from the base every time; a set bonus must
  never be added to a `Stats` that already carries it.
- `Stats` **must never** read `Inventory` or the catalogue; it receives values.
- A passive token **must** be compared as a `StringName` (`&"rage"`), never as a
  translated display name.
- The rage threshold **must** come from `RunConfig`, never from the piece.
- An unknown `set_id` or `passive_id` **must** grant nothing (and is rejected by
  the catalogue integrity tests, not at runtime).
- Adding a set **must not** require a code change: only a new `.tres` and its
  registration in `Catalogue.sets`.

## Alternatives Considered

### Alternative 1: Store equipped-set bonuses on `Inventory` when completed

- **Description**: `Inventory` keeps a `completed_sets` array and adds the bonus
  once when the last piece lands; it removes it when a piece leaves.
- **Pros**: No recompute; the set is only applied on the transition.
- **Cons**: Two sources of truth (bonus stored and pieces worn) that can drift
  on replacement, reload, or a missed signal; replacement requires a precise
  inverse operation.
- **Estimated Effort**: Similar code volume, more failure modes.
- **Rejection Reason**: The rebuild-from-base path already exists and makes
  double counting structurally impossible.

### Alternative 2: List member pieces inside `EquipmentSetData`

- **Description**: The set resource carries `pieces: Array[EquipmentData]` and
  completion checks that all listed pieces are worn.
- **Pros**: The set is self-describing in one file.
- **Cons**: Two references to the same relationship that must stay in sync; a
  duplicated or missing `.tres` reference is invisible until play.
- **Estimated Effort**: Lower initially, higher maintenance.
- **Rejection Reason**: One direction (`piece.set_id`) cannot desynchronise;
  catalog tests can assert every set has enough pieces.

### Alternative 3: One script per passive, attached to the resource

- **Description**: A `PassiveEffect` resource with a virtual `apply()`.
- **Pros**: Arbitrary passive logic without touching `Stats`.
- **Cons**: Behaviour lives in shared content resources; order and stacking
  become implicit; harder to unit test and to serialise in a save.
- **Estimated Effort**: Higher (new class hierarchy).
- **Rejection Reason**: Two passives with one numeric magnitude each do not
  justify a polymorphic effect system; the token + value pair is enough and
  stays data-driven. A third passive with real logic is the trigger to revisit.

## Consequences

### Positive

- A build is now nameable and visible: set completion is a goal the offer pool
  can advance.
- The helmet slot holds a real decision: Duelliste needs the ancient helmet,
  Colosse needs the iron one.
- Passives add conditional play (low-health rage, level-up sustain) without new
  UI or input.
- Content scales by data: a new set is a `.tres` plus a catalogue row.

### Negative

- `Stats` gains four fields that only two passives use; a future passive may
  need a shape this model cannot express.
- The offer decoration path grows a set line that must reason about the slot it
  would replace.
- Set balance is coupled to piece balance: a set's price includes the pieces
  the player gives up.

### Neutral

- The equipment GDD becomes the contract; `equipment.md` replaces scattered
  notes as the reference.
- Set ids are stable ASCII, like weapon ids; display names remain localisable.

## Risks

- **Double counting after a later refactor.** Mitigation: the spawn point is a
  single `_recompute_stats`; integration tests rebuild twice and assert no drift.
- **Rage value read one frame late.** Mitigation: `hp_ratio` is refreshed in
  `_process`; the GDD's hit-resolution rule is explicit, and the multiplier is
  read at damage resolution, not at swing start.
- **Set line lies about completion.** Mitigation: `_set_line_for` counts the
  offered piece in the slot it would occupy; tests cover progress, completion,
  and same-set replacement.
- **Localisation drift.** Mitigation: four CSV keys with English values, tested
  under `--language en`.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `equipment.md` §3.1–3.4 | Piece passives and two-piece sets over `EquipmentData`/`EquipmentSetData` | Adds the three fields, the resource and the catalogue list |
| `equipment.md` §3.5 | Set and passive bonuses applied once per rebuild, never accumulated | Rebuild-from-base contract plus `_apply_set_bonuses` |
| `equipment.md` §4.2–4.5 | Rage multiplier, additive stat application, set counting, level-up heal | `rage_multiplier`, `_add_stat`, `count_set_pieces`, `level_up_heal` |
| `equipment.md` §5 (E1–E15) | Threshold crossing, replacement, unknown tokens, crit cap, no retroactive heal | Covered by unit and integration suites and the catalogue integrity tests |
| `equipment.md` §3.6 | Offer and HUD readability | Passive line, set line, `◆` marker |
| `weapons.md` §4.13 / ADR-0005 | Damage order: level before global multipliers | Rage composes last, after level and `damage_mult` |

## Performance Implications

- **CPU**: One loop over six slots plus three sets per equipment change; one
  division per frame for `hp_ratio`. Negligible.
- **Memory**: Three fields per piece and one small resource per set.
- **Load Time**: Three extra `.tres` loads at catalogue load.
- **Network**: Not applicable.

## Migration Plan

1. Extend `EquipmentData`, add `EquipmentSetData`, register `Catalogue.sets`.
2. Extend `Inventory` and `Stats`; refresh `hp_ratio` in `_process`.
3. Wire the recompute, the level-up heal, offer decoration and HUD marker.
4. Tag the six set pieces and the two passive pieces in `data/equipment/`.
5. Add the three set `.tres` files and localisation keys.
6. Unit, integration and catalogue tests; screenshots.

**Rollback plan**: remove the three fields' effects from the recompute path and
the offer/HUD lines; the `.tres` fields then read as unused data and no save
format depends on them yet (lot 4 is not started).

## Validation Criteria

- Full suite green in French and English (165 tests / 23 suites).
- Duelliste grants +12 % crit once with both pieces, zero after replacing one.
- Colosse grants +30 HP only with the iron helmet and the mail chest; the
  ancient helmet breaks it.
- Rage is exactly ×1.15 below the threshold, exactly ×1.00 at it.
- The amulet heals 8 HP per level, capped at max HP, never retroactively.
- Retained screenshot shows the set summary with `◆`, the rage `ACTIF` marker,
  a set line in an offer, and the level-up heal title.

## Related

- `design/gdd/equipment.md` — the contract this ADR implements
- `design/gdd/weapons.md` — damage order and level rules (ADR-0005)
- `docs/architecture/ADR-0005-weapon-levels.md` — per-run state lives in `Inventory`
- `src/data/equipment_set_data.gd`, `src/data/equipment_data.gd`,
  `src/classes/inventory.gd`, `src/classes/stats.gd`, `src/main.gd`,
  `src/ui/hud.gd`
