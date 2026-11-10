# ADR-0004: Actor art baked into textures

## Status

Proposed

## Date

2026-11-10

## Last Verified

2026-11-10

## Decision Makers

- `technical-director` — rendering architecture, performance budget
- `technical-artist` — art fidelity and bake pipeline
- `engine-programmer` — `SubViewport` bake and texture lifecycle

## Summary

The storybook renderer builds each creature from dozens of polygons, hatch lines
and edge bands; cached or not, every primitive is submitted every frame. A
wave-5 crowd plus its boss cost ~7,600 extra draw calls per frame and held the
boss wave at ~47 FPS with 130 ms process spikes on the Intel UHD test machine.
`ArtCache` renders each archetype once into an off-screen `SubViewport` and
stores an `ImageTexture`, so a creature becomes one textured quad. The same
crowd now holds 60 FPS at the arena's baseline draw-call count.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 stable |
| **Domain** | Rendering |
| **Layer** | Presentation |
| **Knowledge Risk** | HIGH — engine version is post-cutoff; the APIs used are long-standing 4.x APIs (see `docs/engine-reference/godot/VERSION.md`) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Baked textures equal the vector drawing (retained screenshots), transparent background, no clipping at the canvas edge, headless runs still fall back to vector drawing |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | `ADR-0003-character-animation.md` — the enemy `Body` child this cache textures |
| **Enables** | None |
| **Blocks** | None |
| **Ordering Note** | The cache must not change `ActorArt`'s drawing code: it is a rendering path, not an art change |

## Context

### Problem Statement

The shipped "Édition enluminée" direction draws every actor procedurally. It
looks right, but a full boss wave does not run at 60 FPS on the target machine
(Intel UHD integrated graphics). The user reported the lag during the boss wave,
which has the largest crowd and the most complex body.

### Current State

- `ActorArt.draw_creature` routes to `VisualPilot` and draws a creature as
  dozens of filled shapes, outlines, hatch lines and edge bands.
- `Enemy.Body`, `DeathFade` and `Player` draw through that path.
- A `CanvasItem` caches its draw commands, so stopping the per-frame
  `queue_redraw()` removed the expensive geometry rebuild — but every cached
  primitive is still submitted to the renderer every frame.
- Measured with `tools/perf_boss_wave.gd`: an empty arena costs ~5,200 draw
  calls and holds 60 FPS; 42 enemies plus the boss cost ~12,900 draw calls and
  fall to ~47 FPS, with process-time spikes to 130 ms.

### Constraints

- The art direction must not change: the baked picture has to be the same
  drawing, not a simplified stand-in.
- The cast is data-driven: art key, radius and tint come from `EnemyData`, so a
  `.tres` edit must still recolour or resize the creature.
- Tests and CI run headless, where viewport textures cannot be captured.
- The game must keep working if a bake fails: an untextured body falls back to
  the vector drawing.

### Requirements

- Reduce per-creature render submission from ~181 draw calls to a handful.
- Keep the hit flash and the crit flash readable.
- Keep the death fade identical to the living body.
- Bake once per archetype, not per instance.
- Do not block the run while baking.

## Decision

### 1. Bake every archetype once

`ArtCache.request(host, art, radius, tint)` starts three background bakes per
creature: normal, hit flash and crit flash. Each bake renders
`ActorArt.draw_creature` into a transparent `SubViewport` sized
`radius * 2.2 * 2 + 16` px square, waits for `RenderingServer.frame_post_draw`,
copies the image and stores an `ImageTexture` keyed by style, art, radius, tint
and variant.

### 2. Draw one texture per body

`Enemy.Body._draw` and `DeathFade._draw` ask `ArtCache.texture(...)` first. A
hit swaps the body to the hit-flash texture and a crit to the crit-flash
texture; the flash ends by swapping back. A missing texture falls back to
`ActorArt.draw_creature`.

### 3. Bake at run start, in the background

`main.gd` requests every catalogue enemy and the boss from `_ready()`, waits
with `ArtCache.await_idle`, then repaints the bodies already on the field. The
first spawn is 1.4 s away, so the bake finishes during the wave banner.

