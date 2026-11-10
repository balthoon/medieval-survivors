# ADR-0003: Character animation without moving gameplay state

## Status

Proposed

## Date

2026-11-10

## Last Verified

2026-11-10

## Decision Makers

- `technical-director` — animation architecture, game-state integrity
- `technical-artist` — animation feel and drawing implementation
- `gameplay-programmer` — player and enemy wiring

## Summary

Character motion is drawn, never simulated: walk bounce and attack lunge are
offsets applied inside the player's `_draw` with `draw_set_transform`, and the
enemy waddle translates a visual child node, so the actor's `position` remains
the single source of truth for collisions, the spatial hash and weapon
targeting. Death feedback is a short-lived `DeathFade` node created by
`EnemyManager.remove_dead`; it is visual-only and never enters the enemy list or
the hash. Decor stays static by decision.

## Engine Compatibility

- **Engine**: Godot 4.7.2 stable, GDScript.
- **APIs used**: `CanvasItem.draw_set_transform`, `CanvasItem.queue_redraw`,
  `Node._process`, `Node2D.position` on a visual child, `Node2D.scale`,
  `CanvasItem.modulate`.
- **APIs deliberately avoided**: `AnimationPlayer`, `Tween` nodes per actor,
  `Skeleton2D`, shaders. The cast is procedural geometry rebuilt in `_draw`;
  there is no sprite sheet or rig to animate.
- All APIs used predate the pinned engine and are stable in 4.x.

## ADR Dependencies

- `ADR-0002-obstacle-collisions.md` — collision reads `position`; this ADR
  guarantees animation never writes it.
- `ADR-0001-test-framework.md` — gdUnit4 suites validate the timers and wiring.

## Context

### Problem Statement

The direction-A storybook renderer shipped looking static: the player breathes
but does not react to walking or attacking, enemies are frozen between hit
flashes, and a kill removes the body in the same frame. The user asked for
character animations while keeping the procedural, physics-free architecture.

### Current State

- `Player._draw` passes `InkStyle.breathe(_anim_time)` as the bob.
- `Enemy._draw` repaints only on spawn and around a hit flash; the comment said
  "enemies never animate".
- `EnemyManager.remove_dead` calls `enemy.queue_free()` immediately after
  dropping XP.
- Movement, prop collisions, the spatial hash and every weapon query read
  `position` directly.

### Constraints

- A visual offset written into `position` would move the hitbox, the hash entry
  and the weapon attach point. That is not acceptable.
- No physics server, no per-actor Tween or AnimationPlayer node.
- The game must remain deterministic and headless-testable.
- Decor animation (tree sway) is explicitly out of scope: performance.

### Requirements

- Walking and attacking must read on the knight.
- Living enemies must move subtly while walking.
- A kill must squash and fade the body without delaying loot or target removal.
- `position`, the hash and all collision results must be unchanged by animation.

## Decision

### 1. Animation never moves the actor

The player computes its bob and lunge from timers and applies them with
`draw_set_transform(offset)` around the `ActorArt` call, then resets with
`draw_set_transform(Vector2.ZERO)`. An enemy's painted body is a `Body` child
node; the waddle writes that child's `position`, never the enemy's own. In both
cases the actor's `position` is never written.

### 2. Player walk and lunge

- `step_movement` records whether the frame carried input.
- `step` advances `_walk_phase` only while walking, at `WALK_PHASE_HZ = 8.0`;
  the bounce is the rectified sine, peak `WALK_BOUNCE = 2.5` px.
- `WeaponSystem` emits `attack_started(angle)` once per shot that actually
  fires. `main.gd` connects it to `Player.play_attack_lunge(angle)`.
- The lunge lasts `LUNGE_DURATION = 0.12` s and displaces the drawing by
  `LUNGE_DISTANCE = 4.0` px at the start, eased out quadratically.

### 3. Enemy waddle

- Each enemy paints its body once, in a `Body` child, then only translates that
  child. `step_visual` advances `_anim_time` and writes `Body.position` with a
  sideways sway (`WADDLE_HZ = 7`, `WADDLE_SWAY = 1.5` px) and a vertical bob
  (`WADDLE_BOB_HZ = 8`, `WADDLE_BOB = 1.5` px). The body repaints only when the
  hit flash starts and ends — never per frame.
- The phase is derived once from the spawn position (`PHASE_X = 0.05`,
  `PHASE_Y = 0.07`), never from RNG, so a run animates identically every time.
- While the enemy winds up a slam, motion is scaled by
  `TELEGRAPH_MOTION_SCALE = 0.3` so the telegraph still reads as rooted.
- The painted body itself is a baked texture; see
  `ADR-0004-actor-art-texture-cache.md`. This ADR owns the motion model, that
  one owns how the pixels reach the screen.

### 4. Death is a visual-only node

`EnemyManager.remove_dead` creates a `DeathFade` at the dead enemy's position
under the same container, then frees the enemy exactly as before. `DeathFade`
is a plain `Node2D` that squashes to `END_SCALE = (1.35, 0.25)`, fades its
modulate alpha to zero over `DURATION = 0.22` s and frees itself. It is not an
`Enemy`, so it cannot enter the hash, be targeted or be counted.

### 5. Decor stays static

Trees, rocks, bushes and the shrine do not animate. The prop collision field is
derived from static constants and must stay that way.

## Alternatives Considered

### Alternative 1: Animate `position` and offset collision by the same amount

