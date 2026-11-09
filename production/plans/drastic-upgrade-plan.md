# Plan de production — la montée en gamme

**Établi le :** 2026-11-09
**Source :** `production/briefs/drastic-upgrade.md`
**Méthode :** neuf chefs de département ont découpé le brief contre le code réel ; le producteur a fusionné ; le directeur technique et le directeur créatif ont attaqué le plan ; le producteur a réparé. Ce document est le plan réparé.

---

## Verdict

**READY SOUS RÉSERVE** — le socle (W0) et les P0 (W1, W2) sont exécutables dans l'ordre séquencé. W3 (classes) et W5 (audio) ont été reconstruits par le producteur pendant la révision : ils doivent être redécoupés par `game-designer` et `audio-director` avant la phase 8. Les trois décisions de design ouvertes sont tranchées ci-dessous par le chef d'équipe.

## Décisions du chef d'équipe

1. **Accessibilité avancée** (remappage, taille de texte, daltonisme, manette) reste planifiée en phase 18. Elle n'est coupée que si le portail W9-E1 échoue — jamais en silence.
2. **Pas de ciblage manuel en vague.** La visée automatique reste celle du brief ; le pilier 3 est porté par le level-up et la boutique.
3. **Méta = record + déblocages + choix de départ.** Pas de conversion des trophées en puissance permanente.
4. **Le loup (`loup_maudit`) devient le chargeur.** Seul quadrupède du roster, sa silhouette porte l'annonce.
5. **La monnaie n'est pas dorée.** L'or reste réservé à l'XP dans la bible d'art.

## Séquence — 19 phases

| Phase | Epics | Pourquoi |
|---|---|---|
| 1 — Concept | EW0-01 → EW0-05 | Un seul `game-concept.md` ; tranche loup=chargeur et or=XP avant toute conception. |
| 2 — Socle test | W0-E1 | Seul éditeur de `project.godot` ; débloque toute preuve qualité. |
| 3 — Tests portés | W0-E2 | Porte les `verify` en gdUnit4 **avant** le refactor, pour que la suite le protège. |
| 4 — Données hors code | W0-E3 | Refactor `main.gd` protégé par la suite portée. |
| 5 — CI bloquante | W0-E4 | CI après le vert ; échoue sur zéro test et exits non nuls. |
| 6 — Conventions + GDD | W8-E1, W1-E0, W2-E1, W3-E1 | Docs disjoints ; le standard « né localisé » avant le contenu. |
| 7 — GDD économie | W4-E1 | Après W1-E0 pour l'arc de tension. |
| 8 — Socle ennemis, art, audio | W1-E1, W1-E3, W3-E3, W5-E1 | Code ennemi, art ennemis/classes et musique en parallèle. |
| 9 — Cerveaux, classes, boutique logique, SFX | W1-E2, W3-E2, W4-E2, W5-E2 | Quatre chantiers disjoints. |
| 10 — Rencontres, mécaniques armes, art armes | W1-E4, W2-E2, W2-E3 | W2-E2 attend W1-E2. |
| 11 — Preuves ennemis + armes | W1-E5, W2-E4 | Captures et matrice 10×10 après comportements et mécaniques. |
| 12 — Écran classe + méta GDD | W3-E4, W7-E1 | Scène et doc en parallèle. |
| 13 — Panneau boutique | W4-E3 | Après W4-E2 ; édite `main.tscn` après W3-E4. |
| 14 — Intégration boutique | W4-E4 | Branche la boucle après W1-E5 et W2-E2. |
| 15 — **Portail vertical** | W9-E1 | Mesure la barre du brief sur un run complet. |
| 16 — Méta-progression | W7-E2 | Persistance après W7-E1 et W4-E2. |
| 17 — Accessibilité minimale | W6-E1, W6-E2 | Hors pilier ; volumes après W5-E1. |
| 18 — Accessibilité avancée | W6-E3 | Différée derrière les piliers. |
| 19 — Localisation | W8-E2, W8-E3, W8-E4 | Après gel des chaînes. |

## Catalogue des epics

### Bloc A — Concept et socle

