# Game Concept: Medieval Survivors

*Créé : 2026-11-09*
*Statut : Verrouillé — porte Concept PASSED (EW0-05) ; phase 1 quasi close (W0-E3 en cours)*
*Remplace : The Conductor (pivoté ; prototype archivé dans `prototypes/the-conductor-concept/`)*
*Propriétaires : `narrative-director` (document, fiction, ton) + `game-designer` (identité, piliers, boucles) ; visuel : `art-director` ; portée : `producer`.*

> **Règle de lecture.** Ce document décrit le jeu **tel qu'il est construit** et **tel qu'il doit devenir**. Chaque affirmation sur le build est vérifiée dans `data/` ou `src/` ; les éléments cibles sont marqués **« cible W# »**. Aucun contenu n'est annoncé comme existant s'il ne l'est pas. Chemins et identifiants restent en anglais ; le document est en français.

---

## Elevator Pitch

> Medieval Survivors est un survivor-like médiéval de poche : dix vagues de vingt secondes dans une arène dessinée à l'encre, jusqu'à trois armes portées à la fois, des montées de niveau fréquentes — et un seigneur squelette qui revient au milieu puis à la fin du conte. Une run dure quelques minutes, pensée pour que chaque décision compte.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Survivor-like / horde arena, action 2D top-down |
| **Platform** | PC (Windows) — Godot 4.7.2, viewport 1280×720 (`canvas_items`, `keep`) |
| **Target Audience** | Joueurs de survivor-like mid-core, sessions courtes |
| **Player Count** | 1 |
| **Session Length** | 20–30 min (3–5 runs ; cible de run 4–8 min) |
| **Monetization** | Non décidée — prémium présumé, aucun système F2P prévu |
| **Estimated Scope** | Small. **Acquis** : 1 arène, 1 classe, 4 armes, 3 marcheurs + 1 boss, 12 équipements, 5 stats, 10 vagues. **Cible MVP (W9-E1)** : 3 classes, 10 armes, 6 ennemis / 5 comportements, 1 archétype de boss (2 rencontres). Calendrier détenu par `producer`. |
| **Comparable Titles** | Brotato, Vampire Survivors, Megabonk |

---

## Core Fantasy

Vous êtes une silhouette d'environ 30 px de haut dans une arène de conte. La page se remplit de créatures dessinées ; le boss annonce son slam d'un disque de danger, et **W1** étend cette annonce à chaque comportement. Le fantasme n'est pas d'effacer la page d'un coup — c'est de **lire** assez vite pour **répondre** avec un arsenal que vous avez assemblé vous-même, et de tenir jusqu'à ce que le Seigneur referme le livre.

Ce que le joueur ressent, dans l'ordre : la lisibilité (je comprends ce qui m'arrive), la compétence (j'ai esquivé parce que j'ai lu), l'expression (ce build est le mien), la tension (la page se termine). Ce n'est pas un fantasme de puissance brute : c'est un fantasme de **clarté**.

---

## Unique Hook

**Pas de hook mécanique inventé.** Le jeu est un survivor-like ; il ne revendique pas un verbe que Brotato n'a pas. La différence se joue dans l'exécution, sur trois axes mesurables — deux sont encore des cibles :

1. chaque run propose des décisions différentes (espace de décision, pas volume de contenu) — **acquis** : offres pondérées et tirage aléatoire à chaque run ;
2. chaque ennemi pose une question lisible avant d'agir — **cible W1** ; aujourd'hui seul le boss télégraphie (disque de 0,85 s) ;
3. chaque level-up et chaque achat change une décision, pas seulement un chiffre — **cible W2/W4** ; les stats pures restent une part des offres et la boutique n'existe pas encore.