Rejected. It would make the drawn body and the gameplay body agree, but the
spatial hash, prop slide and weapon cones would all have to consume the same
offset every frame, multiplying the places animation can desync from gameplay.

### Alternative 2: Keep the enemy alive for the death animation

Rejected. A dead enemy retained for 0.22 s would stay in `enemies` and the hash
unless every query gained a dying filter, and loot timing would move. A
separate visual node keeps the lifecycle untouched.

### Alternative 3: `AnimationPlayer` or per-actor `Tween`

Rejected. The cast is rebuilt geometry, not a sprite or rig; an animation track
would still have to drive a draw offset. A timer plus a sine is cheaper and
testable headlessly.

### Alternative 4: Leave enemies static

Rejected after the user's direction-A feedback: a field where nothing moves
reads as a mockup, not a game.

## Consequences

### Positive

- Gameplay state (position, hash, collision, targeting) is provably untouched.
- The animation is deterministic and unit-testable through timers.
- Death feedback does not delay XP, loot or target removal.
- No new node per living actor and no shader or rig dependency.

### Negative

- Each living enemy now carries one extra child node (its `Body`), and that
  child's transform is written every frame. Both are cheap, but they exist.
- The amplitudes are deliberately small; on a busy screen they may read too
  subtly and need a playtest tuning pass.
- `WeaponSystem` gains a signal whose only listener is the player, a small
  coupling that must stay optional for tool scenes.

### Neutral

- `DeathFade` nodes exist for 0.22 s after each kill; their count is bounded by
  the kill rate and they never enter any gameplay collection.

## Risks

- **The first waddle implementation repainted every living enemy every frame** —
  measured at 60 → 26 FPS in wave 1 on the Intel UHD test machine, and worst in
  the boss wave, where the crowd is largest. Resolved in two steps: the body
  became a translated child, and `ArtCache` (ADR-0004) bakes the creature art
  into a texture so the body itself is one draw call. A boss-wave crowd of 42
  plus the boss now holds 60 FPS; re-measure with `tools/perf_boss_wave.gd` if
  the art or the wave tuning changes.
- **A visual offset could be mistaken for gameplay displacement** — mitigated by
  the draw-only rule and by tests asserting `position` is unchanged by walking,
  lunging and `step_visual`.
- **The death fade could be spawned for an enemy without data** — guarded by the
  `enemy.data != null` and parent checks in `remove_dead`.
- **The lunge signal may be missed in tool scenes** — the connection is made in
  `main.gd` only; tests that drive `Player` directly call `play_attack_lunge`.
- **Animation tuning is data-adjacent** — the constants live in the scripts, as
  visual feel rather than gameplay balance; they are not in `RunConfig`.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `enemy-behaviors.md` | Enemies move toward the player and never collide with each other | Animation is draw-only; movement, the spatial hash and pass-through are unchanged |
| `weapons.md` | A weapon fires on its own cadence and resolves damage at the impact frame | `attack_started` is emitted only when a shot actually fires; damage timing is untouched |
| `game-concept.md` | Storybook direction A is the shipped look | The cast now has motion while keeping the same geometry and palette |

The animation requirement itself comes from the user's direction-A feedback and
the lot-2 request; it is not yet recorded in a GDD. `game-designer` should
capture it via `/propagate-design-change` if it becomes a pinned requirement.

## Performance Implications

- **CPU**: one child transform write per living enemy per frame, and the
  player's existing per-frame redraw. Measured on the Intel UHD test machine:
  an empty arena holds 60 FPS at ~5,200 draw calls; a wave-5 crowd of 42 plus
  the boss also holds 60 FPS once the bodies are baked textures (ADR-0004).
- **Memory**: one `Body` node per living enemy, no per-frame allocation;
  `DeathFade` allocates one small node per kill and frees it 0.22 s later.
- **Load Time**: none; the art bake happens in the background during the first
  wave banner.
- **Network**: none.

## Migration Plan

Additive; no data or scene migration.

1. Add the walk/lunge timers and the draw transform to `Player`.
2. Add the waddle timers and the draw transform to `Enemy`.
3. Add `WeaponSystem.attack_started` and connect it in `main.gd`.
4. Add `DeathFade` and create it from `EnemyManager.remove_dead`.
5. Add the unit and integration suites from Validation Criteria.

**Rollback plan**: remove the draw transforms and the `DeathFade` creation; the
game returns to the static cast with no gameplay change to undo.

## Validation Criteria

- Unit tests cover the walk timer, the lunge timer, the DeathFade curve and the
  enemy animation time; all assert that `position` is unchanged.
- Integration tests prove the main scene wires `attack_started` to the player
  and that `remove_dead` creates the fade while keeping the XP drop.
- Retained screenshots: `production/qa/evidence/w2-anim-walk.png`,
  `w2-anim-lunge.png`, `w2-anim-death.png` and the zoomed comparison
  `w2-anim-detail.png`.
- The full suite is green (`commands.test` exits 0).

## Related

- `docs/architecture/ADR-0002-obstacle-collisions.md` — collision reads
  `position`; this ADR keeps animation out of it.
- `docs/architecture/ADR-0004-actor-art-texture-cache.md` — how the painted body
  reaches the screen without repainting its geometry.
- `docs/architecture/ADR-0001-test-framework.md` — the suites above.
- `docs/engine-reference/godot/VERSION.md` — pinned engine, post-cutoff warning.
