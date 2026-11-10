# ADR-0002: Obstacle collision for arena props without physics bodies

## Status

Proposed

> Acceptance belongs to the user or `technical-director` (see
> `.claude/docs/templates/architecture-decision-record.md`). This ADR was
> authored by `gameplay-programmer` for the direction-A shipping lot and is not
> yet accepted.

## Date

2026-11-10

## Last Verified

2026-11-10

## Decision Makers

`gameplay-programmer` (author of the implementation), `technical-director`
(review). Acceptance pending from the user.

## Summary

Medieval Survivors has no physics bodies at all: every actor is a plain `Node2D`
moved by direct position math, so the painted tree trunks, rocks, log and shrine
are not solid. This ADR records the decision to add a pure-GDScript obstacle
field (`ObstacleField`) that pushes actors out of static props and slides them
along prop edges, keeping the no-physics movement architecture intact.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 |
| **Domain** | Physics (collision) — implemented as pure geometry; the physics server is deliberately not used |
| **Layer** | Feature |
| **Knowledge Risk** | LOW — the decision uses only pre-cutoff core math (`Vector2`/`Vector3`/`Rect2`/`Array`) and `Node2D.position`; no physics server, no navigation, no post-cutoff API |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; source `src/art/pilot_arenas.gd`, `src/systems/enemy_manager.gd`, `src/main.gd`, `src/actors/player.gd` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Run the collision unit and integration suites headless; confirm a main-scene tree blocks the player; confirm the shipped direction-A screenshot shows solid props |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — the collision system is self-contained GDScript. Its test suites run under ADR-0001's gdUnit4 framework, but the implementation itself has no architectural prerequisite. |
| **Enables** | Future arena prop layouts: any arena drawn from `PilotArenas` constants gets collision for free. Keeps the no-physics movement architecture available to later epics. |
| **Blocks** | None named in this record |
| **Ordering Note** | The implementation must land in the same lot as the direction-A (`Édition enluminée`) visual delivery, so the shipped look and its collision match pixel-for-pixel. `PilotOverlay` is wired into the real scene in the same lot as related delivery, not as part of this decision. |

## Context

### Problem Statement

The arena props are drawn but not physical: tree trunks, rocks, the fallen log
and the shrine exist only as ink. A player or enemy walks straight through a
trunk. Direction A is now shipping, and props that do not exist physically break
the map's solidity.

### Current State

- No physics bodies at all. `Player` (`src/actors/player.gd`) and `Enemy`
  are plain `Node2D`s; `main.gd` moves the player via `step_movement` and
  `EnemyManager.step_all` moves enemies by distance math.
- `Player.step_movement` already clamps the player to `PLAY_RECT` inline (margin
  `RADIUS = 14.0`); there is no separate `clamp_inside()` method yet.
- `EnemyManager` has no `obstacles` property and applies no slide.
- `PilotArenas` (`src/art/pilot_arenas.gd`) holds the exact constants the
  storybook arena draws — `TREES` (9), `ROCKS` (12), `BUSHES` (2), the log drawn
  centred at `(278, 574)` with `46×10` half-extents, and the shrine at
  `(1168, 500)` — but has no `obstacle_field()` method yet.
