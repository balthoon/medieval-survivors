# Game Concept: The Conductor

*Created: 2026-11-09*
*Status: Draft*

---

## Elevator Pitch

> C'est un survivor-like où vous dirigez un orchestre invisible dans une arène
> médiéval-fantasy : lancer un sort sur le temps fait monter un crescendo, et la
> musique elle-même devient votre arme.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Survivor-like / horde arena + action rythmique |
| **Platform** | PC (Steam / Epic) |
| **Target Audience** | Achievers / Competitors — axes *Action-Excitement* et *Mastery* |
| **Player Count** | Solo |
| **Session Length** | 30-45 minutes |
| **Monetization** | Non décidée (prémium présumé) |
| **Estimated Scope** | Large (24-36 mois, solo) — cible retenue par le créateur le 2026-11-09. Le producteur estime 36-48+ mois. Voir Risks. |
| **Comparable Titles** | Brotato, Crypt of the NecroDancer, Metal: Hellsinger |

---

## Core Fantasy

Vous êtes un chef d'orchestre de bataille. L'orchestre est invisible, mais il
vous répond : chaque geste juste est repris, amplifié, chanté. Le fantasme n'est
pas « lancer des sorts puissants » — c'est **être écouté**. Le monde entier suit
votre tempo.

Dans Brotato, le joueur subit le rythme de la vague. Ici, il l'impose. C'est la
promesse émotionnelle qui justifie de choisir ce jeu plutôt que n'importe quel
autre survivor-like.

---

## Unique Hook

**Comme Brotato, et aussi un jeu où la partition orchestrale *est* la
mécanique** : lancer en mesure remplit un Crescendo, et au sommet le joueur
déclenche un *forte* — quelques secondes où tout se résout en double.

Le hook passe le test du « et aussi » : il se comprend en une phrase, il est
relié à la fantasy et pas soudé dessus comme un gadget, et il change le jeu, pas
seulement son habillage.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 2 | L'orchestre répond au geste : chaque coup en mesure ajoute une voix audible. |
| **Fantasy** | 4 | Le chef d'orchestre que le monde écoute. |
| **Narrative** | 6 | Un monde implicite, jamais raconté en cinématique (anti-pilier). |
| **Challenge** | 1 | Fenêtre rythmique qui se resserre, paliers de difficulté, courbe de maîtrise sans plafond. |
| **Fellowship** | N/A | Anti-pilier : pas de coop au lancement. |
| **Discovery** | 5 | Sorts et instruments à débloquer, synergies non documentées. |
| **Expression** | 3 | Combinaisons sorts x variations d'instrument ; la run ressemble à son joueur. |
| **Submission** | N/A | Anti-pilier : la tension rythmique est permanente. |

### Key Dynamics

Les comportements qui doivent émerger sans être enseignés :

- Cesser de viser la survie et commencer à viser la **propreté** d'une vague.
- Expérimenter des combinaisons d'instruments qu'aucun tutoriel ne mentionne.
- Rejouer une vague pour un seul temps raté.

### Core Mechanics

1. **Lancement verrouillé au rythme** — fenêtre « en mesure » généreuse au
   début, qui se resserre vague après vague.
2. **Crescendo -> Forte** — les sorts en mesure remplissent une jauge ; au
   sommet, une phrase de quelques secondes où tout se résout en double.
3. **Structure de mouvement composée** — squelette écrit à la main, plus des
   emplacements de variation tirés par graine depuis un pool restreint.
4. **Assemblage de build entre les vagues** — sorts x variations d'instrument,
   choisis en fin de vague.
5. **Partition adaptative** — musique livrée en stems séparés, avec une carte de
   rythme en données (voir Technical Considerations).

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Choix des sorts, des instruments, du placement, du risque (rester près du danger). | Core |
| **Competence** | Le timing est une courbe sans plafond et le jeu la *montre* : la fenêtre se resserre, c'est un échelon visible. | Core |
| **Relatedness** | Faible par nature. Compensée par **l'orchestre comme personnage** : une présence qui commente, juge et finit par reconnaître le joueur. Aucun dialogue — seulement du son et quelques marques visuelles. | Minimal, assumé |

### Player Type Appeal (Bartle)

- [x] **Achievers** — paliers, déblocages, maîtrise propre de chaque vague.
- [ ] **Explorers** — servis secondairement par les synergies non documentées.
- [ ] **Socializers** — non servis.
- [x] **Killers/Competitors** — classements de profondeur de run, paliers de difficulté.

### Flow State Design