### 4. Headless keeps the vector path

`ArtCache.request` returns immediately when `DisplayServer.get_name()` is
`headless`. Tests, CI and every `--headless` tool run keep the existing vector
drawing and never touch a viewport texture.

### Architecture Diagram

```text
main._ready()
    └─ ArtCache.request(host, art, radius, tint)
           └─ per variant (none, hit, crit)
                 SubViewport (transparent, UPDATE_ONCE)
                     └─ Painter (Node2D) → ActorArt.draw_creature
                 await RenderingServer.frame_post_draw
                 get_texture().get_image() → ImageTexture
                 _textures[key] = texture

Enemy.Body._draw()
    └─ ArtCache.texture(art, radius, tint, flash_kind)
           ├─ texture found → draw_texture(...)       one draw call
           └─ null          → ActorArt.draw_creature  vector fallback
```

### Key Interfaces

- `ArtCache.texture(art: String, radius: float, tint: Color, kind: int) -> Texture2D`
  — the baked texture, or null while baking and in headless.
- `ArtCache.request(host: Node, art: String, radius: float, tint: Color) -> void`
  — starts the three variant bakes; safe to call repeatedly.
- `ArtCache.await_idle(host: Node) -> void` — awaits every bake started so far.
- `Enemy.refresh_body()` — asks the body to repaint after a bake lands.

### Implementation Guidelines

- A bake must draw through `ActorArt.draw_creature`; the cache must never
  reimplement a creature.
- The canvas must cover the art's full extent with transparent margin; the
  current factor is `EXTENT_SCALE = 2.2` plus 8 px.
- The cache key must include `VisualPilot.style`; switching direction must bake
  its own textures.
- `request` must never run in headless, and must never block on a bake.
- The fallback path must stay: a missing or failed bake is a visual
  degradation, never a crash or a blank body.
- The flash colours and alpha must live in one place — `ArtCache` — and
  `Enemy` reads them, so the baked flash and the vector fallback agree.

## Alternatives Considered

### Alternative 1: Simplify the storybook art

- **Description**: drop hatching, edge bands and some outlines until the draw
  call count fits the budget.
- **Pros**: no new rendering path, no cache lifecycle.
- **Cons**: changes the shipped art direction the user chose; the detail is the
  point of "Édition enluminée".
- **Estimated Effort**: low code, high art risk.
- **Rejection Reason**: the user rejected the flat look; reducing detail
  reverses their decision.

### Alternative 2: Triangulate each creature into one vertex-coloured primitive

- **Description**: replace the per-shape calls with one triangle array carrying
  per-vertex colours.
- **Pros**: one draw call without a texture; no bake, no memory.
- **Cons**: requires reimplementing every shape, outline and hatch as triangles;
  antialiasing and blending behave differently; a large rewrite of the art
  renderer for a result the texture path already gives.
- **Estimated Effort**: very high.
- **Rejection Reason**: disproportionate risk to the art for the same win.

### Alternative 3: Pre-render PNGs offline and ship them as assets

- **Description**: run a tool once, commit one PNG per archetype and flash
  variant, load them at run time.
- **Pros**: fastest startup; no `SubViewport` at run time.
- **Cons**: a `.tres` radius or tint edit silently mismatches the committed PNG;
  every content or art change needs a re-bake and a regenerated asset commit.
- **Estimated Effort**: medium.
- **Rejection Reason**: the art must stay data-driven; a runtime bake cannot
  drift from the data that produced it.

### Alternative 4: Keep the per-frame vector drawing

- **Description**: accept the boss-wave frame drop.
- **Pros**: no new code.
- **Cons**: the user reported it as unplayable; 47 FPS average with 130 ms
  spikes is not a shipped frame budget.
- **Estimated Effort**: none.
- **Rejection Reason**: fails the reported requirement.

## Consequences

### Positive

- A creature costs one draw call instead of ~181; the boss-wave crowd returns
  to the empty-arena draw-call baseline.
