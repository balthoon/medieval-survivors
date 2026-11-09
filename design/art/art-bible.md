# Art Bible — Medieval Survivors

> Direction: **encre de conte**. A hand-inked storybook drawn in vector, not a
> pixel game and not a smooth-shaded one. The arena already speaks this
> language (`src/systems/arena_decor.gd`) — this document makes the rest of the
> game speak it too, and gives a rule to settle any future argument.

## The one rule

**Silhouette first.** If a creature is not identifiable from its outline alone,
in one glance, at 100 % zoom, on the grass, it is not finished. Colour, shading
and detail come after the shape reads.

Corollary: no two archetypes may share an outline. The wolf is horizontal, the
orc is wide, the skeleton is narrow with a round skull, the boss is tall with a
cape. Squint at the screen: they must still be four different things.

## Palette

Shared ink and paper come from the arena so that nothing on screen looks like it
was drawn by a different hand.

| Role | Value | Notes |
|---|---|---|
| Ink | `#29241F` → `Color(0.16, 0.14, 0.12)` | Every outline, every text edge. Never pure black. |
| Ink, soft | ink at 55 % alpha | Interior detail lines (ribs, folds). |
| Ground shadow | ink at 10–14 % alpha | Every actor gets one. Nothing floats. |
| Grass base | `Color(0.765, 0.820, 0.608)` | The backdrop everything must read against. |
| Bone | `Color(0.851, 0.812, 0.702)` | Skeleton, boss skull. |
| Bone shade | `Color(0.663, 0.627, 0.529)` | |
| Orc hide | `Color(0.431, 0.549, 0.239)` | Deeper than the grass — the orc must not vanish into it. |
| Wolf pelt | `Color(0.420, 0.435, 0.478)` | Cool grey, the only cool grey in the palette. |
| Knight steel | `Color(0.400, 0.455, 0.541)` | |
| Knight tabard | `Color(0.706, 0.208, 0.196)` | The player's accent. One per actor. |
| Boss violet | `Color(0.360, 0.250, 0.420)` | Already in `seigneur_squelette.tres`. |
| Gold | `Color(0.851, 0.651, 0.149)` | XP **only**. Never decorative. |
| Danger | `Color(0.75, 0.20, 0.14)` | Telegraphs and boss effects. |

### Three tones, one accent

Every actor is built from **base + light + dark** of a single hue, plus **one**
accent colour (tabard red for the knight, gold for the boss crown, tusks for the
orc). A second accent is a mistake, not a flourish.

Light comes from **top-left**. Light tone on the upper-left third of each volume,
dark tone on the lower-right, base in between. Consistency here is what makes a
field of sixty enemies look drawn rather than assembled.

## Line work

- Outline weight: **2 px** at 1× — the same as `ArenaDecor.INK_WIDTH`.
- Interior detail lines: **1 px**, ink at 55 %.
- Outlines never scale with the creature: a boss gets the same 2 px ink as a
  skeleton. Weight is a property of the drawing, not of the subject.
- No outline inside an outline. One rim per volume, and volumes overlap rather
  than nest.

## Proportions

- Everything is expressed as a fraction of the creature's `radius`, so a data
  change scales the whole drawing coherently.
- Heads read large. A realistic head on a 26 px body is three pixels; a head at
  ~45 % of the body width is what makes the creature legible.
- The player is **14 px** radius and must stay the smallest busy shape on screen
  apart from gems — its clarity comes from the red tabard, not from size.

## Actors

### The knight (player)

Four drawn orientations — front, back, left, right — selected from `facing`.
Silhouette: round helm, two pauldrons wider than the torso, a red surcoat over
most of the torso front and back, short cloak behind. The surcoat is wide on
purpose — a stripe down a 28 px body is three pixels of red, which is not
enough to find yourself with. Weapons are **not** part of this drawing:
`WeaponView` owns them and rotates them independently.

### Skeleton

Narrow and vertical. Round skull (45 % of body width) over a tapered ribcage,
three rib lines, two thin arms. Bone palette. Eyes are two ink sockets — no
colour, so the boss's glowing eyes stay special.

### Orc

Wide and low. Barrel torso, shoulders as two circles pushed outside the body
width, tusks as two small bone triangles, a club leaning on one side. Hide green
dark enough to stand off the grass.

### Wolf

The only quadruped, and the only cool grey. Low capsule body on four short legs,
head sitting above the chest with a long muzzle, two short wide ears, and a tail
swept out to one side so the outline stays wider than it is tall. Cool grey —
the only desaturated creature, so a pack reads as a pack.

### Boss — Seigneur squelette

Tall, with a cape that is visible behind the body and a gold crown. Skull larger
and more angular than the plain skeleton, ribs deeper, eyes drawn in the accent
colour so it reads as *the* threat. Carries a staff.

## Gems

A faceted crystal, not a diamond outline: three facets (light crown, base,
dark side), ink rim, one specular fleck. Gold, because gold means XP and nothing
else on the field is gold.

## Motion

- Actors do not idle-bob on the grass except the player and the gems. A field of
  bobbing sprites reads as noise.
- The player's drawing breathes by ±1 px at 1.6 Hz — enough to feel alive,
  never enough to move the hitbox.
- Gems rotate their specular fleck slowly; the crystal itself does not spin.

## HUD

The HUD is drawn in the same ink as the world, never in flat grey boxes.

- Every bar sits in an ink frame with a 1 px inner light line — the frame is the
  design, the fill is the data.
- Panels (level-up, boss loot) are ink-outlined paper with a heavy top rule and
  a title in small caps.
- Typography: one family, three sizes — **28 px** banners, **20 px** panel
  titles, **14 px** body. Labels are title case, banners are upper case.
- The boss bar is the only bar allowed a saturated red fill. The HP bar stays in
  the knight's steel blue, so red on the display always means the threat and
  never your own health.

## Evidence

Every change to this document's output must leave a screenshot in
`production/qa/evidence/`. A look that was described but never seen is not a
look.