- **Onboarding curve** : la fenêtre large des premières vagues enseigne le geste
  sans jamais le punir. On ne meurt pas d'un hors-mesure, on gagne moins vite.
- **Difficulty scaling** : la fenêtre se resserre. En complément — densité et
  superposition des voix à suivre, et pression par le **silence** (retirer le
  repère audible). **Aucun levier numérique.**
- **Feedback clarity** : chaque coup en mesure ajoute une voix audible à
  l'orchestre — le joueur *entend* sa propre progression.
- **Recovery from failure** : mort -> relance immédiate, sans écran de fin long.
  L'échec est une information sur un temps raté, pas une punition.

---

## Core Loop

### Moment-to-Moment (30 seconds)

Un danger s'annonce — d'abord au son, ensuite à l'œil. On se replace, on lit la
mesure, on lance sur le temps. L'attaque se verrouille dans la partition, une
section de cordes s'ajoute, l'ennemi tombe.

Le plaisir est la **synchronisation** : le son de l'action *est* dans la
partition. C'est ce qui rend l'action satisfaisante en elle-même — pas les
dégâts, le fait que le monde chante avec vous.

### Short-Term (5-15 minutes)

Les sorts en mesure remplissent le Crescendo. Au sommet, le *forte* : une phrase
de quelques secondes où tout se résout en double. Entre les vagues, on choisit
un sort ou une variation d'instrument.

Le « encore une » naît d'une erreur comprise : on est mort sur un temps raté
qu'on sait corriger.

### Session-Level (30-45 minutes)

Trois **mouvements** de 8 à 10 vagues, chacun avec son tempo, son instrumentation
et son thème d'ennemis. Points d'arrêt naturels aux frontières de mouvement. Le
rappel entre sessions : un sort débloqué, un palier de difficulté ouvert.

### Long-Term Progression

Trois axes :

1. La maîtrise du joueur — la fenêtre se resserre, c'est un échelon visible.
2. Le déblocage de sorts et d'instruments par jalons (exempté du pilier 2).
3. Des paliers de difficulté qui recomposent les mouvements.

Le jeu est « fini » quand le dernier mouvement tombe au palier le plus haut.

### Retention Hooks

- **Curiosity** : sorts et instruments non encore vus.
- **Investment** : déblocages acquis.
- **Social** : aucun — assumé.
- **Mastery** : le prochain temps propre, le prochain palier.

---

## Game Pillars

### Pillar 1: La musique est la mécanique

Aucun système n'existe sans contrepartie sonore ; le son informe, il ne décore
pas.

*Design test* : Son ou lisibilité ? -> **La lisibilité (P5) est le plancher
incompressible ; le caractère sonore (P1) s'optimise au-dessus de ce plancher.**

### Pillar 2: Le timing est la compétence

La progression du joueur **en course** passe par la précision, pas par les
chiffres. Les déblocages par jalons entre les runs sont exemptés.

*Design test* : Récompenser la précision ou le volume de sorts ? -> **La
précision.**

### Pillar 3: La pression monte en mesure

La difficulté vient du resserrement de la fenêtre rythmique, pas de l'inflation
des points de vie.

*Design test* : Ennemi plus résistant ou tempo plus exigeant ? -> **Le tempo.**
Leviers autorisés à monter avec lui : densité et superposition des voix à
suivre ; pression par le silence. Aucun levier numérique.

### Pillar 4: Une run est une partition

Chaque run a une structure composée et lisible — mouvements, thèmes, silences —
pas un sac de vagues.

*Design test* : Aléatoire ou composé ? -> **Composé, avec variation contrôlée**,
définie comme : un squelette de mouvement écrit à la main, plus des emplacements
de variation tirés par graine depuis un pool restreint propre au thème du
mouvement.

### Pillar 5: Ça s'entend avant de se voir

Chaque danger a une signature sonore qui précède sa manifestation visuelle.

*Design test* : Beau ou signalétique dans le doute ? -> **Signalétique.**
Priorité déclarée sur P1.

### Anti-Pillars (What This Game Is NOT)

- **PAS de narration lourde** (cinématiques, dialogues) : elle casserait la
  boucle courte d'une run. Les silences sont des temps structurels, pas des
  scènes.
- **PAS de builds purement numériques** : elles videraient le pilier 2.
- **PAS de coop au lancement** : elle compromettrait le finissage d'un premier
  jeu.
- **PAS de génération procédurale totale des mouvements** : elle dissoudrait le
  pilier 4.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **Brotato** | La boucle arène courte, le shop entre vagues, la lisibilité d'une run. | La musique est la mécanique et la difficulté, pas un fond sonore. | Prouve que la boucle tient en solo, à petite échelle. |
