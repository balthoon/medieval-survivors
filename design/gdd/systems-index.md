# Systems Index: Medieval Survivors

> **Status**: Draft
> **Created**: 2026-11-09
> **Last Updated**: 2026-11-09
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Medieval Survivors is a 20-minute survivor-like: ten 20-second waves in a single arena, automatic weapons, a level-up choice every few seconds, and two encounters with the same Seigneur squelette. Its mechanical scope is deliberately small and deep: **six enemy archetypes / five behaviours**, **ten weapons with distinct mechanics**, **three classes**, a between-wave shop, state-driven music, and a thin meta-progression (record + unlocks + starting choice). The systems below are ordered by the three pillars: every enemy asks a different question (Pilier 2), every run differs through offers and composition (Pilier 1), and the player always has a choice that counts — placement, priority, level-up (Pilier 3). No system may grow into a second arena, manual aiming, a permanent power tree, or gold as a run currency; those are anti-pillars and locked decisions.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Socle de contenu data-driven (Catalogue, EnemyData, WeaponData, RunConfig) | Core | MVP | Implemented | — | — |
| 2 | Horloge de run et vagues (WaveDirector, WaveData) | Core | MVP | Implemented | — | — |
| 3 | Progression de run (XP, montée de niveau, offres, rerolls) | Progression | MVP | Implemented | — (rétro-doc à écrire) | Socle de contenu |
| 4 | Comportements ennemis (roster, boucles, annonces, calendrier) | Gameplay | MVP | In Design | design/gdd/enemy-behaviors.md | Socle de contenu, Progression de run |
| 5 | Combat et armes (dix mécaniques, matrice 10×10) | Gameplay | MVP | In Design | design/gdd/weapons.md | Socle de contenu, Comportements ennemis, Progression de run |
| 6 | Rencontres et vagues (calendrier, plafonds, mélange garanti) | Gameplay | MVP | Not Started | design/gdd/encounters.md | Horloge de run, Comportements ennemis, Socle de contenu |
| 7 | Classes (trois classes, règle signature) | Gameplay | MVP | In Design | design/gdd/classes.md | Combat et armes, Progression de run |
| 8 | Économie de run et boutique (monnaie, prix, stock, pity) | Economy | MVP | Not Started | design/gdd/run-economy.md | Rencontres et vagues, Progression de run, UI/HUD |
| 9 | Audio (musique par état, bus, SFX) | Audio | MVP | Not Started | design/gdd/audio.md | Comportements ennemis, Rencontres et vagues |
| 10 | UI / HUD (HUD de run, level-up, boutique, écrans de fin) | UI | MVP | Implemented | — (specs à écrire, W4-E3 / W6-E2) | Classes, Économie de run, Audio, Localisation |
| 11 | Localisation (clés, CSV, repli fr, extraction) | Meta | Full Vision | In Design | docs/localization-standard.md | — (standard transversal) |
| 12 | Méta-progression (record, déblocages, choix de départ) | Persistence | Full Vision | Not Started | design/gdd/meta-progression.md | Économie de run, Progression de run, Localisation |

**Notes de lecture.**

- Les lignes 1, 2, 3 et 10 n'ont pas de GDD : leur comportement existe déjà dans le code (`src/data/`, `src/classes/wave_director.gd`, `src/main.gd`, `src/ui/`). Elles figurent ici parce que les autres systèmes en dépendent et parce qu'une rétro-documentation est nécessaire avant que W2/W4/W6 ne les modifient. « Implemented » décrit le code, pas un document approuvé.
- `design/gdd/weapons.md`, `design/gdd/classes.md` et `design/gdd/run-economy.md` sont tenus par d'autres agents en parallèle (W2-E1, W3-E1, W4-E1). Cet index ne les rédige pas ; il enregistre leur existence et leurs dépendances.
- `docs/localization-standard.md` est le standard « né localisé » de W8-E1, pas un GDD. Il est listé dans la colonne Design Doc parce que c'est le document de référence du système.
- La colonne Priority suit les paliers du template, mappés sur le brief : P0/P1 = **MVP** (le portail W9-E1), P2 = **Full Vision** (v1.0). Le palier « Vertical Slice » n'est pas utilisé : le portail vertical **est** le MVP.