- The baked picture is the same code path as the vector art, so future art
  changes propagate without a separate asset pipeline.
- The hit and crit flashes are baked, so they cost no extra draw call either.
- Headless tests and CI keep the old path and stay deterministic.

### Negative

- Bake time at run start (~one second of frames, during the wave banner).
- Textures are cached for the process lifetime; a `.tres` edited *during* a run
  will not re-bake until the next launch. Content is not hot-reloaded anyway.
- A baked texture is filtered, so a body at a fractional pixel position can be
  a hair softer than the vector drawing.

### Neutral

- The cache is static state shared across scene reloads; a restart reuses the
  textures baked by the previous run.
- `DeathFade` gets the texture path for free but does not trigger a bake: a fade
  for an unbaked archetype uses the vector fallback for its 0.22 s life.

## Risks

- **A bake renders an empty or flipped image** — mitigated by three retry
  frames, by reading the image only after `frame_post_draw`, and by the
  retained zoom capture `production/qa/evidence/w2-boss-wave.png` showing the
  baked boss, orcs and knight view correctly.
- **The canvas clips a wide or tall art** — mitigated by `EXTENT_SCALE = 2.2`
  plus margin, which covers the widest extent (the boss crown, ~1.97 radii after
  the palette's actor scale).
- **The startup bake stutters the first second** — accepted and hidden by the
  1.2 s wave banner; the stress probe's first sample is the only one below 60.
- **A headless run accidentally tries to bake** — guarded at the single entry
  point, `ArtCache.request`, by the display-server check.
- **Static cache state leaks between styles** — prevented by including
  `VisualPilot.style` in the key.

## GDD Requirements Addressed

Foundational — no GDD requirement. Enables: the storybook art direction chosen
from the three mockups to run at its designed wave density, including the
boss-wave crowd that `design/gdd/enemy-behaviors.md` and the wave tuning define.

## Performance Implications

- **CPU**: the per-frame cost of a creature drops from ~181 submitted primitives
  to one textured quad. Measured on the Intel UHD test machine with
  `tools/perf_boss_wave.gd`: 42 enemies + boss were ~12,900 draw calls / ~47 FPS
  before, ~5,200 draw calls / 60 FPS after. Empty-arena baseline is ~5,200.
- **Memory**: one texture per archetype and flash variant. At the shipped radii
  that is roughly 74×74 (skeleton), 104×104 (orc), 64×64 (wolf) and 148×148
  (boss), three variants each — under 100 KB of RGBA before compression.
- **Load Time**: the bake runs after `_ready()`, across a handful of frames,
  while the first wave banner is on screen; it never blocks gameplay.
- **Network**: none.

## Migration Plan

Additive; no data or scene migration.

1. Add `src/art/art_cache.gd`.
2. Make `Enemy.Body` and `DeathFade` texture-first with a vector fallback.
3. Request the catalogue's archetypes from `main._ready()` and refresh bodies
   once the bakes land.
4. Re-run the captures and the boss-wave probe.

**Rollback plan**: delete the `ArtCache.request` call from `main.gd`. Every body
returns to the vector drawing with no gameplay change; the cache becomes inert.

## Validation Criteria

- `commands.test` exits 0 in headless, proving the fallback path is intact.
- `tools/perf_boss_wave.gd` reports 60 FPS for 42 enemies plus the boss, with a
  draw-call count at the empty-arena baseline.
- `production/qa/evidence/w2-boss-wave.png` and its zoom show the baked orcs,
  boss and knight with no clipping, blank body or flipped art.
- `production/qa/evidence/w2-look-storybook.png` and
  `production/qa/evidence/w2-e2-weapon-mechanics.png` regenerate identically to
  the vector art.

## Related

- `docs/architecture/ADR-0003-character-animation.md` — the `Body` child this
  ADR textures and the waddle that translates it.
- `src/art/art_cache.gd` — the implementation.
- `tools/perf_boss_wave.gd` — the repeatable boss-wave probe.
- `docs/engine-reference/godot/VERSION.md` — pinned engine, post-cutoff warning.