| **Crypt of the NecroDancer** | Le rythme comme contrainte dure, jouable et apprenable. | On ne déplace pas au temps ; on *lance* au temps. Le déplacement reste libre — la contrainte porte sur la décision, pas sur le geste de survie. | Prouve qu'un roguelike rythmique peut être profond. |
| **Metal: Hellsinger** | Le tir en mesure et la montée de puissance par la musique. | Fantasy médiévale, 2D, et une structure de run composée plutôt qu'un couloir. | Prouve que « tirer en rythme » est immédiatement grisant. |
| **Hades** | La lisibilité de la structure de run et la brièveté de la relance. | Aucune narration ; l'orchestre remplace les personnages. | Prouve que la maîtrise seule soutient des dizaines d'heures. |

**Non-game inspirations** : l'enluminure médiévale et l'encre de noix de galle
(direction visuelle) ; le geste du chef d'orchestre — battue, crescendo,
silence ; les cues d'action de partition de film, qui tiennent un pouls strict
sous une texture dense.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-40 |
| **Gaming experience** | Mid-core à hardcore |
| **Time availability** | Sessions de 30-45 min en semaine, plus longues le week-end |
| **Platform preference** | PC, clavier-souris ou manette |
| **Current games they play** | Brotato, Vampire Survivors, Hades, Crypt of the NecroDancer |
| **What they're looking for** | Un survivor-like qui demande autre chose que du positionnement passif ; une raison de rejouer la même vague. |
| **What would turn them away** | La bande-son comme barrière d'accessibilité ; un jeu qu'on ne peut pas jouer en écoutant un podcast — ce qu'on assume et qu'on traite par l'accessibilité visuelle. |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | **NON DÉCIDÉ** — `/setup-engine` tranchera. Dimensions à classer selon ce concept : contrôle de latence audio et audio adaptatif ; ergonomie 2D + shaders custom ; instanciation de horde. |
| **Key Technical Challenges** | Latence audio/visuelle ; partition en stems ; carte de rythme en données ; shader d'encre humide ; densité x VFX à 60 fps. |
| **Art Style** | 2D — aplats d'encre sur vélin, palette de cinq couleurs. |
| **Art Pipeline Complexity** | Moyenne — 2D custom + un shader propriétaire. |
| **Audio Needs** | Très lourds / adaptatifs — c'est le poste de risque n°1. |
| **Networking** | Aucun. |
| **Content Volume** | 3 mouvements x 8-10 vagues, 25-30 sorts, 6-8 variations d'instrument, 10-12 ennemis, 3 boss, ~20-30 h de complétion. |
| **Procedural Systems** | Emplacements de variation par graine uniquement. Rien d'autre. |

### Contraintes de pipeline musical

Non négociables, et à arrêter **avant la première note** :

1. Musique livrée **en stems séparés** (percussions / cordes / basses / cuivres).
   C'est la condition des leviers du pilier 3 ; ce n'est pas rétrofitable depuis
   un mix final — ce serait une recomposition.
2. **Grille stricte** : pas de rubato, pas de swell de tempo en cours de vague,
   BPM fixe par vague. Changement uniquement aux frontières de mouvement.
3. **Carte de rythme en données** (BPM, mesures, points de télégraphe), découplée
   du fichier audio. C'est ce qui rend « la partition est le jeu » lisible par le
   code.
4. **Bus séparés** musique / télégraphes, avec ducking par sidechain, et
   télégraphes composés dans une bande de fréquence laissée libre par la
   partition.

---

## Visual Identity Anchor — Manuscript

**Règle visuelle en une ligne** : *le monde est écrit — l'arène est une
partition, tout ce qui s'y trouve est de l'encre.*

**Principe 1 — la portée est un lieu, pas un décor.** Le sol de vélin porte des
mesures réglées à la main ; le temps a une position physique à l'écran, sans
surcouche d'interface.
*Design test* : HUD de rythme ou portée au sol ? -> **Portée au sol.**

**Principe 2 — l'encre doit rester humide.** Les gestes du joueur peignent des
arcs d'encre qui sèchent et deviennent la structure de la mesure suivante. Rendu
par shader (diffusion, bavure, séchage), jamais image par image.
*Design test* : animation dessinée ou shader ? -> **Shader.** Sans encre humide,
la direction devient un jeu de plateau en carton.