---

## Categories

| Category | Description | Systems in this project |
|----------|-------------|-------------------------|
| **Core** | Foundation systems everything depends on | Socle de contenu data-driven, Horloge de run et vagues |
| **Gameplay** | The systems that make the game fun | Comportements ennemis, Combat et armes, Rencontres et vagues, Classes |
| **Progression** | How the player grows within a run | Progression de run (XP, montée de niveau, offres) |
| **Economy** | Resource creation and consumption | Économie de run et boutique |
| **Persistence** | Save state and continuity | Méta-progression |
| **UI** | Player-facing information displays | UI / HUD |
| **Audio** | Sound and music systems | Audio |
| **Meta** | Cross-cutting standards outside the loop | Localisation |

**Catégories retirées.** **Narrative** : le jeu n'a ni dialogue, ni quête, ni cinématique ; la fiction vit dans les noms, les silhouettes et les couleurs (game-concept §Minimal Fiction). Aucun système narratif n'est à concevoir.

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function and for the W9-E1 vertical gate | W9-E1 — run complet de 10 vagues, 3 classes, 10 armes, 6 ennemis, boutique, musique | Design FIRST |
| **Vertical Slice** | Not used — the MVP gate **is** the vertical slice in this project | — | — |
| **Alpha** | All features present in rough form | Not planned separately | — |
| **Full Vision** | v1.0 polish and content-complete features | v1.0 — méta, accessibilité minimale, localisation FR/EN | Design SECOND |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Socle de contenu data-driven** — every gameplay system reads its values from `.tres` resources under `data/`; without it, no system is data-driven or testable.
2. **Horloge de run et vagues** — owns the 20 s clock, spawn cadence, `max_alive` and the boss cadence; independent of content.
3. **Localisation** — cross-cutting standard of keys and fallback; every player-facing system depends on it, it depends on none.

### Core Layer (depends on foundation)

1. **Progression de run** — depends on: Socle de contenu (XP curve, offer weights, rerolls).
2. **Comportements ennemis** — depends on: Socle de contenu (`EnemyData`), Progression de run (XP values), Localisation (keys).
3. **Combat et armes** — depends on: Socle de contenu (`WeaponData`), Comportements ennemis (damage windows, recovery, detonation order), Progression de run (offers).

### Feature Layer (depends on core)

1. **Rencontres et vagues** — depends on: Horloge de run, Comportements ennemis (unlock calendar, weights), Socle de contenu.
2. **Classes** — depends on: Combat et armes (starting weapon), Progression de run (stats).
3. **Économie de run et boutique** — depends on: Rencontres et vagues (tension arc, trophies), Progression de run, UI/HUD (panel interface).

### Presentation Layer (depends on features)

1. **Audio** — depends on: Comportements ennemis (telegraph events), Rencontres et vagues (wave states).
2. **UI / HUD** — depends on: Classes, Économie de run, Audio (volume), Localisation (all strings).

### Polish Layer (depends on everything)

1. **Méta-progression** — depends on: Économie de run, Progression de run, Localisation, Persistence (save format).

---

## Recommended Design Order