- **EW0-01 — Socle du document : audit de vérité et squelette** (`narrative-director`, dépend de —) — Audit de vérité du build · Squelette conforme au template.
- **EW0-02 — Identité de jeu : positionnement, piliers, boucle** (`game-designer`, ← EW0-01) — Pitch et Core Identity adossés au build · Core Fantasy sans hook inventé · Trois piliers et anti-piliers · Boucle moment/run/session/méta · Analyse joueur et inspirations.
- **EW0-03 — Fiction minimale : monde, dix vagues, deux boss** (`world-builder`, ← EW0-02) — Prémisse de monde · Dix vagues justifiées · Décision canon : les deux boss · Bestiaire · Cadre des trois classes · Ton, lexique et interdits.
- **EW0-04 — Ancrage visuel encre de conte** (`art-director`, ← EW0-03) — Visual Identity Anchor · Rôles couleur : or=XP verrouillé.
- **EW0-05 — Technique, portée, risques et verrouillage** (`producer`, ← EW0-04) — Technical Considerations · MVP et paliers de portée · Risques et questions ouvertes · Porte Concept franchie · Déblocage confirmé W1-W3.
- **W0-E1 — Socle gdUnit4 et porte d'entrée unique** (`qa-lead`) — Vendoriser gdUnit4 6.2.2 · Scaffolder `tests/` · MainSceneFixture · Rouge puis vert (exit 100) · ADR-0001 test framework.
- **W0-E2 — Remplacer les 4 scripts de vérification par gdUnit4** (`lead-programmer`, ← W0-E1) — Porter verify_facing · verify_slice02 · verify_slice03 · slice04 logique pure · slice04 intégration boss · Supprimer scripts + carte couverture.
- **W0-E3 — Sortir les données de run de `main.gd`** (`lead-programmer`, ← W0-E1, W0-E2) — RunConfig (tuning seul) · Catalogue par énumération · Remplacer les 7 chemins · Déplacer constantes de boss et run · Unlock + id stable dans EnemyData · Migrer l'input vers InputMap · Garde-fou `.tres` orphelin · Aligner les scripts de capture.
- **W0-E4 — CI bloquante** (`devops-engineer`, ← W0-E1..E3) — `tests.yml` · Échouer sur zéro test et exits 101/103/104/105 · Job obligatoire sur main · Contrat de merge dans `tests/README`.

### Bloc B — Conventions et GDD

- **W8-E1 — Socle de localisation : clés, CSV, repli** (`localization-lead`) — Standard « né localisé » · Pipeline CSV + repli fr.
- **W1-E0 — GDD comportements : règles, roster, télégraphies** (`game-designer`, ← EW0-05) — Squelette GDD + roster + calendrier · Boucles marcheur/chargeur/tireur · Exploseur, invocateur, cas limites.
- **W2-E1 — Contrat et données des dix armes** (`systems-designer`, ← EW0-05, W0-E3) — Spécifier 10 armes + matrice 10×10 · Mécaniques des 4 existantes · `mechanic` dans WeaponData · Les dix `.tres` · Offre décisionnelle · Né localisé.
- **W3-E1 — Concevoir les trois classes** (`game-designer`, ← EW0-05) — GDD classes · Règle signature par classe.
- **W4-E1 — Concevoir monnaie de run, prix et stock** (`economy-designer`, ← EW0-05) — Langue visuelle non dorée · Modèle de monnaie · Tables robinets/puits + pity · Arc de tension 10×20 s · GDD + design-review.

### Bloc C — Les P0 en parallèle