**Principe 3 — la couleur est rationnée.** Le vermillon est le seul à signifier
« ça arrive » ; l'or n'existe qu'au multiplicateur maximal.
*Design test* : ajouter une couleur pour la variété ou la retenir ? -> **La
retenir.**

**Colour philosophy** — Parchemin crème (le sol, le neutre) · Encre de fer
(structure, environnement) · Vermillon (menace entrante — la rubrication
médiévale était littéralement la marque de l'attention) · Lapis (votre magie,
votre agentivité) · Or (le sommet, visible uniquement au pic du crescendo).

**Règle d'accessibilité transversale** — La couleur peut nommer une menace, mais
**la forme ou le mouvement doit aussi la nommer**. Jamais de codage par la seule
couleur.

---

## Risks and Open Questions

### Design Risks

- Un seul levier de difficulté a un plafond : une fenêtre qui se resserre finit
  illisible. Traité par les leviers compagnons du pilier 3, mais la courbe réelle
  reste à régler.
- La tension permanente peut épuiser sur des sessions longues.
- La marge de builds est plus étroite que dans un survivor classique.

### Technical Risks

- **La latence est le risque n°1** : les pilotes audio PC sont hors de contrôle.
  Mitigation dès le premier prototype — calibration, indicateurs visuels du
  temps, jamais l'audio comme unique canal.
- Le pipeline musical (stems, grille stricte, carte de rythme) est un travail
  d'ingénierie à part entière, comparable à la charge de programmation.
- Le shader d'encre humide est un risque de calendrier silencieux pour un
  premier projet.

### Market Risks

- Niche dans une niche : les joueurs de Brotato ne veulent pas forcément du
  rythme, ceux de NecroDancer pas forcément du survivor. C'est aussi ce qui rend
  le jeu identifiable.

### Scope Risks

**Écart connu et assumé.** Le créateur retient 24-36 mois pour la vision
complète ; le producteur (PR-SCOPE, 2026-11-09) rend **OPTIMISTIC** et estime
**36-48+ mois**, en proposant de faire du palier de repli la cible v1.0. Les
réglages de périmètre ont été présentés et refusés le 2026-11-09. Le MVP est
estimé à 1 semaine par le créateur, 2-3 semaines par le producteur.

C'est le point de vigilance n°1 du projet. **Recommandation : rejouer PR-SCOPE
après la décision moteur et le MVP**, quand l'estimation reposera sur une
vélocité mesurée plutôt que sur une supposition.

### Open Questions

1. *Le geste en mesure est-il agréable ?* -> MVP, fenêtre volontairement large.
2. *Le shader d'encre humide est-il tenable pour un premier projet ?* -> spike
   visuel d'une semaine.
3. *La horde tient-elle 60 fps sur machine minimale avec le shader actif ?* ->
   spike densité, séparé du MVP.
4. *Un télégraphe reste-t-il audible sur le passage orchestral le plus dense ?*
   -> vague de test dédiée.

---

## MVP Definition

**Core hypothesis** — On ne teste qu'une chose : *lancer en mesure est-il
agréable ?*

**Required for MVP** — 1 mouvement · 6 vagues · 5 sorts · 3 ennemis · encre de
remplissage · fenêtre volontairement large · détection du temps, Crescendo et
forte.

**Explicitly NOT in MVP** — méta-progression, boss, musique définitive, art
final, shader d'encre complet.

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 mouvement, 6 vagues | Boucle cœur seule, jetable | 1 semaine (cible créateur) / 2-3 semaines (producteur) |
| **Vertical Slice** | 1 mouvement complet | Cœur + progression | À estimer après le MVP |
| **Palier de repli** | 1 mouvement poli, 8 sorts, 4 ennemis, 1 boss | Mode difficulté infini, quatuor à cordes | Vendable — le producteur recommande d'en faire la v1.0 |
| **Full Vision** | 3 mouvements, 25-30 sorts, 6-8 instruments, 10-12 ennemis, 3 boss | Tout, poli, OST orchestrale | 24-36 mois (cible) / 36-48+ (estimation) |

---

## Next Steps

- [ ] `/setup-engine` — choisir et configurer le moteur (dépendance du MVP)
- [ ] `/prototype` — MVP : le lancement en mesure est-il agréable ?
- [ ] Spike visuel — le shader d'encre humide est-il tenable ?
- [ ] `/art-bible` — identité visuelle, avant tout GDD
- [ ] `/design-review design/gdd/game-concept.md`
- [ ] `/map-systems` puis `/design-system` — un GDD par système
- [ ] `/create-architecture` puis `/architecture-decision`
- [ ] `/architecture-review`, `/gate-check`