This is the **design** order (which GDD must exist before which other GDD can be written), not the build order. The production plan (`production/plans/drastic-upgrade-plan.md`) owns the build sequence and file collisions.

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Localisation (standard) | Full Vision | Foundation | localization-lead | S |
| 2 | Comportements ennemis | MVP | Core | game-designer | M |
| 3 | Combat et armes | MVP | Core | systems-designer | L |
| 4 | Classes | MVP | Feature | game-designer | M |
| 5 | Économie de run et boutique | MVP | Feature | economy-designer | L |
| 6 | Rencontres et vagues | MVP | Feature | game-designer | M |
| 7 | Audio | MVP | Presentation | audio-director | M |
| 8 | UI / HUD (spécifications d'écran) | MVP | Presentation | ux-designer, ui-programmer | M |
| 9 | Progression de run (rétro-doc) | MVP | Core | systems-designer | S |
| 10 | Méta-progression | Full Vision | Polish | economy-designer | M |

**Why this order.** The localisation standard goes first because every later document must be born localised. Behaviours go before weapons and encounters because both read its damage windows and calendar. Economy goes before encounters in the *design* order because the shop's tension arc must be designed against ten waves before the encounter composition is tuned; the build order is the reverse (encounters in phase 10, shop in phase 13–14) and that is the producer's call. Audio and UI can be designed in parallel once their upstream systems are stable. Meta is last because it consumes the run's economy and progression. A retro-doc of run progression is scheduled before W2/W4/W6 modify `main.gd`, not because it blocks them.

**Effort estimates**: S = 1 session, M = 2–3 sessions, L = 4+ sessions. A session is one focused design conversation producing a complete GDD.

---

## Circular Dependencies

**None found.** Two pairs are interlocked in implementation but **not** circular at the design level; each is broken by a named interface:

- **Économie de run ↔ UI/HUD** — the shop panel needs the shop API, and the shop API needs a panel to be used. Broken by W4-E2 (pure `Wallet` / `Shop` models, no node access) before W4-E3 (panel + HUD API). The economy GDD owns the model; the UI spec owns the screen.
- **Audio ↔ UI/HUD** — the settings screen needs audio buses, and music needs the run state. Broken by `SettingsStore` (autoload, W6-E2) and by the audio bus layout (W5-E1) being defined before the settings screen.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Comportements ennemis | Design | Five behaviours at 60 enemies may become unreadable; two simultaneous commitments can be unwinnable (Pilier 2 vs Pilier 3) | Telegraph budget (max 2 charge bands, 6 drawn threads), spaced unlocks, W1-E5 captures + colour-blind review, W1-E4 validates no unavoidable wave |
| Rencontres et vagues | Design / Technical | Weighted RNG can miss a newly unlocked behaviour, breaking the "≥ 4 behaviours" criterion | Forced unlock guarantees (2 spawns, 1 on boss waves), seeded tests, carry-forward of an unfulfilled guarantee |
| Économie de run et boutique | Design | The run currency could be mistaken for gold/XP, or become a numeric power shop | Locked: gold = XP only; W4-E1 explores non-gold visual language with `art-director`; W4-E2 pure models + pity test |
| Audio | Scope | Music for a solo project is expensive; “music by state” can balloon | W5-E1 defines a small state set (calm / pressure / boss / victory) and a bus layout before any composition; SFX rebalance is advisory |
| Localisation | Scope | Strings frozen too late make extraction expensive | Born-localised rule from W8-E1; enemy/weapon/screen keys defined at authoring time; extraction W8-E2 after content freeze |
| UI / HUD | Design | No GDD exists; screens are added by different epics and can drift into inconsistent ink styles | Art bible governs the frame; per-screen specs W4-E3 / W6-E2 / W3-E4; one UI owner per phase (file collision list) |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 12 |
| Design docs started | 4 (enemy-behaviors, weapons, classes, localization standard) |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 0 / 10 (enemy-behaviors drafted, awaiting /design-review) |
| Full Vision systems designed | 0 / 2 (localization standard in progress) |
| Systems implemented without a design doc | 4 (socle de contenu, horloge de run, progression de run, UI/HUD) |

---

## Next Steps

- [x] Enumerate the systems and their dependencies (W1-E0)
- [ ] Review and approve this systems enumeration (producer + creative-director)
- [ ] Run `/design-review design/gdd/enemy-behaviors.md`
- [ ] Design Rencontres et vagues (W1-E4) from the calendar in `enemy-behaviors.md`
- [ ] Retro-document Progression de run before W2/W4/W6 edit `main.gd`
- [ ] Design Économie de run (W4-E1) after the enemy tension arc is fixed
- [ ] Write per-screen UI specs at W4-E3 / W6-E2 rather than one monolithic UI GDD
- [ ] Run `/review-all-gdds` once the MVP set (behaviours, weapons, classes, economy, encounters) exists
- [ ] Run `/gate-check technical-setup` when the MVP systems are designed