- `design/gdd/enemy-behaviors.md` §Collisions states the deliberate rule that
  enemies do not collide with each other ("ils se traversent, y compris le
  boss"); only `Player.PLAY_RECT` stops scripted movement. This ADR preserves
  that rule: it adds only static-prop collision, never body-to-body collision.

### Constraints

- Determinism: tests are headless and must not depend on physics timing; enemy
  slide must be deterministic, with no RNG.
- No allocation per frame after the field is built: the field is immutable per
  run.
- Single source of truth: collision data and visual data must share one source
  (the `PilotArenas` constants), so art edits move collision with them.
- No `StaticBody2D`, no `CharacterBody2D`, no physics server, no navigation
  mesh — any of these would change the movement architecture this decision
  exists to preserve.

### Requirements

- Actors (player and enemies) must be pushed out of props and slide along them.
- Spawn positions inside props must be resolved.
- Tree canopies must never block (top-down readability); bushes are decorative;
  only trunks, rocks, the log and the shrine collide.
- Negligible CPU: 23 shapes per actor per frame, 3 passes, no allocation after
  construction.

## Decision

Add `src/systems/obstacle_field.gd`,
`class_name ObstacleField extends RefCounted`:

- An immutable-per-run set of circles (`Array[Vector3]`, x/y/radius) and
  rectangles (`Array[Rect2]`).
- `resolve(point, body_radius)`: a 3-pass push-out; closest-point resolution for
  rectangles; nearest-face exit when the point starts inside.
- `slide(from, to, body_radius)`: resolve the target, remove the normal
  component of the motion, and apply a deterministic tangential nudge for
  dead-on approaches.

The field is built once by `PilotArenas.obstacle_field()` from the exact
constants the storybook arena draws:

- **Tree trunks** — anchored at mid-trunk (`y + radius * 0.88`), collision
  radius `max(radius * 0.24, 5.0)`. The trunk polygon spans `radius * 0.45` to
  `radius * 1.30` below the base point, so `0.88` is its midpoint, and `0.24`
  is its widest half-width.
- **Rocks** — a circle of radius `radius * 0.85`, where `radius` is the rock's
  `spot.z` half-width. `0.85` keeps the collision circle just inside the drawn
  irregular polygon.
- **The log** — `Rect2(232.0, 564.0, 92.0, 20.0)` (the 92×20 rect whose visual
  is centred at `(278, 574)` with `46×10` half-extents).
- **The shrine** — a circle of radius 16 px at `(1168.0, 500.0)`.

Bushes are decorative and canopies never collide. The result is 22 circles
(9 trees + 12 rocks + 1 shrine) plus 1 rectangle (the log) = 23 shapes.

Wiring:

- `main.gd` owns one field, assigns it to `EnemyManager.obstacles`, slides the
  player after `step_movement`, and calls `player.clamp_inside()` afterwards —
  the arena border stays authoritative even after a slide pushes the player.
  When a prop overlaps the border, the clamp can push the body back into the
  prop (a wedge with no legal position); the player then keeps its last free
  position for that frame instead of crossing through the prop.
- `EnemyManager` resolves spawn positions inside props and applies `slide()`
  after each enemy's movement, before the spatial hash is rebuilt.
- Projectiles, pickups and weapons pass through props by design.

### Architecture Diagram

```text
PilotArenas (TREES / ROCKS / log / shrine constants)
        │  obstacle_field()  — built once per run
        ▼
ObstacleField (RefCounted, immutable)
   22 circles (Array[Vector3]) + 1 rect (Array[Rect2])
        │
        ├── main.gd ── player: slide() after step_movement → clamp_inside()
        │                 → revert to last free position if still inside a prop
        │
        └── EnemyManager.obstacles ── spawn: resolve() inside props
                                      step_all: slide() per enemy, before hash rebuild
```

### Key Interfaces

- `class_name ObstacleField extends RefCounted`
  - `var circles: Array[Vector3]` — `(x, y, radius)` per circle.
  - `var rects: Array[Rect2]` — axis-aligned rectangles.
  - `func resolve(point: Vector2, body_radius: float) -> Vector2`
  - `func slide(from: Vector2, to: Vector2, body_radius: float) -> Vector2`
- `PilotArenas.obstacle_field() -> ObstacleField` (static).
- `EnemyManager.obstacles: ObstacleField`.
- `Player.clamp_inside()` — re-applies the `PLAY_RECT` border margin.

### Implementation Guidelines

- must build the field once per run from `PilotArenas.obstacle_field()` and
  never mutate it afterwards.
- must never allocate per actor per frame; `resolve`/`slide` operate on the
  existing arrays.
- must apply `slide()` before `EnemyManager` rebuilds the spatial hash, so hash
  ids stay in sync with resolved positions.
- must resolve spawn positions inside props — a spawn that starts inside a trunk
  is pushed out, not left stuck.
- must re-clamp the player after obstacle resolution so `PLAY_RECT` remains the
  authoritative border, and must reject a clamped position that still overlaps a
  prop by reverting to the frame's start position — the border and the prop
  together can leave no legal position, and crossing the prop is never the
  answer.
- must keep the tangential nudge deterministic: no RNG in `slide()`.
- must never add `StaticBody2D`, `CharacterBody2D`, `PhysicsServer` calls or a
  navigation mesh.
- must never make canopies or bushes collide.
- projectiles, pickups and weapons must never call the obstacle field.

## Alternatives Considered

### Alternative 1: `StaticBody2D` props + `CharacterBody2D` actors + `move_and_slide()`
- **Description**: Give props `StaticBody2D` shapes and convert actors to
  `CharacterBody2D`, delegating collision to the physics server.
- **Pros**: Battle-tested engine collision; free corner handling, depenetration
  and sliding; no hand-rolled geometry.
- **Cons**: Changes the movement architecture of every actor; adds physics-server
  state and 23 static-shape nodes for what is a fixed layout; makes headless
  tests depend on physics timing; buys nothing this game needs (no dynamic
  bodies, no rotation, no forces).
- **Estimated Effort**: High — every movement path rewrites.
- **Rejection Reason**: The cost lands on the whole movement architecture for a
  static, once-per-run layout this game can solve in a few dozen lines of
  deterministic math.

### Alternative 2: `NavigationAgent2D` avoidance/pathfinding
- **Description**: Give enemies a navigation agent over a navigation mesh so they
  path around props.
- **Pros**: Handles crowd avoidance and pathing around obstacles.
- **Cons**: Designed for navigation meshes and crowds, far heavier than 23 static
  shapes warrant; would not give the player collision at all; the game is one
  open arena, not a network of corridors.
- **Estimated Effort**: High.
- **Rejection Reason**: Wrong tool — it solves a pathfinding problem this game
  does not have and leaves the player's collision unsolved.

### Alternative 3: Keep walking through props (status quo)
- **Description**: Ship direction A with the props as pure decoration.
- **Pros**: Zero code; no risk to the deterministic movement.
- **Cons**: Props that do not exist physically break the map's solidity; a tree
  the player walks through contradicts the painted world.
- **Estimated Effort**: None now, but the visual promise is broken at ship.
- **Rejection Reason**: The user explicitly asked for collisions with trees and
  rocks; the solidity of the map is the point of drawing it.

## Consequences

### Positive
- Props become solid and match the shipped direction-A look.
- Collision and visual data share one source (`PilotArenas` constants), so art
  edits move collision with them.
- Fully deterministic and headless-testable; no physics-timing dependence.
- Zero physics-server state, zero per-frame allocation, negligible cost.

### Negative
- Collision fidelity is circles and rectangles, not the exact ink silhouette; a
  tight visual gap is possible at the edges and must be tuned.
- Hand-rolled push-out and slide geometry must be unit-tested to earn trust.
- A 3-pass push-out is a fixed iteration, not a solver; pathological overlaps
  between multiple props resolve approximately, not exactly.

### Neutral
- The field is a `RefCounted` owned by `main.gd`, not a scene node — it is
  invisible in the editor and configured only through `PilotArenas`.

## Risks

- **Dead-on enemy approach stalls behind a trunk** — mitigated by the
  deterministic tangential nudge in `slide()`.
- **Spawn inside a prop** — resolved at spawn; a resolved spawn is pushed out
  before the hash is rebuilt.
- **A slide pushes the player toward the border** — `clamp_inside()` runs after
  obstacle resolution, so `PLAY_RECT` stays authoritative. If the clamp lands
  back inside a prop (a trunk near the bottom edge), the frame reverts to the
  last free position: the player is stopped by the wedge rather than passing
  through the trunk. Verified by the integration walk test, which failed before
  the revert guard and passes after it.
- **Circle/rect approximation reads differently from the ink** — mitigated by
  the shared `PilotArenas` constants and a retained shipped screenshot; radii
  are tuned if the look disagrees.
- **Enemy slide regresses enemy pass-through** — the two rules are independent;
  slide applies only to props, never to other enemies, and the
  `enemy-behaviors.md` pass-through rule must not change.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `enemy-behaviors.md` | §Collisions: enemies do not collide with each other; only `Player.PLAY_RECT` stops scripted movement | Preserves that rule: `slide()`/`resolve()` apply only to static props, never enemy-vs-enemy; enemy pass-through is unchanged |

The prop-solidity requirement itself is new — it comes from the user's explicit
request and the direction-A (`Édition enluminée`) visual now shipping — and is
not yet recorded in a GDD. `game-designer` should capture it (e.g. in
`game-concept.md` or a props entry) via `/propagate-design-change` so the
requirement earns a stable TR id.

## Performance Implications

- **CPU**: O(actors × 23 shapes) per frame, 3 passes; negligible at this game's
  enemy counts. No allocation after construction.
- **Memory**: One `RefCounted` per run — 22 `Vector3` + 1 `Rect2` in two typed
  arrays; negligible.
- **Load Time**: Negligible — the field is built once at scene setup from
  constants.
- **Network**: None.

## Migration Plan

Additive change; no physics nodes exist to remove.

1. Add `src/systems/obstacle_field.gd` (`ObstacleField`) with `resolve` and
   `slide`.
2. Add `PilotArenas.obstacle_field()` building the 22 circles + 1 rect from the
   existing constants.
3. Wire `main.gd` to own one field, assign `EnemyManager.obstacles`, resolve the
   player after `step_movement`, then call `player.clamp_inside()`.
4. Add `Player.clamp_inside()` re-applying the `PLAY_RECT` margin.
5. Wire `EnemyManager` to resolve spawns and slide enemies before the hash
   rebuild.
6. Add the unit and integration suites from Validation Criteria.

**Rollback plan**: remove the field wiring and the `obstacle_field()` method;
movement reverts to the previous pass-through behaviour with zero physics-node
changes to undo.

## Validation Criteria

- Unit tests: circle and rectangle push-out, and slide deflection, pass for
  representative and boundary cases.
- Integration test: a main-scene tree blocks the player, and
  `EnemyManager.obstacles` is the same field instance `main.gd` owns.
- Retained screenshot of the shipped look in `production/qa/evidence/`.
- The full suite is green (`commands.test` exits 0).

## Related

- `docs/architecture/ADR-0001-test-framework.md` — the gdUnit4 framework the
  collision suites run under.
- `design/gdd/enemy-behaviors.md` — the no-enemy-vs-enemy-collision rule this
  ADR preserves.
- `src/art/pilot_arenas.gd` — source of the prop constants (single source of
  truth).
- `src/art/pilot_overlay.gd` — related delivery in the same lot, not part of
  this decision.
- `src/main.gd`, `src/systems/enemy_manager.gd`, `src/actors/player.gd` — the
  wiring points.