- **W1-E1 — Socle data-driven : comportement, état, contexte** (`ai-programmer`, ← W0-E1, W0-E3, W1-E0) — ADR comportement/état/contexte · Enemy délègue + `EnemyData.behavior` · BehaviorTelegraph 4 formes · BehaviorContext + area strike · SlamBehavior hors d'`enemy.gd`.
- **W1-E2 — Les cinq cerveaux** (`ai-programmer`, ← W1-E0, W1-E1, W0-E1) — WalkerBehavior · ChargerBehavior · EnemyBolt + manager · RangedBehavior · ExploderBehavior · SummonerBehavior · Né localisé.
- **W1-E3 — Silhouettes et annonces encre de conte** (`art-director`, ← W1-E0) — Bible : 3 ennemis + loup chargeur · ActorArt loup sans cornes (posture + ligne au sol) + exploseur · ActorArt tireur + invocateur · Les 4 annonces en revue d'art.
- **W1-E4 — Rencontres : calendrier, plafonds, mélange garanti** (`game-designer`, ← W1-E0, W1-E2, W0-E3) — Spawner piloté par données · Data de rencontres · Test 4 comportements garantis · Pacing par vague thème · Composition émergente.
- **W1-E5 — Preuve de run, debug et budget 2 ms** (`qa-lead`, ← W1-E2..E4) — Overlay debug F3 · Captures par comportement · Run acceptation 4 comportements · Canary 2 ms / 60 ennemis · Revue daltonisme.
- **W2-E2 — Résolution des dix mécaniques** (`gameplay-programmer`, ← W2-E1, W1-E2) — Faux 360° · Arbalète perforante · Bâton chaîne 3 sauts · Orbe orbitale · Encensoir à mèche · Lame vampire · Mécaniques des 4 existantes · Nommer la mécanique dans l'offre.
- **W2-E3 — Silhouettes et annonces à l'encre** (`art-director`, ← W2-E1) — Bible : six silhouettes · Faux + lame vampire · Arbalète + encensoir · Orbe, chaîne, anneau · Planche des dix armes.
- **W2-E4 — Preuve et non-domination** (`qa-lead`, ← W2-E2, W2-E3, W0-E1) — Un test par mécanique · Trois runs, trois builds.
- **W3-E2 — ClassData et règle signature** (`gameplay-programmer`, ← W3-E1, W0-E1, W0-E3) — ClassData + stats · Appliquer la règle signature · Arme de départ branchée.
- **W3-E3 — Silhouettes des trois classes** (`art-director`, ← W3-E1) — Bible : trois silhouettes · ActorArt des classes.
- **W3-E4 — Écran de sélection de classe** (`ui-programmer`, ← W3-E2) — Écran clavier · Capture.
- **W5-E1 — Musique par état et bus de mixage** (`audio-director`, ← EW0-05) — États audio · Bus maître/musique/SFX · Musique par état composée.
- **W5-E2 — SFX rééquilibrés et branchement** (`sound-designer`, ← W5-E1) — Rééquilibrer les 8 SFX contre la musique · Brancher la musique aux états du run.

### Bloc D — Économie et intégration

- **W4-E2 — Portefeuille, boutique et données pures** (`systems-designer`, ← W4-E1, W0-E1) — Wallet pur testé · Shop pur + pity · Schémas monnaie/stock/offres · Test GDD = données.
- **W4-E3 — Panneau de boutique et API HUD** (`ui-programmer`, ← W4-E2) — Spécifier l'écran · ShopPanel + API HUD + solde · Entrées clavier/manette · Zéro prix en dur · Signature art-director.
- **W4-E4 — Brancher monnaie et boutique dans la boucle** (`systems-designer`, ← W4-E3, W2-E2, W1-E5) — Hold/resume de WaveDirector · Créditer les trophées · Ordonnancer la boutique · Appliquer chaque achat · Test flux complet · Preuve 3 achats + capture.
- **W9-E1 — Vertical intégré : vingt minutes sans ennui** (`producer` + `qa-lead`, ← W1-E5, W2-E4, W4-E4, W3-E4, W5-E2) — Run complet 10 vagues · Capture du run entier · Chaque classe survit au premier boss · Aucune plage de 3 vagues sans décision · Arc de tension mesuré.

### Bloc E — Méta et accessibilité