La signature visible est la direction **« encre de conte »** : une arène et des acteurs dessinés au trait, pas des pixels. Elle rend le jeu reconnaissable ; elle ne remplace pas un hook.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 3 | Trait d'encre, hitstop, secousses, nombres de dégâts, 8 SFX (musique en W5) |
| **Fantasy** | 4 | Le chevalier de marge dans une page qui se referme |
| **Narrative** | N/A | Fiction minimale : noms, silhouettes, couleurs ; aucune cinématique |
| **Challenge** | 1 | Lire les silhouettes et les annonces (boss aujourd'hui ; W1 pour les autres), se placer, construire ; pas de ciblage manuel |
| **Fellowship** | N/A | Solo assumé, aucun coop au lancement |
| **Discovery** | 5 | Combinaisons armes/équipements/stats ; déblocages (W7) ; nouveaux ennemis (W1) |
| **Expression** | 2 | 3 armes + 6 emplacements + stats ; classe en W3 : chaque run ressemble à son joueur |
| **Submission** | N/A | Anti-pilier : pas de mode contemplation, chaque vague demande une décision |

### Key Dynamics

- Lire la silhouette et, au boss, le disque de danger, puis se placer avant que l'annonce ne se résolve — **W1** étend l'annonce aux cinq comportements.
- Refuser « +20 % dégâts » quand une arme change la façon de jouer : aujourd'hui par sa portée, sa cadence ou son arc ; **W2** ajoute une mécanique propre par arme.
- Garder la monnaie de run pour la vague 5, puis pour la vague 10 — **cible W4** : aucune monnaie de run n'existe dans le build.
- Relancer immédiatement après une mort pour tester un autre build — « MORT — R pour recommencer ».
- Comparer son record et viser un déblocage précis — **cible W7** : ni record ni déblocage dans le build.

### Core Mechanics

1. **Arsenal automatique** — jusqu'à 3 armes, chacune avec son cooldown et sa cible ; visée automatique sur l'ennemi vivant le plus proche ; **pas de ciblage manuel** (décision verrouillée).
2. **Horloge de vagues** — 10 vagues × 20 s ; intervalle de spawn 1,4 s × 0,88 par vague, plancher 0,22 s ; max vivant 18 + 6 par vague ; boss aux vagues 5 et 10.
3. **XP et montée de niveau** — gemmes dorées, XP uniquement (pas une monnaie) ; coût 5 + 4 × (niveau − 1) ; 3 offres (stat / arme / équipement) ; 2 rerolls, +1 aux niveaux 10 et 20 ; poids arme 1,4, équipement 0,9 × poids de rareté.
4. **Boss et butin** — Seigneur squelette, barre dédiée, slam télégraphié 0,85 s (rayon 96, 22 dégâts, cooldown 4,5 s) ; panneau « Butin du boss » à sa mort, pondéré arme 3,0 / équipement 2,5.
5. **Économie de run et méta** — **cible W4/W7**, absentes du build : monnaie de run non dorée et achats entre les vagues (W4) ; record, 4–6 déblocages et choix de départ (W7).

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | 3 choix au level-up et 2 rerolls (+1 aux niveaux 10 et 20), armes/équipements, boutique (W4), classe et choix de départ (W7) | Core |
| **Competence** | Lire les annonces et se placer ; la visée étant automatique, la compétence est le placement et le build, pas la précision de souris | Core |
| **Relatedness** | Faible par nature : solo, aucun PNJ, aucun compagnon. La page est un cadre, pas un personnage. | Minimal, assumé |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — record (W7), déblocages (W7), victoire par classe (W3).
- [x] **Explorers** — combinaisons entre armes, équipements et stats ; contenu non encore rencontré.
- [ ] **Socializers** — non servis.
- [x] **Killers/Competitors** — compétition contre soi-même et le record (W7) ; pas de PvP ni de classement en ligne.

### Flow State Design

- **Onboarding curve** : les vagues 1 à 5 introduisent squelette (index 0), loup (index 2) et orc (index 4) à densité lisible ; le premier level-up vise la vague 1 (coût XP 5 : cinq squelettes).
- **Difficulty scaling** : cadence de spawn, plafond d'ennemis vivants et paliers de boss. Les nouveaux comportements ajoutent des questions, pas seulement des points de vie.
- **Feedback clarity** : silhouettes, nombres de dégâts, barre de boss, chrono de vague, hitstop et secousses ; annonces du boss aujourd'hui, des cinq comportements en W1.
- **Recovery from failure** : mort → « MORT — R pour recommencer » ; une run dure 4–8 min (cible) ; aucun écran de fin long.

---

## Core Loop

### Moment-to-Moment (30 seconds)

Lire les silhouettes, se déplacer, laisser les armes automatiques travailler, ramasser les gemmes, esquiver les corps et — aux vagues 5 et 10 — le disque de danger. Le plaisir immédiat est double : **comprendre** ce que la page s'apprête à faire, et **sentir** le build répondre (impact, hitstop, nombre qui monte). Le build actuel porte cette boucle avec 8 SFX et aucune musique ; W5 ajoutera la musique par état.

### Short-Term (5–15 minutes)

Une run : 10 vagues, des montées de niveau fréquentes, un premier boss à la vague 5 avec son butin, un second affrontement à la vague 10, puis la victoire ou la mort. C'est ici que vit le « encore une » : une erreur comprise, un build à retester. **W1** ne change ni l'arène ni les dix vagues : il remplace les trois marcheurs par cinq comportements — même cadre, questions différentes.

### Session-Level (20–30 minutes)

Trois à cinq runs. Le joueur essaie une classe (W3), un axe d'armes (W2), une dépense (W4). La session se termine sur un record ou un déblocage (W7), pas sur un écran de fin.

### Long-Term Progression (meta)

**Cible W7** : record, 4–6 déblocages, choix de départ. Pas de conversion des trophées en puissance permanente. La marge se souvient, elle n'arme pas. Deux runs consécutifs doivent différer à cause du premier — c'est le critère d'acceptation du plan.

### Retention Hooks

- **Curiosity** : armes, équipements et ennemis non encore vus (contenu actuel + W1/W2).
- **Investment** : déblocages et record (W7).
- **Social** : aucun — assumé.
- **Mastery** : lire plus vite, construire mieux, battre le boss 1 avec chaque classe (W3).

---

## Game Pillars

### Pillar 1 : Chaque run est différent

La variété n'est pas du volume de contenu, c'est de l'**espace de décision**. Mêmes armes, mêmes ennemis, même ordre = le joueur s'arrête au bout de trois runs. **Acquis** : les offres sont tirées au hasard à chaque niveau, donc deux runs ne proposent pas les mêmes choix.

*Design test* : ajouter un ennemi qui ne pose pas de nouvelle question, ou ajouter une décision ? → **La décision.** Corollaire : une arme qui ne change qu'un chiffre n'est pas du contenu ; les quatre armes actuelles sont retrofitées en W2.

### Pillar 2 : Chaque ennemi pose une question différente

Un comportement, une silhouette, une annonce. Le joueur doit pouvoir nommer ce que l'ennemi s'apprête à faire avant qu'il le fasse. **État** : le boss télégraphie déjà son slam (0,85 s) ; les trois marcheurs se lisent à leur silhouette, et **W1** doit donner une annonce aux cinq comportements.

*Design test* : ennemi plus rapide ou ennemi qui demande une autre réponse ? → **L'autre réponse.** Un ennemi sans annonce lisible n'est pas fini.

### Pillar 3 : Le joueur a toujours un choix qui compte

Entre les vagues (boutique W4), pendant une vague (placement, quand ramasser, où attirer la horde), au level-up (3 offres + 2 rerolls), au départ (classe W3, choix de départ W7).

*Design test* : « +20 % dégâts » ou une mécanique qui change la run ? → **La mécanique.** Pas de ciblage manuel : le choix porte sur le build et le placement, pas sur la visée — la visée reste automatique sur l'ennemi le plus proche, comme décidé.

### Anti-Pillars (What This Game Is NOT)

- **PAS « plus de contenu » comme réponse à la variété** : le volume ne remplace pas l'espace de décision.
- **PAS d'armes ou d'objets purement numériques** : chaque arme doit avoir une mécanique propre. Règle cible : les quatre armes du build sont encore des variantes de chiffres, retrofitées en W2.
- **PAS de ciblage manuel** : la visée automatique reste ; le troisième pilier est porté par le placement, le level-up (3 offres + rerolls) et la boutique (W4).
- **PAS de puissance permanente achetée par la méta** : record + déblocages + choix de départ seulement (W7).
- **PAS d'or comme monnaie de run** : l'or reste réservé à l'XP — les gemmes dorées sont de l'XP, jamais une monnaie.
- **PAS de narration lourde** : pas de cinématiques, pas de dialogues, pas de lore qui interrompt une vague de 20 s.
- **PAS de nouvelle arène ou biome au lancement** : une arène dessinée une fois, lisible ; la variété vient des ennemis et des offres.

---

## Inspiration and References

Références de positionnement, pas des chiffres de marché : aucune donnée de ventes ou de part de marché n'est revendiquée ici.

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **Brotato** | Vagues courtes, boutique entre vagues, lisibilité d'une run | Run bornée à 10 vagues et télégraphes lisibles (W1) ; notre boutique (W4) est une décision, pas un catalogue | Prouve que la boucle tient en solo et en sessions courtes |
| **Vampire Survivors** | Horde, attaque automatique, gemmes d'XP, montée de niveau | 10 vagues bornées, pas d'endless ; des silhouettes lisibles et des annonces (W1), pas un tapis | Prouve que l'auto-attaque laisse la place au placement et au build |
| **Megabonk** | Arène herbeuse lisible, foule qui se lit | 2D à l'encre, pas de 3D ; une arène fixe | Prouve qu'une arène unique peut porter un jeu |
| **Enluminure médiévale et illustration de conte à l'encre** (non-jeu) | Silhouettes, palette rationnée, marges, trait | — | Donne au jeu sa signature visuelle et son lexique |

---

## Target Player Profile

Profil cible dérivé des références ci-dessus — hypothèses de cadrage, pas une étude de marché.

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16–45 |
| **Gaming experience** | Mid-core |
| **Time availability** | Sessions de 20–30 min en semaine |
| **Platform preference** | PC, clavier au lancement ; manette en W6-E3 (différée derrière les piliers) |
| **Current games they play** | Brotato, Vampire Survivors, Megabonk |
| **What they're looking for** | Des runs courtes avec de vraies décisions de build et des morts lisibles |
| **What would turn them away** | Des télégraphes illisibles, du grind de puissance permanente, des runs longues, de la visée intensive |

---

## Minimal Fiction — Le Conte

> **Statut (EW0-05) : ratifié canon.** Le cadre « Le Conte / la page / la marge » n'est écrit nulle part dans le build : aucune chaîne joueur ne le nomme. Ce qui est acquis et vérifiable : l'arène est une clairière d'herbe cernée d'un trait d'encre, sur un fond de papier chaud ; les noms des ennemis et du boss ; les silhouettes ; la structure dix vagues et deux rencontres. Le cadre nomme cette structure sans lui ajouter de mécanique — il est ratifié comme fiction de référence, cohérent avec l'ancre « encre de conte » déjà verrouillée. Ratifier le cadre ne déclenche aucune réécriture de chaîne joueur : le build continue de dire « VAGUE ». La règle « un seul mot pour une run » se résout sur « la page » ; « la veillée » reste une variante de prémisse, pas un terme joueur.

### Prémisse

**Le monde est une page.** Ce qui y est dessiné vit ; ce qui est raturé revient. L'arène est une clairière tracée à l'encre sur une page de conte — le vélin affleure hors de ses bords (le fond chaud du viewport, derrière le cadre d'encre). Le chevalier est une figure de marge, la seule que le build dessine ; les deux autres classes (cible W3) devront être des figures de la même page, pas une autre histoire. Chaque run est une **veillée** : une page qu'on traverse avant que le Seigneur ne la referme.

Mourir, c'est déchirer la page ; R, c'est la redessiner. La marge garderait la trace de ce qu'on a déjà dessiné — cible W7, rien de tel dans le build.

### Les dix vagues

Dix **strophes** de 20 secondes — « vagues » dans le build —, soit 200 secondes de lecture. La structure est celle d'un conte court :

| Vagues | Fonction |
| ---- | ---- |
| 1–2 | Installation : la page, la horde, la première montée de niveau |
| 3–4 | Montée : un nouvel ennemi entre à la vague 3 (le loup, rapide et fragile) ; la diversification des comportements est une cible W1 |
| 5 | Épreuve du milieu : le premier Seigneur et la seule annonce télégraphiée du build (0,85 s) |
| 6–7 | Approfondissement : le build se précise |
| 8–9 | Ascension : la densité monte |
| 10 | Dernière page : le Seigneur revient, la page ne se ferme que s'il tombe |

**Pourquoi dix.** Assez pour une dizaine de décisions et deux affrontements de boss, assez court pour qu'une run se lise d'une traite, assez long pour qu'une session de 20 minutes contienne plusieurs runs. L'horloge de vague est le temps de lecture : quand la dernière page est lue, le livre ne se ferme que si le Seigneur est tombé — d'où la condition de victoire (chrono de la dernière vague écoulé **et** boss mort). Le build attend aussi que le panneau de butin ouvert par le boss soit refermé avant d'afficher la victoire — vérifié.

### Les deux boss

**Ratifié (EW0-05)** : un seul archétype (`seigneur_squelette.tres`), deux rencontres pour la v1.0 ; un second boss **distinct** est une décision de portée, hors MVP (Open Questions 4 résolue).

- **Vague 5 — le Seigneur vient voir.** Palier 0. Il enseigne le slam : disque de danger de 0,85 s, rayon 96, 22 dégâts, cooldown 4,5 s, résistance au recul 0,85. Le boss est immobilisé pendant l'annonce : c'est une vraie fenêtre d'esquive.
- **Vague 10 — le Seigneur revient, couronné par la fin.** Palier 1 : PV ×1,9, dégâts ×1,35 (+0,9 PV et +0,35 dégâts par palier). Le palier est piloté par `data/run_config.tres` depuis W0-E3 — plus de constante en dur dans `main.gd`. Même ressource, même silhouette ; c'est le même personnage, pas un nouveau.

**Pourquoi ça tient.** L'antagoniste d'un conte revient au milieu et à la fin. La première visite apprend l'annonce ; la seconde demande de l'appliquer sous la pression de la dernière page, avec un build. Le build affiche le même nom aux deux rencontres ; nommer la seconde est une question ouverte. Le Conte a de la place pour une autre page, mais l'ajouter est une décision de portée, pas une dette de fiction.

### La marge (méta)

**Cible W7** : le record, 4–6 déblocages et le choix de départ sont des marques dans la marge — fiction proposée pour porter la méta ; le build n'a ni record ni déblocage. Aucune conversion des trophées en puissance permanente. La marge se souvient, elle n'arme pas.

### Règles de la fiction

- Pas de dialogue, pas de cinématique, pas de dump de lore : la fiction vit dans les noms, les silhouettes et les couleurs ; une phrase de cadre reste possible mais n'existe pas dans le build.
- Pas de système de magie à expliquer, pas de panthéon à nommer, pas de carte.
- La page ne s'adresse jamais au joueur en tant que joueur : pas de quatrième mur. Les chaînes fonctionnelles (« MORT — R pour recommencer », « VAGUE 5 · BOSS ») sont de l'UI, pas de la fiction, et n'ouvrent pas le quatrième mur.
- La lisibilité prime toujours : si un nom ou une couleur rend une menace plus difficile à lire, la lisibilité gagne.
- Tout ce qui n'est pas nécessaire à la boucle est coupé.

---

## Bestiary Framework

### La règle

**Un comportement = une question = une silhouette = une annonce** — règle **cible W1**, pas encore celle du build. Un nouvel ennemi est une nouvelle question, pas une nouvelle barre de vie. Aucune silhouette ne peut être confondue avec une existante à 100 % sur l'herbe.

Le build ne satisfait pas encore cette règle : ses trois marcheurs ne diffèrent que par la silhouette, la vitesse, les PV et les dégâts de contact ; aucun n'a d'annonce. Seul le boss télégraphie.

### Le roster du build actuel

Tous les archétypes actuels **marchent vers le joueur et infligent des dégâts de contact** ; le boss ajoute le slam. Les valeurs de combat sont dans `data/enemies/` et restent réglables ; les vagues de déblocage, elles, sont codées en dur dans `src/systems/spawner.gd` (`_UNLOCK_WAVES`, clé = `display_name` en minuscules) et devront sortir en W0-E3.

| Ennemi | Comportement | PV | Vitesse | Contact | XP | Apparition |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| Squelette | Marcheur | 20 | 70 px/s | 8 | 1 | dès la vague 1 (index 0) |
| Orc | Marcheur | 56 | 55 px/s | 14 | 2 | dès la vague 5 (index 4) |
| Loup maudit | Marcheur → **chargeur en W1** | 8 | 130 px/s | 6 | 1 | dès la vague 3 (index 2) |
| Seigneur squelette | Boss + slam | 480 | 42 px/s | 16 | 30 | vagues 5 et 10 |

### Le roster cible (W1)

**Cible W1** — cinq comportements, six ennemis (trois existants + trois nouveaux). Le loup devient le chargeur ; aucun de ces ajouts n'existe dans le build.

| Rôle | Question posée | Silhouette | Annonce | Statut |
| ---- | ---- | ---- | ---- | ---- |
| **Marcheur** | Sais-tu kiter ? | Squelette étroit ; orc large | La masse qui avance | Build : squelette, orc |
| **Chargeur** | Sais-tu lire et esquiver ? | Loup : seul quadrupède, bas, sans cornes | Ligne tracée au sol + baisse du corps avant la charge | Build : loup (devient chargeur en W1) — **décision verrouillée** |
| **À distance** | Sais-tu fermer la distance ? | Fin, bâton, capuche | Tir télégraphié | Cible W1 |
| **Exploseur** | Sais-tu le tuer à temps ? | Rond, luisant | Lueur + accélération | Cible W1 |
| **Invocateur** | Sais-tu prioriser ? | Grand, encapuchonné | Cercle d'encre au sol | Cible W1 |

**Le loup chargeur.** C'est le seul quadrupède du roster — décision verrouillée ; sa silhouette porte l'annonce. La bible d'art (`design/art/art-bible.md`) et `ActorArt` décrivent deux oreilles courtes et larges, sans cornes : le build dessine le loup horizontal, à quatre pattes, museau long, queue latérale. **Décision EW0-04 : pas de cornes.** La charge est un comportement, pas une anatomie — le corps s'aplatit avant de partir, puis une ligne est tracée au sol le long de la trajectoire. Des cornes ajouteraient une marque verticale au seul profil horizontal du roster et feraient lire un bélier : de la masse, c'est-à-dire la mauvaise question pour une attaque qui s'esquive. La malédiction se lit dans la couleur : le loup est le seul gris froid d'un monde chaud.

**Annonces du roster cible.** Le plan W1-E1 prévoit quatre formes de télégraphe pour cinq comportements : la forme de l'annonce du marcheur reste à trancher en W1-E0.

**Noms de travail des futurs ennemis** (propositions pour W1-E0, non canon — aucun n'existe dans `data/`) : **la Plume** (à distance), **la Tache** (exploseur), **le Copiste** (invocateur).

**Boss.** Un archétype (`seigneur_squelette.tres`, `is_elite = true`, `spawn_weight = 0`), deux rencontres. Il ne fait pas partie des six ennemis de horde : le spawner ignore tout `EnemyData` élite.

---

## Class Framework

### La règle

Une classe = un `ClassData` + une arme de départ + des stats + une **règle signature** (cible W3). Le `ClassData` actuel ne porte que `display_name`, `max_hp`, `move_speed` et l'arme de départ : ni id stable, ni règle signature. Une seule classe existe (`data/classes/chevalier.tres`). Une classe doit se jouer autrement dès la vague 1 et battre le premier boss avec une stratégie différente.

| Classe | Fantasy | Distance | Arme de départ | Signature | Statut |
| ---- | ---- | ---- | ---- | ---- | ---- |
| **Chevalier** | L'équilibre, la référence | Mêlée moyenne | Épée longue | À définir en W3-E1 | Build : 100 PV, 220 px/s |
| **Chasseresse** (proposition) | La distance, la mobilité | Loin | Arc court | À définir en W3-E1 | Cible W3 |
| **Pénitent** (proposition) | La masse, la patience | Mêlée lourde | Marteau | À définir en W3-E1 | Cible W3 |

### Notes de design

- Le chevalier est la classe qui enseigne l'arène. Les deux autres ne doivent pas être « le chevalier avec une autre arme ».
- **Pas de ciblage manuel** (décision verrouillée) : l'identité de la classe à distance vient de la portée, du comportement des projectiles, de la mobilité et du placement — pas de la visée.
- La classe lourde est lente, large, résistante, avec du recul ; sa question est « où est-ce que je me place quand je ne peux pas courir ? ».
- « Chevalier » est le nom du build ; « Chasseresse » et « Pénitent » sont des **propositions**. W3-E1 fige noms, stats et règles signature. L'écran de classe (W3-E4) se pilote au clavier et laisse une capture.
- Le choix de classe ferait partie du « choix de départ » de la méta (W7) ; l'inclusion de la classe dans ce choix reste à trancher (Open Questions 7). L'écran existe dès la tranche verticale (W9).

---

## Tone and Lexicon

> **Statut : proposition (fiction canon).** Ce lexique habille la fiction canon ratifiée en EW0-05 ; aucune de ces chaînes n'est affichée par le build. Le ton ne s'entend aujourd'hui que dans les libellés fonctionnels — il n'y a aucun texte narratif dans le build.

### Ton

Conte noir, sec, sans ironie. La page ne s'excuse pas. La violence est dessinée, pas graphique. Pas de dialogue, pas de cinématique, pas de quatrième mur, pas d'humour contemporain, pas d'exposition.

### Lexique

| Terme | Sens | À éviter |
| ---- | ---- | ---- |
| **le Conte** | Le monde et la run (fiction proposée) | « univers », « lore » en chaîne joueur |
| **la page** | Une run | « partie », « session » en fiction |
| **la veillée** | La run vécue comme une lecture (terme de la prémisse) | « run » en chaîne joueur |
| **la strophe** | Une vague | « round » ; le build dit « vague » |
| **la marge** | La méta (fiction proposée) | « profil », « compte » |
| **le trait** | Une attaque, un danger | « skill » |
| **le Seigneur** | Le boss | « boss » en chaîne longue |
| **le Butin** | Le loot de boss | « loot » en chaîne joueur |
| **Montée de niveau** | Level-up (existant) | « level up » |
| **Mort / Victoire** | Fins de run (existant) | — |

**Un seul mot pour une run.** « la page » et « la veillée » se recouvrent ; le lexique doit en retenir un comme terme joueur — question à trancher avec la fiction.

**Note de build — les chaînes réellement affichées.**

| Contexte | Chaîne du build | Écart avec le lexique |
| ---- | ---- | ---- |
| Bannière de vague | « VAGUE %d » puis « · BOSS » → « VAGUE 5 · BOSS » | « vague » au lieu de « strophe » ; « BOSS » est de l'anglais |
| Boss vaincu | « VAGUE n · VAINCU » | le lexique dit « le Seigneur » |
| Barre de boss | « SEIGNEUR SQUELETTE » (nom mis en capitales) | cohérent ; le lexique abrège en « le Seigneur » |
| Butin de boss | « Butin du boss » | « boss » en anglais dans une chaîne joueur |
| Mort | « MORT — R pour recommencer » | cohérent |
| Victoire | « VICTOIRE », « Niveau %d · %d vagues », « R pour recommencer » | « vagues » au lieu de « strophes » |
| Montée de niveau | « Montée de niveau », « Relancer — R (%d restantes) » | « Relancer » là où les docs disent « reroll » |

Le lexique préfère « SEIGNEUR » ou « ÉPREUVE » ; l'emploi de « BOSS » et de « boss » contredit l'interdit « anglais dans les chaînes joueur ». **Tranché en EW0-05 : « SEIGNEUR » / « ÉPREUVE », jamais « BOSS » / « boss ».** Le libellé exact des bannières est figé par `game-designer` + `narrative-director` en W1-E3, appliqué en W8-E2 (Open Questions 13 résolue).

### Interdits

Or comme monnaie de run ; mana ; vocabulaire militaire moderne ; jeux de mots ; quatrième mur ; dialogue ; cinématique ; anglais dans les chaînes joueur. « Boss » est de l'anglais et le build l'emploie encore dans deux chaînes — dette de lexique, pas exception. Les identifiants et chemins restent en anglais.

### Règles de nommage

Noms affichés en français ; ids et chemins en anglais `snake_case`. `display_name` n'est **pas** un identifiant stable : W0-E3 ajoute un id stable et un champ de déblocage à `EnemyData`. Aujourd'hui le spawner débloque par `display_name.to_lower()` et une table `_UNLOCK_WAVES` en dur dans `spawner.gd` : renommer un ennemi le fait réapparaître dès la vague 1, sans erreur — piège connu. « Squelette », « Loup maudit », « Orc » et « Seigneur squelette » sont donc des noms d'affichage, pas des clés.

---

## Visual Identity Anchor — Encre de conte

### La règle unique

**La silhouette d'abord.** Une créature non identifiable à son seul contour, en un coup d'œil, à 100 %, sur l'herbe, n'est pas finie. La couleur, l'ombrage et le détail viennent après. Deux archétypes ne partagent jamais un contour.

### Trait, tons et proportions

- Encre `#29241F` — jamais du noir pur. Contour **2 px** à 1×, détail intérieur **1 px** à 55 % d'encre, ombre au sol à 10–14 %.
- Trois tons + **un** accent par acteur ; lumière en haut à gauche.
- Proportions exprimées en fraction du `radius` ; les têtes lisent grand (~45 % de la largeur du corps).
- Le joueur fait **14 px** de rayon et reste la plus petite forme animée de l'écran, hors gemmes.
- Pas d'oscillation au repos, sauf le joueur (±1 px à 1,6 Hz) et les gemmes (le reflet tourne, le cristal non).

### HUD

Cadres à l'encre, panneaux de vélin, une seule famille en trois tailles (28 / 20 / 14 px). La barre de boss est la **seule** barre autorisée à un rouge saturé ; la barre de vie reste en acier bleu. Le HUD est dessiné dans la même encre que le monde, jamais dans des boîtes grises.

**La page (décision EW0-04).** Le vélin a une présence visible, mais dans le cadre seulement : le fond chaud du viewport hors de l'arène (`0.93, 0.90, 0.82`) et le papier des cartes du HUD. L'arène est un dessin cerné d'un trait d'encre posé sur la page ; rien de papier — grain, déchirure, couture — n'entre dans le terrain, où la lisibilité prime. La marge reste vide de mécanique tant que W7 ne l'écrit pas.

### Ce que W1/W2/W3 doivent ajouter

- W1-E3 : silhouettes des trois nouveaux ennemis + loup chargeur, avec annonces. **Le loup n'a pas de cornes** (décision EW0-04) : la charge est portée par la posture — le corps s'aplatit avant de partir — puis par la ligne tracée au sol ; la malédiction se lit dans la couleur (seul gris froid du monde), pas dans une corne. Le plan et le bestiaire qui disent « cornu » sont à corriger ; la bible tranche.
- W2-E3 : six nouvelles silhouettes d'armes (les quatre existantes restent).
- W3-E3 : silhouettes des trois classes.
- Chaque ajout entre dans la bible d'art **avant** l'implémentation et laisse une capture dans `production/qa/evidence/`. La bible est la loi ; un amendement est une modification de document avec preuve, pas une exception silencieuse.

### Colour Roles

| Rôle | Valeur | Sens | Interdits |
| ---- | ---- | ---- | ---- |
| **Encre** | `#29241F` | Structure, contours, texte | Jamais noir pur |
| **Encre douce** | Encre 55 % | Détails intérieurs | — |
| **Ombre au sol** | Encre 10–14 % | Ancrage | Rien ne flotte |
| **Herbe** | `0.765, 0.820, 0.608` | Fond | — |
| **Os** | `0.851, 0.812, 0.702` | Squelette, crâne du boss | — |
| **Peau d'orc** | `0.431, 0.549, 0.239` | Orc | Plus sombre que l'herbe |
| **Pelage de loup** | `0.420, 0.435, 0.478` | Loup, seul gris froid | — |
| **Acier du chevalier** | `0.400, 0.455, 0.541` | Armure, barre de vie | — |
| **Tabard** | `0.706, 0.208, 0.196` | Accent du joueur | Un seul accent par acteur |
| **Violet du boss** | `0.360, 0.250, 0.420` | Boss | — |
| **Or** | `0.851, 0.651, 0.149` | **L'encre de la récompense** : XP, anneau de montée, paiements (boss tué, run gagnée), titre de victoire | Jamais un rang, jamais un ornement de page, jamais la monnaie |
| **Danger** | `0.75, 0.20, 0.14` | Télégraphes, effets de boss | — |

**La monnaie de run n'est pas dorée** (décision verrouillée). Elle ne doit pas se confondre avec l'or d'XP, le rouge de danger, le violet du boss ni l'acier de la barre de vie. Directions à explorer par W4-E1 + `art-director` : os/ivoire, ardoise, encre bleue.

**Or — décision EW0-04.** L'or est l'encre de la récompense : il ne marque qu'une chose, le joueur qui est payé. Sur le terrain : la gemme d'XP et l'anneau qui se déclenche quand l'XP devient un niveau, quand le boss lâche son butin et quand la run est gagnée. Dans le cadre : la barre d'XP. Une seule fois en typographie : le titre de victoire, paiement final affiché alors que le jeu est arrêté. Tout le reste n'est pas or : la couronne du boss est en os — un rang se lit par la forme, et de l'or sur une menace se lit comme du butin ; la bannière de vague revient à l'encre, un tour de page n'étant pas un paiement ; la monnaie de run n'est jamais dorée. Test pour tout or futur : **le joueur est-il payé à cet instant ? Sinon, ce n'est pas de l'or.**

**Accessibilité couleur.** Une couleur peut nommer une menace, mais la forme ou le mouvement doit aussi la nommer. Jamais de codage par la seule couleur ; revue daltonisme en W1-E5.

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.7.2 stable, GDScript, Forward+, 2D top-down, 1280×720, PC |
| **Key Technical Challenges** | 5 comportements lisibles à 60 ennemis ; 10 armes aux mécaniques distinctes ; boutique (données + UI) ; identité de boss pilotée par les données ; 60 fps avec dessin à l'encre ; suite de tests ; rétrofit de localisation |
| **Art Style** | 2D vectorielle à l'encre, dessin procédural (`_draw`), pas de sprites bitmap |
| **Art Pipeline Complexity** | Faible à moyenne : primitives partagées (`InkStyle`), apparence pilotée par des clés d'art |
| **Audio Needs** | 8 SFX aujourd'hui, aucune musique ; W5 ajoute 4 états (calme / vague / boss / victoire) et des bus |
| **Networking** | Aucun |
| **Content Volume** | 3 classes, 10 armes, 6 ennemis / 5 comportements + 1 archétype de boss (2 rencontres), 12 équipements, 5 stats, 1 arène, 10 vagues ; run 4–8 min ; session 20–30 min |
| **Procedural Systems** | Décor d'arène statique à graine ; offres pondérées ; aucune génération de niveau |
| **Persistence** | Aucune aujourd'hui ; W7 ajoute `ProfileData` / `ProfileStore` |
| **Localization** | Français langue source, anglais première traduction ; W8 ; aucun système aujourd'hui |

### Contraintes et dettes à traiter

- **Visée automatique** sur l'ennemi vivant le plus proche, partout dans l'arène ; direction de déplacement en repli. Aucun ciblage manuel.
- **Données** : les valeurs vivent dans des `.tres` sous `data/`. **W0-E3 en cours** : `RunConfig` (`data/run_config.tres`) et `Catalogue` (`data/catalogue.tres`) sont extraits, `main.gd` consomme le catalogue au lieu des chemins codés en dur, et les paliers de boss sont lus depuis `run_config.tres`. Restent l'id stable + champ de déblocage d'`EnemyData` (le spawner lit encore `display_name`), la migration `InputMap` et les garde-fous.
- **Boss** : le boss est désormais référencé par le `Catalogue` (champ `boss`) ; l'identité pilotée par les données (spawn par vague, paliers) reste à finir en W1-E4.
- **Déblocage d'ennemis** : `Spawner` lit encore `display_name` (`_UNLOCK_WAVES`) ; W0-E3 ajoute l'id stable — en cours.
- **Entrées** : clavier physique WASD/ZQSD + flèches, axes de manette lus avec deadzone 0,25, HUD pilotable au clavier/souris/manette focalisée. Pas d'`InputMap` ; W0-E3 migre.
- **Tests** : gdUnit4 6.2.2 **vendorisé** (`addons/gdUnit4`, W0-E1) ; les 4 scripts jetables `tools/verify_*.gd` sont **supprimés** et remplacés par la suite portée (W0-E2) — `tests/unit/` (run_config, bootstrap) et `tests/integration/` (boss, armes, level-up, ciblage, bootstrap de scène), plus `tests/fixtures/main_scene_fixture.gd`. ADR-0001 documente le cadre. Reste W0-E4 (CI bloquante).
- **Audio** : 8 WAV (`enemy_death`, `hit_crit`, `hit_light`, `hit_heavy`, `level_up`, `player_hurt`, `boss_roar`, `boss_slam`) ; `sfx.gd` crée à la demande un bus « SFX » avec limiteur, routé vers Master. Aucune musique.
- **Chaînes** : français codé en dur dans `src/ui/hud.gd` et `scenes/main.tscn` ; W8.
- **Performance** : cible 60 fps ; canari W1-E5 à 60 ennemis / 2 ms.
- **Hors périmètre** : multijoueur, réseau, classements, mobile, tactile, certification console, nouveau moteur.

---

## MVP Definition

### Core hypothesis

**Un inconnu joue vingt minutes sans une minute ennuyeuse ou cassée.** C'est la barre du brief, pas « plus de contenu ».

### Ce qui est déjà prouvé

La tranche 0.4 : boucle complète, 10 vagues, deux rencontres de boss, butin, montée de niveau, mort et victoire. C'est une preuve de faisabilité, pas le MVP de la montée en gamme. W0-E1 (gdUnit4 vendorisé) et W0-E2 (suite portée) sont faits : la preuve qualité existe avant le contenu. Aucun élément des tiers « MVP » et « v1.0 » n'existe dans le build.

### Required for MVP (W9-E1 — portail vertical)

- 3 classes jouables, chacune battant le premier boss avec une stratégie différente.
- 10 armes aux mécaniques distinctes ; aucune strictement meilleure qu'une autre au même prix.
- 6 ennemis / 5 comportements, dont au moins 4 comportements distincts dans un run.
- Boutique entre les vagues : au moins 3 achats que le joueur peut expliquer.
- Musique par état et SFX rééquilibrés.
- Aucune plage de 3 vagues sans décision ; arc de tension mesuré ; run complet capturé.

### Explicitly NOT in MVP

Méta-persistance (W7), accessibilité avancée (W6-E3), localisation (W8), second boss distinct, nouvelles arènes ou biomes.

### Scope Tiers

| Tier | Content | Features | Statut |
| ---- | ---- | ---- | ---- |
| **Acquis — slice 0.4** | 1 classe, 4 armes, 3 marcheurs + 1 boss, 12 équipements, 5 stats, 10 vagues | Boucle complète, level-up, butin, mort/victoire | Vérifié |
| **MVP de la montée en gamme (W9-E1)** | 3 classes, 10 armes, 6 ennemis / 5 comportements, boutique, musique | 20 min sans ennui, 4 comportements/run, 3 achats expliqués, chaque classe bat le boss 1 | À construire |
| **v1.0** | + méta (W7), accessibilité minimale (W6-E1/E2), pause/réglages, localisation FR/EN (W8) | Deux runs diffèrent, écrans au clavier, chaînes hors code | À construire ; W6-E3 conditionnel |
| **Hors v1.0** | 2e boss distinct, autres arènes/biomes, classes supplémentaires, multijoueur, classements, mobile/console | — | Non planifié |

W6-E3 (accessibilité avancée) est planifiée en phase 18 ; elle n'est coupée que si W9-E1 échoue, et jamais en silence.

---

## Risks and Open Questions

### Design Risks

- **Visée automatique** : la compétence doit rester le placement, la lecture et le build. Si la boutique ne vend que des stats, le pilier 3 meurt.
- **Boutique** : chaque achat doit changer une décision. Le critère « 3 achats explicables » est le test.
- **Lisibilité des comportements** : 5 comportements × 60 ennemis ; silhouettes et annonces sont porteuses. Revue daltonisme en W1-E5.
- **Répétition du boss** : même archétype deux fois. L'escalade doit venir du palier et du contexte ; sinon la fin est plate.
- **Durée de run** : 4–8 min. La barre des 20 minutes dépend de la motivation de rejouer (classes, builds, méta), pas de la longueur d'une run.
- **Méta sans puissance permanente** : peut sembler maigre ; les déblocages et le choix de départ doivent produire de vraies différences.
- **Contrainte or = XP** : la monnaie non dorée doit rester lisible à côté des gemmes d'or, du rouge de danger et du violet du boss.
- **Fiction minimale** : trop de lore casse la boucle ; trop peu rend le bestiaire arbitraire.

### Technical Risks

- **gdUnit4** doit être vendorisé depuis GitHub ; si le réseau est indisponible, on s'arrête et on rapporte — on n'invente pas un harnais.
- **60 ennemis à 60 fps** avec dessin procédural à l'encre ; canari W1-E5 à 2 ms.
- **`main.gd` (846 lignes)** est un carrefour ; W0-E3 est en cours d'extraction des données (`RunConfig` + `Catalogue` sortis, id stable `EnemyData` restant) — à finir avant d'ajouter du contenu.
- **Boss et tuning codés en dur** ; W0-E3.
- **Rétrofit de localisation** : les chaînes sont codées en dur ; le standard « né localisé » (W8-E1) doit précéder le contenu.
- **Pas de musique** : W5 doit construire les états et les bus, pas seulement livrer des fichiers.

### Market Risks

- Genre saturé ; **aucun hook mécanique revendiqué** : l'exécution doit porter le jeu.
- Volume de contenu volontairement petit ; prix et positionnement non décidés.
- Développeur solo et premier projet : la discipline de portée est le risque principal.

### Scope Risks

- W0 (colonne vertébrale qualité) doit passer avant le contenu ; sinon chaque chantier est construit sur du sable.
- 19 phases ; W3 (classes) et W5 (audio) ont été reconstruits par le producteur et doivent être redécoupés par leurs chefs de département.
- La boutique arrive aux phases 13–14, après les armes et les ennemis ; ordre assumé, réversible sur demande.

### Open Questions

1. ~~**Loup chargeur vs bible d'art**~~ — **Résolu (EW0-04)** : pas de cornes. La charge est annoncée par la posture (corps aplati) et une ligne tracée au sol ; la malédiction se lit dans le gris froid. W1-E3 dessine, il ne redécide pas.
2. ~~**Règle de l'or**~~ — **Résolu (EW0-04)** : l'or est l'encre de récompense — gemmes d'XP, montée de niveau, butin de boss, titre de victoire, barre d'XP. Test : « le joueur est-il payé à cet instant ? » Si non, ce n'est pas de l'or. La couronne du boss passe en os ; la bannière de vague revient à l'encre.
3. **Langue visuelle de la monnaie de run** (`economy-designer` + `art-director`, W4-E1) : non dorée, non rouge de danger, non violette ; os/ivoire ou ardoise ?
4. ~~**Second boss**~~ — **Résolu (EW0-05)** : un seul archétype (`seigneur_squelette.tres`), deux rencontres (vagues 5 et 10, paliers scalés via `run_config.tres`). Un second `.tres` distinct est hors MVP et hors v1.0.
5. **Noms et règles signature des classes** — **ouvert** (`game-designer`, W3-E1) : « Chasseresse » et « Pénitent » sont des propositions.
6. **Classe à distance sans ciblage manuel** (`game-designer`, W3-E1) : confirmer que son identité est portée par la portée, les projectiles et le placement.
7. **Détails de la méta** — **ouvert** (`economy-designer`, W7-E1) : quels 4–6 déblocages ; le « choix de départ » inclut-il la classe ou seulement l'arme/le bonus ?
8. **XP du boss** : 30 XP fixes, non scalés par palier ; faut-il les scaler ? (`economy-designer` / `systems-designer`)
9. **Titre** — **ouvert** : « Medieval Survivors » est un titre de travail ; à confirmer avant W8-E3 (traduction) / Steam (`producer`).
10. **Noms des futurs ennemis** — **ouvert** (`game-designer` + `art-director`, W1-E0) : la Plume / la Tache / le Copiste.
11. **Entrées** : le brief dit « aucun déplacement à la manette », mais `main.gd` lit les axes de manette et le HUD accepte une manette focalisée ; W6-E3 prévoit la manette de bout en bout. Quelle base pour la v1.0 ? (`ux-designer` / `ui-programmer`)
12. **Audio** : le brief dit « aucun mixage par bus », mais `sfx.gd` crée un bus « SFX » + limiteur ; confirmer la base avant W5 (`audio-director`).
13. ~~**Lexique de bannière**~~ — **Résolu (EW0-05)** : « SEIGNEUR » / « ÉPREUVE », jamais « BOSS » / « boss » en chaîne joueur (interdit « anglais » déjà verrouillé). Libellé exact figé par `game-designer` + `narrative-director` en W1-E3, appliqué en W8-E2.
14. **Identité de boss pilotée par les données** : W0-E3/W1-E4 (`lead-programmer`).

---

## Next Steps

**Porte Concept : PASSED (EW0-05).** Le concept est verrouillé ; W1, W2 et W3 (ainsi que W4 et W5) sont débloqués. La relecture finale du chef d'équipe reste le dernier verrou humain.

- [x] EW0-01 → EW0-04 — identité, fiction, bestiaire, classes, ton, ancrage visuel.
- [x] W0-E1 — gdUnit4 6.2.2 vendorisé (`addons/gdUnit4`).
- [x] W0-E2 — les 4 `tools/verify_*.gd` remplacés par la suite portée (`tests/`).
- [ ] W0-E3 — données hors de `main.gd` (en cours : `RunConfig` + `run_config.tres` et `Catalogue` + `catalogue.tres` faits, `main.gd` consomme le catalogue ; restent l'id stable `EnemyData` + déblocage, la migration `InputMap`, les garde-fous).
- [ ] W0-E4 — CI bloquante.
- [ ] Relecture finale par le chef d'équipe.
- [ ] W1-E0 — GDD des cinq comportements, roster et télégraphies.
- [ ] W1-E3 — amendements de la bible d'art (loup, nouvelles silhouettes), avec captures.
- [ ] W2-E1 — contrat des dix armes et matrice 10×10.
- [ ] W3-E1 — GDD des classes (noms, stats, règles signature).
- [ ] W4-E1 — GDD de l'économie (monnaie non dorée, prix, stock, arc de tension).
- [ ] W7-E1 — GDD de la méta (record, 4–6 déblocages, choix de départ).
- [ ] `/design-review design/gdd/game-concept.md`.
- [ ] Garder ce document comme source unique du concept.