- **W7-E1 — Concevoir la méta-progression** (`economy-designer`, ← EW0-05, W2-E4, W4-E1) — Trancher le modèle (pas d'arbre) · 4-6 déblocages · Choix de départ · ADR format de sauvegarde · GDD + design-review.
- **W7-E2 — Implémenter sauvegarde et déblocages** (`lead-programmer`, ← W7-E1, W4-E2, W0-E1) — ProfileData + ProfileStore · Record à mort/victoire · Déblocages · Choix de départ appliqué · Record sur cartes de fin · Écran choix de départ · Preuve deux runs diffèrent.
- **W6-E1 — Cadre d'accessibilité et audit** (`accessibility-specialist`) — Document d'accessibilité · Auditer HUD/level-up/victoire.
- **W6-E2 — Pause et réglages de session** (`ui-programmer`, ← W6-E1, W5-E1) — Matrice d'états · État pause · Écran pause · SettingsStore autoload · Écran réglages + volumes.
- **W6-E3 — Polissage accessibilité avancé (différé)** (`ui-programmer`, ← W6-E1, W6-E2) — InputMap + remappage · Theme + tailles de texte · Outil daltonisme · Manette de bout en bout.

### Bloc F — Localisation

- **W8-E2 — Extraction des chaînes joueur** (`localization-lead`, ← W8-E1, W0-E3) — HUD + `main.tscn` · Données `.tres` · Écrans de run.
- **W8-E3 — Traduction anglaise** (`localization-lead`, ← W8-E2, W1-E5, W2-E4, W4-E4, W6-E3, W7-E2) — Figer la source française · Glossaire fr/en · Pack de contexte + import anglais.
- **W8-E4 — Vérification locale** (`qa-lead`, ← W8-E3, W0-E4) — Scan chaînes en dur + parité · Pass locale observé + pseudo-locale.

## Collisions de fichiers

- `src/main.gd` — carrefour W0-E3, W1-E1/E2/E4/E5, W2-E2, W4-E4, W7-E2, W6-E2, W8-E2 : jamais deux epics en parallèle.
- `src/systems/enemy_manager.gd` — W1-E1/E2 vs W2-E2 : les armes attendent le socle comportements.
- `src/systems/spawner.gd` + `src/data/enemy_data.gd` — refactor fusionné dans W0-E3.
- `src/art/actor_art.gd` — W1-E3 vs W3-E3 : silhouettes ordonnancées par phases.
- `src/ui/hud.gd` + `scenes/main.tscn` — W3-E4, W4-E3, W6-E2/E3, W7-E2, W8-E2 : séquentiel, réimport après chaque édition.
- `project.godot` — W0-E1 (plugin), W8-E1 (i18n), W6-E2 (autoload), W7-E2 (autoload) : un seul éditeur par phase.
- `design/gdd/systems-index.md` — EW0, W1-E0, W3-E1, W4-E1, W7-E1 : append séquentiel.
- `design/art/art-bible.md` — EW0-04, W1-E3, W2-E3, W4-E1, W6-E3 : or=XP verrouillé avant la monnaie.
- `src/classes/wave_director.gd` — W0-E3, W1-E4, W4-E4 : séquentiel.

## Premier sprint — 8 stories

| Story | Epic | Propriétaire | Pourquoi |
|---|---|---|---|
| Squelette conforme au template | EW0-01 | `narrative-director` | Remplace le concept périmé ; débloque tous les GDD. |
| Vendoriser gdUnit4 6.2.2 | W0-E1 | `devops-engineer` | Sans addon, aucune preuve ne peut exister. |
| Porter verify_facing | W0-E2 | `lead-programmer` | La suite portée protège le refactor W0-E3. |
| RunConfig + catalogue par énumération | W0-E3 | `lead-programmer` | Sort les données de `main.gd` sans recréer un registre partagé. |
| Unlock + id stable dans EnemyData | W0-E3 | `gameplay-programmer` | Retire le piège `display_name` avant que W1 ajoute cinq ennemis. |
| Standard « né localisé » | W8-E1 | `localization-lead` | Chaque nouvel ennemi/arme/écran naîtra localisé. |
| Pitch et Core Identity adossés au build | EW0-02 | `game-designer` | Fige les trois piliers qui arbitrent chaque décision. |
| Rouge puis vert (exit 100) | W0-E1 | `qa-lead` | Prouve que la suite peut échouer. |

## Points fragiles

- **W3 et W5 n'ont pas eu leur chef de département.** Le producteur les a reconstruits depuis le brief pendant la révision. Ils doivent être redécoupés par `game-designer` et `audio-director` avant la phase 8.
- **La boutique arrive en phase 13–14**, après les armes et les ennemis. Le directeur créatif voulait une tranche plus tôt ; ordre assumé par le chef d'équipe, réversible sur demande.
- **gdUnit4 doit être vendorisé depuis GitHub.** Si le réseau est indisponible au moment de W0-E1, on s'arrête et on rapporte — on n'invente pas un harnais.
