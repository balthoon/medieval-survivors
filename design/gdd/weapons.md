# Armes — Medieval Survivors

> **Statut** : Designed (W2-E1) — contrat de données et spécification ; les mécaniques sont implémentées en W2-E2.
> **Auteur** : systems-designer
> **Dernière mise à jour** : 2026-11-09
> **Dernière vérification** : 2026-11-09
> **Pilier servi** : pilier 1 « chaque run est différent » et pilier 3 « le joueur a toujours un choix qui compte » ; la matrice de la §3.7 sert le pilier 2.
> **Référence rapide** — Couche : Core · Priorité : P0 (W2) · Dépend de : `WeaponData`, `Stats`, `Inventory`, `EnemyData`, `Offer`, `RunConfig`, comportements W1 · Est dépendu par : W2-E2, W2-E3, W2-E4, W3-E1, W4, W8.

## Overview

Le jeu passe de quatre armes — qui ne diffèrent que par des chiffres — à **dix armes portant chacune une règle que les neuf autres n'ont pas**. Une arme est définie par un identifiant stable, une silhouette, des valeurs de combat et un **jeton de mécanique** (`mechanic`) que W2-E2 résoudra dans `WeaponSystem`. Le joueur en porte trois au maximum, sur les trois emplacements existants ; aucune arme n'ajoute d'emplacement. Ce document est le contrat : il fige les dix armes, les quatre mécaniques rétrofit des armes existantes, les formules, les cas limites, les règles d'offre et les critères d'acceptation. **Aucune mécanique n'est implémentée ici** : le catalogue reste à quatre armes et `tests/integration/data_catalogue_test.gd` doit rester vert avec `EXPECTED_WEAPONS := 4`. Les six nouveaux `.tres` sont livrés et chargés, mais volontairement orphelins du catalogue jusqu'à W2-E2.

## Player Fantasy

Chaque arme doit répondre à une phrase que le joueur peut dire à voix haute avant de la prendre : « je vais laisser la meute m'entourer et tourner », « je vais aligner la colonne et tirer à travers », « je vais poser la mèche là où ils seront dans une seconde », « je vais tenir au contact et me refaire ». Le plaisir ne vient pas du chiffre de dégâts : il vient de **reconnaître une situation et de choisir l'outil qui la retourne**. Une arme qui ne change qu'un chiffre vole une décision ; elle n'entre pas dans ce document. Le joueur doit pouvoir, à la lecture d'une offre, nommer la mécanique et se représenter la scène où elle gagne — et la scène où elle perd.

Les quatre armes existantes gardent leur fantasy et gagnent une règle lisible : l'épée est la coupe fiable qui traverse un cône, la dague est le finisseur qui enchaîne les exécutions, le marteau est le coup qui repousse et coupe l'élan, l'arc est la flèche qui mord plus fort au bout de sa course.

## Detailed Rules

### 3.1 Le contrat : dix armes, trois emplacements, une règle par arme

- Dix armes, dix identifiants stables, **dix jetons de mécanique distincts** : `cleave`, `execution`, `stagger`, `distance`, `whirl`, `pierce`, `chain`, `orbit`, `fuse`, `lifesteal`.
- Toutes les armes partagent les **trois emplacements** de `Inventory.MAX_WEAPONS = 3`. Aucune arme n'a de slot propre. Une arme occupe un emplacement jusqu'à la fin de la run ; le level-up ne remplace pas une arme (voir §3.8).
- Une arme déjà portée n'est jamais reproposée **en acquisition** : `Inventory.has_weapon` compare par `id`. Deux armes identiques ne peuvent pas être portées. En revanche, une arme portée sous son niveau maximum est reproposée comme **niveau** (`weapon_upgrade`, lot 1) : c'est la même arme qui monte, pas une seconde copie.
- La **mécanique est la règle** ; `kind` (`melee` / `projectile`) et `shape` (dessin) restent des détails de résolution et de présentation. Une arme peut être mêlée et avoir une mécanique à distance (bâton en chaîne), ou projectile et ne pas infliger de dégâts à l'impact (encensoir).
- Les valeurs de combat restent dans les `.tres` ; aucun nombre de ce document ne vit dans un script.

### 3.2 Le champ `mechanic` : jeton `StringName`, et pourquoi

`WeaponData.mechanic` est un `StringName` dont les valeurs autorisées sont listées dans `WeaponData.MECHANICS`. Le choix est justifié ainsi :

| Option | Avantage | Coût | Décision |
|---|---|---|---|
| Enum GDScript (`int`) | Vérification à la compilation, exhaustivité dans le `match` | Un `.tres` écrit `mechanic = 7` ; ajouter une mécanique au milieu renumérote les données ; diff illisible | Rejeté |
| `String` nu | Lisible, extensible | Faute de frappe silencieuse, aucune liste close | Rejeté |
| **`StringName` + `MECHANICS`** | Lisible dans le `.tres` (`mechanic = &"pierce"`), extensible sans renumérotation, cohérent avec `kind`/`shape`/`rarity` déjà en chaîne, interning gratuit (la comparaison est faite une fois par frappe) | Pas d'exhaustivité à la compilation ; une faute est attrapée par le test de données (W2-E4), pas par le parseur | **Retenu** |

Règles de robustesse :

- `WeaponData.has_known_mechanic()` retourne faux pour un jeton inconnu.
- W2-E2 traite un jeton inconnu comme `cleave` et émet un `push_warning`, afin qu'une faute de frappe ne rende jamais une arme inerte. Le test de données de W2-E4 doit échouer sur un jeton inconnu.
- Un nouveau jeton s'ajoute **à la fin** de `MECHANICS` ; aucun jeton existant n'est renommé (les sauvegardes et les tests s'appuient dessus).

### 3.3 Les dix armes

Toutes les valeurs ci-dessous sont celles des `.tres` livrés. `arc` vaut 360° pour la faux et l'orbe ; il est ignoré pour les projectiles.

| id | Nom | Mécanique | Silhouette / règle en une phrase | Dégâts | Cadence (/s) | Portée (px) | Arc | Critique | Rareté | Slot | Ce que la mécanique demande au joueur |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `epee_longue` | Épée longue | `cleave` | Une entaille large qui frappe tous les ennemis du cône. | 12 | 1,8 | 64 | 90° | 5 % ×2,0 | commun | arme (1/3) | Tenir la ligne d'aimantation dans le paquet, pas sur une cible isolée. |
| `dague` | Dague | `execution` | Une frappe rapide, une seule cible ; un coup fatal rend la frappe disponible. | 7 | 2,8 | 42 | 60° | 12 % ×2,0 | commun | arme (1/3) | Rester au contact et finir les blessés ; ne pas l'emporter contre un boss. |
| `marteau` | Marteau de guerre | `stagger` | Un coup à 160° qui repousse et interrompt l'élan. | 26 | 0,7 | 80 | 160° | 3 % ×2,2 | peu_commun | arme (1/3) | Faire face tôt, attraper la préparation d'un chargeur ou d'un exploseur. |
| `arc_court` | Arc court | `distance` | Une flèche qui frappe plus fort au bout de sa course (jusqu'à +50 %). | 9 | 1,2 | 320 | projectile | 8 % ×2,0 | commun | arme (1/3) | Garder l'ennemi à l'extérieur, reculer plutôt que coller. |
| `faux` | Faux | `whirl` | Un tour complet qui tranche tout ce qui entoure le porteur. | 14 | 0,9 | 58 | 360° | 4 % ×2,0 | peu_commun | arme (1/3) | Se laisser entourer volontairement, rester dans la masse. |
| `arbalete` | Arbalète | `pierce` | Un carreau qui traverse une ligne, chaque cible suivante à 85 %. | 18 | 0,8 | 380 | projectile | 6 % ×2,2 | rare | arme (1/3) | Chercher l'alignement ; repositionner pour que la meute fasse une ligne. |
| `baton` | Bâton | `chain` | Un coup qui saute jusqu'à deux ennemis proches, chaque saut à 75 %. | 10 | 1,1 | 72 | 40° | 5 % ×2,0 | rare | arme (1/3) | Frapper un paquet, jamais une cible seule. |
| `orbe` | Orbe orbitale | `orbit` | Une lune d'encre qui tourne autour du porteur ; un contact par ennemi et par tour. | 8 | 1,0 (indicatif) | 46 | 360° | 5 % ×2,0 | epique | arme (1/3) | Bouger pour balayer de nouveaux ennemis, rester à portée courte. |
| `encensoir` | Encensoir | `fuse` | Une détonation posée au sol, qui éclate après 0,9 s dans 70 px. | 22 | 0,55 | 220 | projectile | 5 % ×2,0 | peu_commun | arme (1/3) | Prédire où le groupe sera dans une seconde ; lancer tôt. |
| `lame_vampire` | Lame vampire | `lifesteal` | Une lame qui rend 25 % des dégâts réellement infligés. | 11 | 1,5 | 58 | 80° | 6 % ×2,0 | rare | arme (1/3) | Tenir au contact et échanger, sans encaisser un burst. |

**Lecture de la rareté.** La rareté est une étiquette de présentation et une future clé de prix de boutique (W4), **pas un rang de puissance**. W2 offre les dix armes au même poids et au même prix : un emplacement d'arme et une ligne d'offre. W4 ne peut introduire un prix par rareté que si la preuve de non-domination est refaite **par palier de prix**.

### 3.4 Paramètres spécifiques de mécanique

| id | `execution_floor` | `stagger_seconds` | `distance_damage_bonus` | `pierce_falloff` | `chain_jumps` / rayon / `chain_falloff` | `orbit_radius` / vitesse / recharge | `fuse_seconds` / rayon | `lifesteal_ratio` |
|---|---|---|---|---|---|---|---|---|
| `epee_longue` | — | — | — | — | — | — | — | — |
| `dague` | 0,18 s | — | — | — | — | — | — | — |
| `marteau` | — | 0,6 s | — | — | — | — | — | — |
| `arc_court` | — | — | 0,50 | — | — | — | — | — |
| `faux` | — | — | — | — | — | — | — | — |
| `arbalete` | — | — | — | 0,85 | — | — | — | — |
| `baton` | — | — | — | — | 2 / 90 px / 0,75 | — | — | — |
| `orbe` | — | — | — | — | — | 46 px / 2,4 rad/s / 0,5 s | — | — |
| `encensoir` | — | — | — | — | — | — | 0,9 s / 70 px | — |
| `lame_vampire` | — | — | — | — | — | — | — | 0,25 |

Pour l'orbe, `attacks_per_second` n'est pas la cadence réelle : la cadence est portée par `orbit_speed` et `orbit_hit_cooldown`. W2-E2 doit calculer l'affichage de l'offre à partir de la mécanique, pas du tronc commun (voir §3.8).

### 3.5 Les quatre armes existantes, noir sur blanc

Les valeurs numériques des quatre `.tres` existants sont **inchangées**. Ce qui change en W2-E2 est la règle qui les distingue.

#### Épée longue — `cleave` (entaille large)

**Règle** : au moment d'impact, tous les ennemis vivants dans le cône de 90° et la portée prennent les dégâts pleins. Pas de rendement décroissant avec le nombre de cibles, pas de cible privilégiée, pas d'interruption. Chaque ennemi est touché au plus une fois par coup.

**Ce qui la distingue** : c'est la seule arme qui combine un cône large, des dégâts pleins sur chaque cible et **aucune condition** (pas de vol de vie, pas de recul, pas de chaîne, pas de délai). Elle est la référence de dégâts mêlée fiable ; elle ne gagne jamais une situation par une règle, elle la gagne par la géométrie et la constance.

**Ce qu'elle demande** : orienter le cône vers le *paquet*, pas vers le premier ennemi. La visée automatique choisit l'ennemi le plus proche ; le joueur choisit sa position pour que ce premier ennemi soit aussi le centre du paquet.

#### Dague — `execution` (frappe d'exécution)

**Règle** : la dague ne frappe que **la cible la plus proche** dans son cône. Si le coup **tue**, le cooldown de la dague est ramené à `execution_floor` (0,18 s) au lieu de `1 / cadence` (0,357 s). Le plancher est nécessaire : sans lui, un coup fatal toutes les frames rendrait la cadence dépendante du framerate et permettrait plusieurs frappes dans la même image.

**Ce qui la distingue** : c'est la seule arme dont la cadence dépend du **résultat** du coup, et la seule qui ne touche qu'une cible. Elle est excellente contre un flux de cibles déjà entamées ou fragiles, et médiocre contre un boss (aucune exécution).

**Ce qu'elle demande** : finir, pas ouvrir. La dague veut des cibles à quelques points de vie ; elle ne crée pas l'ouverture.

#### Marteau — `stagger` (recul lourd)

**Règle** : le marteau frappe tous les ennemis du cône de 160° et applique son recul. En plus, si un ennemi **non élite** est en train de préparer une attaque (charge, tir, mèche, invocation) au moment du coup, sa préparation est annulée et son prochain délai d'attaque est augmenté de `stagger_seconds` (0,6 s). Les élites (`EnemyData.is_elite = true`) sont **immunisées à l'interruption** : elles prennent les dégâts et le recul réduit par `knockback_resistance`, mais leur slam n'est pas annulé.

**Ce qui la distingue** : c'est la seule arme qui **retire une action à venir** à un ennemi. Le recul seul serait un chiffre ; l'interruption est la règle. Elle est la réponse au chargeur et à l'exploseur, et un mauvais choix contre un boss.

**Ce qu'elle demande** : lire l'annonce et frapper pendant la préparation, pas après. Le marteau est lent (0,7/s) : un coup manqué coûte cher.

#### Arc court — `distance` (tir tendu)

**Règle** : la flèche touche le **premier** ennemi qu'elle rencontre et s'arrête. Ses dégâts sont multipliés par `1 + distance_damage_bonus × clamp(distance_parcourue / portée, 0, 1)`, soit ×1,0 au contact et jusqu'à ×1,5 au bout de la portée. La distance est mesurée **à l'impact**, pas au tir.

**Ce qui la distingue** : c'est la seule arme qui paie le joueur pour **maintenir la distance**. L'arbalète traverse et retombe ; l'arc, lui, exige le duel à distance et punit le corps à corps.

**Ce qu'elle demande** : ne pas laisser l'ennemi entrer. L'arc est une arme de repli, pas de contact.

### 3.6 Les six nouvelles armes, noir sur blanc

#### Faux — `whirl` (entaille circulaire)

**Règle** : au moment d'impact, tous les ennemis vivants dans un rayon de `portée` autour du joueur, sur 360°, prennent les dégâts pleins. Chaque ennemi est touché au plus une fois par tour. Aucune orientation n'est requise : le cône est le cercle.

**Ce qui la distingue** : c'est la seule mêlée qui ne demande **aucune orientation** et qui frappe derrière. Le prix est le DPS en cible unique (13,1), le plus bas des mêlées, et un temps d'armement de 0,28 s.

**Ce qu'elle demande** : accepter l'encerclement. La faux est mauvaise quand le joueur fuit ; elle est excellente quand il tient sa position au centre de la masse.

#### Arbalète — `pierce` (carreau perforant)

**Règle** : le carreau traverse les ennemis vivants qu'il rencontre jusqu'à sa portée. Le premier prend les dégâts pleins ; chaque ennemi suivant prend `pierce_falloff` fois les dégâts du précédent (0,85). Un ennemi déjà mort avant d'être atteint est ignoré et **n'incrémente pas** le rang de perforation. Un ennemi vivant n'est traversé qu'une fois par carreau.

**Ce qui la distingue** : c'est la seule arme qui convertit **l'alignement** en multiplicateur. Elle ne demande pas de foule, elle demande une **ligne**.

**Ce qu'elle demande** : repositionner pour aligner. L'arbalète est mauvaise quand les ennemis arrivent en arc de cercle.

#### Bâton — `chain` (chaîne)

**Règle** : le bâton frappe la cible la plus proche dans son cône, puis saute jusqu'à `chain_jumps` fois (2) vers l'ennemi vivant le plus proche de la **cible précédente**, dans un rayon de `chain_jump_radius` (90 px). Chaque saut vaut `chain_falloff` (0,75) fois le précédent. Un ennemi ne peut être touché qu'une fois par cast ; un ennemi mort est exclu ; si la cible meurt pendant la résolution, la chaîne continue depuis sa dernière position.

**Ce qui la distingue** : c'est la seule arme qui atteint **derrière** la première ligne sans ligne ni projectile, et la seule dont la valeur dépend d'un **amas**, pas d'une ligne.

**Ce qu'elle demande** : frapper un paquet. Contre une cible seule, le bâton vaut 11,6 DPS, l'un des pires du jeu.

#### Orbe orbitale — `orbit`

**Règle** : l'orbe tourne autour du joueur à `orbit_radius` (46 px) à `orbit_speed` (2,4 rad/s). Elle inflige ses dégâts à chaque ennemi qu'elle traverse, mais **au plus une fois par ennemi et par tour complet** ; `orbit_hit_cooldown` (0,5 s) est un second plafond, et c'est le plus contraignant des deux qui s'applique. L'orbe ne vise pas et n'utilise pas la visée automatique.

**Ce qui la distingue** : c'est la seule arme **passive** : elle ne consomme aucun temps d'arme et ne demande aucune action. Son coût est un emplacement et un DPS faible par ennemi (3,2).

**Ce qu'elle demande** : bouger pour amener de nouveaux ennemis dans l'anneau, et rester à courte portée. Elle ne remplace pas une arme de burst.

#### Encensoir — `fuse` (détonation retardée)

**Règle** : l'encensoir est lancé vers la cible la plus proche (ou, à défaut, vers le point d'aimantation à portée). Il ne fait aucun dégât à l'impact ; il se pose, s'arme, puis explose après `fuse_seconds` (0,9 s) et inflige ses dégâts à tous les ennemis vivants dans `fuse_radius` (70 px). Un seul jet de critique par détonation, partagé par toutes les cibles. Les détonations simultanées sont indépendantes et s'additionnent.

**Ce qui la distingue** : c'est la seule arme dont la valeur dépend de la **position future** des ennemis. Elle paie contre les groupes lents et stationnaires, et ne paie pas contre un chargeur qui quitte le rayon.

**Ce qu'elle demande** : lire la trajectoire du groupe et lancer **avant** qu'il arrive. Le délai est la décision.

#### Lame vampire — `lifesteal` (vol de vie)

**Règle** : la lame frappe tous les ennemis de son cône (80°) et rend au joueur `lifesteal_ratio` (0,25) des dégâts **réellement infligés** — le sur-dégât au-delà des points de vie restants ne compte pas. Le soin est plafonné par les points de vie manquants. Les élites (`EnemyData.is_elite = true`) sont **immunisées au vol de vie** : elles prennent les dégâts, mais ne rendent aucun point de vie. Aucun champ nouveau n'est nécessaire : `is_elite` est déjà dans `EnemyData`.

**Ce qui la distingue** : c'est la seule arme qui transforme les dégâts en **ressource de survie**. Son DPS est moyen (18,5) mais elle ajoute 4,6 PV/s sur une cible unique, et zéro contre le boss.

**Ce qu'elle demande** : tenir au contact et échanger, tout en évitant le burst qui tue avant que le soin ne paie. Contre un boss, il faut une autre source de survie.

### 3.7 Matrice 10 × 10

**Colonnes 1 à 6 — comportements ennemis (W1)** : Marcheur (squelette, orc), Chargeur (loup maudit), Tireur (la Plume), Exploseur (la Tache), Invocateur (le Copiste), Boss (Seigneur squelette, slam).
**Colonnes 7 à 10 — pressions géométriques** : Foule (5 ennemis ou plus au contact), Ligne (3 ennemis ou plus alignés), Cible unique (un ennemi ordinaire isolé, hors boss, pour que l'exécution de la dague puisse se déclencher), Survie (contact prolongé sans autre source de soin).

Chaque case commence par un verdict — **Très fort** > **Fort** > **Moyen** > **Faible** — puis la raison. Le plan nomme cette matrice « 10×10 » : le bestiaire W1 fournit cinq comportements plus le boss (six colonnes), et les quatre pressions complètent les dix colonnes sans changer la question posée à chaque arme. Aucune case n'est vide.

| Arme | Marcheur | Chargeur | Tireur | Exploseur | Invocateur | Boss | Foule | Ligne | Cible unique | Survie |
|---|---|---|---|---|---|---|---|---|---|---|
| **Épée longue** | **Fort** — cône de 90° qui coupe 2 à 3 marcheurs pendant le recul. | **Moyen** — l'atteint de face, mais aucune interruption ; il faut pré-viser. | **Faible** — 64 px contre 320 : il faut traverser le tir. | **Moyen** — assez de burst pour le tuer, mais à portée de l'explosion. | **Moyen** — coupe l'invocateur et ses ajouts s'ils s'empilent ; pas de priorisation. | **Moyen** — dégâts fiables, recul presque nul (résistance 0,85), pas d'outil anti-slam. | **Fort** — chaque ennemi du cône prend les dégâts pleins, sans rendement décroissant. | **Moyen** — pas de perforation ; il faut être au contact de la ligne. | **Moyen** — 22,7 DPS, la référence mêlée fiable. | **Moyen** — aucun soin ; le cône aide à désengager. |
| **Dague** | **Fort** — achève les blessés et rend 0,18 s par exécution. | **Faible** — 42 px de portée ; la charge arrive avant la frappe. | **Faible** — la plus courte portée ; ne peut pas répondre. | **Fort** — l'exécution enchaîne sur un exploseur déjà entamé. | **Moyen** — bonne pour finir l'invocateur, mauvaise pour nettoyer les ajouts. | **Faible** — pas d'exécution sur un boss : 22 DPS sans bonus. | **Faible** — une seule cible par frappe ; submergée. | **Faible** — aucune perforation. | **Très fort** — 22 DPS, et 43,6 DPS sur une cible tuée en un coup. | **Faible** — aucun soin, doit rester au contact. |
| **Marteau** | **Fort** — 160° et 60 px de recul ; casse la meute et rouvre le kite. | **Très fort** — annule la préparation et ajoute 0,6 s ; la réponse au chargeur. | **Faible** — 0,7 att/s et 80 px ; le tireur punit l'armement. | **Très fort** — interrompt la mèche et le repousse hors du rayon. | **Moyen** — interrompt l'invocation, mais 0,7/s ne nettoie pas les ajouts. | **Faible** — immunisé à l'interruption, 85 % de résistance au recul ; 18,9 DPS. | **Très fort** — le meilleur outil de foule : 160° et recul. | **Moyen** — le cône large attrape une ligne courte, sans perforation. | **Faible** — 18,9 DPS, le plus bas des mêlées lourdes. | **Fort** — le recul est une défense ; aucun soin. |
| **Arc court** | **Fort** — éclaircit à 320 px, jusqu'à ×1,5 au bout de course. | **Moyen** — touche la ligne de charge, mais le loup franchit 320 px en 2,5 s. | **Très fort** — même portée, et le bonus de distance récompense le duel à distance. | **Moyen** — le tue à distance, mais le trait s'arrête au premier ajout. | **Fort** — atteint l'invocateur derrière la meute ; cible unique. | **Moyen** — 11,7 à 17,5 DPS à distance sûre, sans outil anti-slam. | **Faible** — un seul ennemi par flèche. | **Faible** — pas de perforation. | **Fort** — 17,5 DPS au maximum de portée. | **Fort** — la distance est la survie ; aucun soin. |
| **Faux** | **Très fort** — 360° : tout ce qui touche est coupé, sans visée. | **Moyen** — le prend à l'arrivée, mais 0,28 s d'armement et aucune interruption. | **Faible** — 58 px ; ne peut pas l'atteindre. | **Moyen** — le touche de n'importe quel côté, mais le délai de frappe risque la détonation. | **Moyen** — frappe l'invocateur et l'anneau d'ajouts s'ils encerclent. | **Faible** — 13,1 DPS en cible unique, le plus bas des mêlées. | **Très fort** — 6 ennemis = 78,6 DPS par tour ; l'anti-encerclement. | **Moyen** — frappe la ligne si elle est au contact, pas à distance. | **Faible** — 13,1 DPS. | **Moyen** — tue ce qui colle, mais aucun soin. |
| **Arbalète** | **Très fort** — une colonne alignée prend 18 + 15,3 + 13 par carreau. | **Moyen** — une cible unique, pas d'interruption ; le carreau ne ralentit pas. | **Fort** — 380 px, plus loin que le tireur ; peut aussi traverser l'écran de marcheurs. | **Moyen** — le tue à distance si aucun ajout n'est devant. | **Très fort** — une ligne à travers la meute atteint l'invocateur et les ajouts derrière. | **Moyen** — 15,4 DPS en cible unique ; bon seulement si des ajouts s'alignent. | **Fort** — la perforation paie exactement sur une foule alignée. | **Très fort** — la meilleure arme de ligne. | **Moyen** — 15,4 DPS. | **Fort** — 380 px ; aucun soin. |
| **Bâton** | **Fort** — un cast touche trois marcheurs (10 + 7,5 + 5,6). | **Faible** — un chargeur seul ne donne aucun saut ; 11,6 DPS. | **Faible** — 72 px ; hors de portée. | **Fort** — la chaîne atteint l'exploseur derrière deux marcheurs. | **Très fort** — l'invocateur et ses ajouts sont la grappe idéale ; 26,7 DPS par cast. | **Faible** — cible unique, aucun saut, aucun contrôle. | **Très fort** — jusqu'à 2,31 fois les dégâts d'un coup. | **Moyen** — la chaîne saute dans un rayon de 90 px, pas en ligne. | **Faible** — 11,6 DPS. | **Faible** — aucun soin, courte portée. |
| **Orbe orbitale** | **Fort** — l'anneau coupe les marcheurs qui entrent pendant le kite, sans input. | **Moyen** — le chargeur traverse l'anneau pour un contact, sans interruption. | **Faible** — rayon 46 px ; le tireur n'entre jamais dedans. | **Fort** — il doit entrer dans l'anneau pour t'atteindre ; il prend un contact. | **Moyen** — l'anneau érafle l'invocateur et les ajouts, sans focus. | **Moyen** — 3,2 DPS par ennemi sur l'anneau ; sûr mais lent. | **Fort** — chaque ennemi sur l'anneau paie ; 5 ennemis = 16 DPS. | **Faible** — l'anneau est un cercle, pas une ligne. | **Faible** — 3,2 DPS. | **Très fort** — passif, ne demande aucun temps d'arme ; aucun soin. |
| **Encensoir** | **Très fort** — un blast de 70 px sur un paquet de marcheurs. | **Faible** — le loup quitte le rayon pendant les 0,9 s ; la charge le sauve. | **Fort** — 220 px de jet atteint le nid et blast l'écran autour. | **Très fort** — rond et lent ; la mèche le tue avec ses voisins. | **Très fort** — le cercle d'invocation est une cible stationnaire. | **Moyen** — 12,7 DPS en cible unique, mais le boss lent reste dans le blast. | **Très fort** — 4 ennemis = 50,8 DPS. | **Moyen** — le blast est circulaire ; une ligne dense paie, une ligne fine non. | **Faible** — 12,7 DPS si la cible reste 0,9 s. | **Fort** — tue à distance ; aucun soin. |
| **Lame vampire** | **Fort** — échange avec les marcheurs et rend 3,1 PV par coup. | **Faible** — 58 px, aucune interruption ; la charge passe quand même. | **Faible** — doit traverser le tir pour se soigner. | **Moyen** — peut encaisser un blast et se refaire, si le burst ne la tue pas d'abord. | **Moyen** — se maintient à travers les ajouts, mais tue lentement. | **Faible** — 18,5 DPS sans soin : le boss est une élite, donc immunisé au vol de vie. | **Moyen** — frappe une cible et se soigne sur elle ; pas d'area. | **Faible** — pas de perforation. | **Fort** — 18,5 DPS et 4,6 PV/s, la meilleure endurance hors boss. | **Très fort** — le seul vol de vie ; transforme le contact en ressource. |

**Non-domination.** Aucune arme n'est supérieure ou égale à une autre sur les dix colonnes avec au moins une supériorité stricte. Les duels qui auraient pu dominer sont tranchés par une case : la dague bat la vampire en cible unique et en exploseur ; l'arc bat l'arbalète en tireur et en cible unique ; la faux bat le marteau en marcheur ; l'encensoir bat l'arbalète en exploseur et en foule ; l'épée bat la vampire en foule et en ligne. Le test de W2-E4 doit encoder ces verdicts et échouer si une paire devient dominante.

### 3.8 Offres décisionnelles

**Ce qu'une offre d'arme doit montrer.** Le titre d'une acquisition garde le format existant « Arme : <nom> » ; celui d'un niveau est décrit plus bas. La description commence par le texte de `weapon.<id>.desc` — la **mécanique nommée** — puis les nombres qui aident à décider. Une offre qui n'affiche que « 12 dégâts · 1,8 att/s · 22 DPS · portée 64 px » est refusée : elle cache la règle. Pour les mécaniques non couvertes par le DPS du tronc commun, l'affichage est spécifique :

| Mécanique | Ce que l'offre affiche après la phrase |
|---|---|
| `cleave` | DPS cible unique et DPS par cible supplémentaire (dégâts pleins). |
| `execution` | DPS normal, puis « 43,6 DPS sur une cible tuée en un coup ». |
| `stagger` | Recul effectif et « interrompt une préparation (élites exclues) ». |
| `distance` | DPS au contact et DPS à portée maximale. |
| `whirl` | DPS par ennemi et « jusqu'à N ennemis par tour ». |
| `pierce` | Dégâts du 1er, 2e et 3e ennemi traversé. |
| `chain` | Dégâts du coup et total des trois sauts. |
| `orbit` | « 1 contact par ennemi et par tour · 3,2 DPS par ennemi ». |
| `fuse` | « Détonation après 0,9 s · rayon 70 px · 22 dégâts par ennemi ». |
| `lifesteal` | DPS et « +4,6 PV/s · élites immunisées ». |

**Poids et tirage.** Le niveau tire trois offres distinctes sans remise, chacune pondérée par `Offer.weight`. Les armes candidates valent toutes `RunConfig.weapon_offer_weight` (1,4) : aucune arme n'est plus probable qu'une autre. Les niveaux valent `RunConfig.weapon_upgrade_weight` (1,4), de sorte qu'une acquisition et un niveau pèsent le même poids par candidat. Les améliorations de stat valent leur `weight` (1,0 chacune) et l'équipement vaut `equipment_offer_weight` (0,9) × le poids de rareté. La formule est en §4.13.

**Niveaux d'arme (lot 1).** Une arme portée sous son `max_level` (4 dans les données actuelles) est candidate à une offre `weapon_upgrade`. Le titre est « ↑ <nom> +1 (niv. N) » ; la description commence par « niv. N-1 → N », puis les nombres **effectifs au niveau visé** — le joueur voit ce que le niveau suivant change, pas les valeurs actuelles. Un niveau ajoute un pas **additif** sur la base (`WeaponData.level_damage_step = 0,25`, `level_cadence_step = 0,05`, `level_range_step = 0,05` par niveau), appliqué **avant** les multiplicateurs globaux ; le niveau 4 vaut donc ×1,75 dégâts et ×1,15 cadence, pas ×1,25³. Une arme au niveau maximum n'est jamais candidate. Le niveau vit dans `Inventory.weapon_levels`, indexé par l'`id` de l'arme : la `WeaponData` reste partagée par toutes les runs.

**Une seule ligne d'arme (A2).** Acquisitions et niveaux partagent une seule et même ligne : un panneau ne montre jamais deux lignes d'arme. Le pool pondéré contient toutes les candidates, chacune avec son poids, et c'est `_pick_weighted` qui retire les autres lignes d'arme dès qu'une est tirée. Conséquence assumée : un panneau ne propose jamais « une arme neuve **et** un niveau » ; le second choix attend le panneau suivant.

**Slots pleins.** Aucune arme n'est proposée **en acquisition** quand `Inventory.free_weapon_slots() == 0` : le refus est structurel, pas une option. Le joueur ne peut donc jamais « refuser » une arme faute de place — il ne la voit pas. Les niveaux, eux, restent disponibles quand les trois slots sont pleins : c'est là qu'ils prennent le relais. Le level-up ne remplace jamais une arme. Si W4 ajoute un échange en boutique, il passera par `Inventory.replace_weapon` et non par le panneau de level-up.

**Doublons.** Une arme dont l'`id` est déjà porté n'est jamais candidate **en acquisition** (`Inventory.has_weapon`) et `Inventory.add_weapon` la refuse ; elle peut en revanche être candidate **en niveau** tant qu'elle est sous son max. Deux `.tres` distincts avec le même `id` sont un défaut de données : le second est traité comme déjà porté, et le test de données de W2-E4 exige des `id` uniques.

**Plafond des acquisitions.** Le nombre d'**acquisitions** candidates est plafonné à `free_weapon_slots()` : deux slots libres donnent au plus deux acquisitions candidates, un slot libre une seule. Le tirage excédentaire est mélangé uniformément (Fisher-Yates avec le RNG de la run), jamais trié par DPS. Sans ce plafond, la part d'arme du panneau grandirait avec la taille du catalogue. Les niveaux ne sont pas plafonnés de la même manière : chaque arme portée sous son max est une candidate. Les deux ensembles réunis forment le pool d'arme, dont une seule ligne est tirée.

**Reroll.** `RunConfig.reroll_base = 2`, plus un reroll aux niveaux 10 et 20 (`reroll_levels`). Un reroll reconstruit les trois offres, garde le panneau ouvert et ne rend pas le choix précédent. Il ne peut pas créer d'acquisition quand les slots sont pleins, mais il peut reproposer un niveau (tant qu'une arme portée est sous son max). Il partage le même compteur entre level-up et butin de boss.

**Butin de boss.** Même panneau, poids `boss_loot_weapon_weight = 3,0` et `boss_loot_equipment_weight = 2,5`. Quand un poids d'arme explicite est fourni, il remplace **les deux** poids d'arme — acquisitions et niveaux. Toujours sans doublon, et les acquisitions restent plafonnées par les slots libres.

### 3.9 Périmètre de W2-E1

| Fait dans W2-E1 | Fait plus tard |
|---|---|
| `mechanic`, `name_key`, `description`, `description_key`, `rarity` et les champs de mécanique dans `WeaponData`. | Résolution des mécaniques dans `weapon_system.gd` / `projectile.gd` (W2-E2). |
| Les six nouveaux `.tres` remplis et chargeables. | Ajout des six armes à `data/catalogue.tres` et passage de `EXPECTED_WEAPONS` à 10 (W2-E2, dans le même changement). |
| Les quatre `.tres` existants tagués (`mechanic`, clés, champs de mécanique), **valeurs numériques inchangées**. | Textes d'offre nommant la mécanique (`Offer.for_weapon`, `_decorate_offer`) : W2-E2. |
| Ce GDD, matrice et formules. | Silhouettes et couleurs définitives : W2-E3. |
| Aucun test ajouté ; la suite reste à 58 tests / 11 suites. | Un test par mécanique, trois runs / trois builds, matrice de non-domination : W2-E4. |

## Formulas

**Glossaire commun.** `w` est une `WeaponData` ; les valeurs entre parenthèses sont celles du `.tres` livré. `m_dmg`, `m_spd`, `m_rng` et `b_crit` sont les multiplicateurs de `Stats` (additifs, voir `Stats.apply_upgrade`).

### F1 — Dégâts d'un coup et espérance

**Expression**

```text
D_hit      = D_w * m_dmg * M_w          si le coup est critique
D_hit      = D_w * m_dmg                sinon
p_crit     = clamp(C_w + b_crit, 0, 0.75)
E[D_hit]   = D_w * m_dmg * (1 + p_crit * (M_w - 1))
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `D_w` | float | 7–26 | `weapon.damage`, dégâts de base du `.tres`. |
| `m_dmg` | float | 1,0–3,0 | `Stats.damage_mult`, additif sur les améliorations et l'équipement. |
| `M_w` | float | 2,0–2,2 | `weapon.crit_multiplier`. |
| `C_w` | float | 0,03–0,12 | `weapon.crit_chance`. |
| `b_crit` | float | 0,0–0,75 | `Stats.crit_chance_bonus`, déjà plafonné par `Stats`. |
| `p_crit` | float | 0,0–0,75 | Chance de critique effective. |
| `E[D_hit]` | float | `D_w*m_dmg` à `D_w*m_dmg*1,75` | Espérance des dégâts d'un coup. |

**Plage de sortie** — `D_hit` va de `D_w*m_dmg` (pas de critique) à `D_w*m_dmg*M_w` (critique). `E[D_hit]` est bornée par le plafond de critique à 0,75 : au maximum ×1,75 pour `M_w = 2,0` et ×1,90 pour `M_w = 2,2`. Aucune valeur négative : `D_w`, `m_dmg` et `M_w` sont positifs par construction des données.

**Exemple chiffré** — Épée longue (`D_w = 12`), `m_dmg = 1,2`, `C_w = 0,05`, `b_crit = 0,10`, `M_w = 2,0` : `p_crit = 0,15`, `E[D_hit] = 12 × 1,2 × 1,15 = 16,56`. Un critique vaut `12 × 1,2 × 2,0 = 28,8`.

### F2 — Cadence et DPS cible unique

**Expression**

```text
RPS_w   = max(A_w * m_spd, 0.001)
DPS_1   = E[D_hit] * RPS_w
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `A_w` | float | 0,55–2,8 | `weapon.attacks_per_second`. |
| `m_spd` | float | 1,0–2,5 | `Stats.attack_speed_mult`, additif. |
| `RPS_w` | float | 0,001–7,0 | Attaques effectives par seconde. Le plancher de 0,001 évite une division par zéro. |
| `DPS_1` | float | 0–200 | Dégâts espérés par seconde sur une cible unique. |

**Plage de sortie** — `RPS_w` est bornée en bas par 0,001 (jamais zéro) et, en pratique, par les valeurs de données à 7,0 (dague 2,8 × 2,5). `DPS_1` est positive et non bornée en haut par les multiplicateurs ; elle est bornée par la plage de tuning ci-dessus. Pour l'orbe, `DPS_1` **n'est pas** la valeur affichée : voir F10.

**Exemple chiffré** — Épée longue à stats de base : `E[D_hit] = 12,60`, `RPS_w = 1,8`, `DPS_1 = 22,68`. Dague : `7,84 × 2,8 = 21,95`.

### F3 — DPS de zone

**Expression**

```text
DPS_A = DPS_1 * N_hit
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `N_hit` | int | 1–60 | Nombre d'ennemis distincts touchés par une frappe (géométrie de la mécanique). |
| `DPS_A` | float | `DPS_1` à `DPS_1 × 60` | Dégâts espérés par seconde sur l'ensemble des cibles. |

**Plage de sortie** — de `DPS_1` (une cible) à `DPS_1 × 60` (canari W1-E5 à 60 ennemis). Aucune valeur négative. La borne haute est un plafond de scène, pas un plafond de règle.

**Exemple chiffré** — Faux (`DPS_1 = 13,104`) sur 6 ennemis : `DPS_A = 78,62`.

### F4 — Exécution de la dague

**Expression**

```text
T_cd      = E_floor                         si le coup tue et E_floor > 0
T_cd      = 1 / RPS_w                       sinon
DPS_exec  = E[D_hit] / max(T_cd, 1/60)
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `E_floor` | float | 0,12–0,25 s ; 0 = désactivé | `weapon.execution_floor`. |
| `T_cd` | float | 0,18–1,82 s | Cooldown après le coup. |
| `DPS_exec` | float | `DPS_1` à `E[D_hit] × 60` | DPS soutenu sur une cible toujours disponible. |

**Plage de sortie** — sans exécution, `DPS_exec = DPS_1` (21,95 pour la dague). Avec exécution, le plancher de 1/60 s empêche une cadence dépendante du framerate ; la valeur pratique est `E[D_hit] / 0,18 = 43,56`. Si `E_floor = 0`, la règle est désactivée et `T_cd = 1/RPS_w`.

**Exemple chiffré** — Loup maudit à 8 PV, dague `E[D_hit] = 7,84` : le premier coup laisse 0,16 PV, le second tue. Cycle = `0,357 + 0,18 = 0,537 s` pour deux coups : `DPS_exec = 15,68 / 0,537 = 29,2`. Squelette à 20 PV : trois coups, cycle `2 × 0,357 + 0,18 = 0,894 s`, `DPS = 23,52 / 0,894 = 26,3`.

### F5 — Recul et interruption du marteau

**Expression**

```text
K_eff  = K_w * (1 - r_kb)
Δcd    = S_w        si la cible prépare une attaque et n'est pas une élite
Δcd    = 0          sinon
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `K_w` | float | 0–60 | `weapon.knockback`. |
| `r_kb` | float | 0,0–1,0 | `EnemyData.knockback_resistance`. |
| `S_w` | float | 0,3–1,0 s ; 0 = désactivé | `weapon.stagger_seconds`. |
| `K_eff` | float | 0–60 px | Distance réellement parcourue par la cible. |
| `Δcd` | float | 0–1,0 s | Délai ajouté à la prochaine attaque de la cible. |

**Plage de sortie** — `K_eff` va de 0 (résistance totale) à `K_w` (aucune résistance). `Δcd` vaut 0 ou `S_w` ; jamais négatif. Les élites (`is_elite = true`) imposent `Δcd = 0` : c'est la soupape qui empêche le marteau de trivialiser le boss.

**Exemple chiffré** — Marteau (`K_w = 60`, `S_w = 0,6`) contre un squelette (`r_kb = 0`) : recul 60 px, préparation annulée, prochaine attaque +0,6 s. Contre le Seigneur (`r_kb = 0,85`) : recul `60 × 0,15 = 9 px`, aucune interruption.

### F6 — Tir tendu de l'arc

**Expression**

```text
D_dist = E[D_hit] * (1 + b_d * clamp(t / R_w_eff, 0, 1))
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `b_d` | float | 0,0–1,0 | `weapon.distance_damage_bonus` (0,5 pour l'arc). |
| `t` | float | 0–400 px | Distance parcourue par la flèche **à l'impact**. |
| `R_w_eff` | float | 40–400 px | `weapon.range_px * stats.range_mult`. |
| `D_dist` | float | `E[D_hit]` à `E[D_hit] × (1+b_d)` | Dégâts du coup à cette distance. |

**Plage de sortie** — de ×1,0 au contact à ×1,5 à portée maximale (`b_d = 0,5`). `t` est plafonné à `R_w_eff` ; une flèche qui vole plus loin n'existe pas, elle est libérée à la portée. Aucune valeur négative.

**Exemple chiffré** — Arc (`E[D_hit] = 9,72`, `b_d = 0,5`, `R_w_eff = 320`) : à 160 px, `9,72 × 1,25 = 12,15` ; à 320 px, `9,72 × 1,5 = 14,58`.

### F7 — Entaille circulaire de la faux

**Expression**

```text
N_circle   = |{e : distance(e, joueur) <= R_w_eff et e vivant}|
DPS_whirl  = DPS_1 * N_circle
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `N_circle` | int | 0–60 | Ennemis vivants distincts dans le cercle, chacun compté une fois. |
| `DPS_whirl` | float | 0 à `DPS_1 × 60` | DPS de zone du tour. |

**Plage de sortie** — 0 si aucun ennemi dans le rayon, jusqu'à `DPS_1 × 60`. Chaque ennemi est touché au plus une fois par tour : un ennemi qui reste dans le rayon pendant deux tours est touché à chaque tour, pas deux fois au même tour.

**Exemple chiffré** — Faux (`DPS_1 = 13,104`) entourée de 6 ennemis : `DPS_whirl = 78,62`.

### F8 — Perforation de l'arbalète

**Expression**

```text
D_k          = E[D_hit] * f_p^(k-1)          pour k = 1..K
DPS_pierce   = RPS_w * Σ(k=1..K) D_k
             = DPS_1 * (1 - f_p^K) / (1 - f_p)      si f_p ≠ 1
             = DPS_1 * K                            si f_p = 1
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `f_p` | float | 0,75–0,95 | `weapon.pierce_falloff` (0,85). |
| `k` | int | 1–K | Rang de l'ennemi vivant traversé ; les morts ne comptent pas. |
| `K` | int | 0–20 | Ennemis effectivement traversés par ce carreau. |
| `D_k` | float | `E[D_hit]` à `E[D_hit] × f_p^(K-1)` | Dégâts infligés au k-ième ennemi. |
| `DPS_pierce` | float | `DPS_1` à `DPS_1 / (1-f_p)` | DPS du carreau si K ennemis sont alignés. |

**Plage de sortie** — par carreau, de `E[D_hit]` (K=1) à l'asymptote `E[D_hit] / (1 - f_p) = 6,67 × E[D_hit]` pour `f_p = 0,85` quand la ligne est infinie ; en pratique K est borné par la longueur de la ligne et la portée. Aucune division par zéro : `f_p = 1` est traité par la branche linéaire.

**Exemple chiffré** — Arbalète (`E[D_hit] = 19,296`, `f_p = 0,85`) sur trois ennemis alignés : `19,296 + 16,402 + 13,941 = 49,64` par carreau ; à `RPS_w = 0,8`, `DPS_pierce = 39,71`.

### F9 — Chaîne du bâton

**Expression**

```text
D_k          = E[D_hit] * f_c^k              pour k = 0..J
DPS_chain    = RPS_w * E[D_hit] * Σ(k=0..J) f_c^k
             = DPS_1 * (1 - f_c^(J+1)) / (1 - f_c)
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `J` | int | 0–3 | `weapon.chain_jumps` (2). |
| `f_c` | float | 0,6–0,9 | `weapon.chain_falloff` (0,75). |
| `D_k` | float | `E[D_hit] × f_c^J` à `E[D_hit]` | Dégâts du k-ième maillon, k=0 = cible initiale. |
| `DPS_chain` | float | `DPS_1` à `DPS_1 × Σ f_c^k` | DPS du cast si tous les sauts trouvent une cible. |

**Plage de sortie** — de `DPS_1` (aucun saut possible, cible seule) à `DPS_1 × 2,3125` pour `J=2`, `f_c=0,75`. Un ennemi déjà touché par le cast est exclu ; un ennemi mort est exclu. Si `J=0`, la formule redonne `DPS_1`.

**Exemple chiffré** — Bâton (`E[D_hit] = 10,5`, `J=2`, `f_c=0,75`) : `10,5 + 7,875 + 5,906 = 24,28` par cast ; à `RPS_w = 1,1`, `DPS_chain = 26,71`.

### F10 — Orbe orbitale

**Expression**

```text
T_rev    = 2 * PI / ω_o
H_e      = min(1 / T_rev, 1 / c_o)
DPS_orb  = E[D_hit] * H_e * N_ring
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `ω_o` | float | 1,8–3,2 rad/s | `weapon.orbit_speed` (2,4). |
| `T_rev` | float | 1,96–3,49 s | Durée d'un tour complet. |
| `c_o` | float | 0,35–0,8 s | `weapon.orbit_hit_cooldown` (0,5). |
| `H_e` | float | 0–1 /s | Contacts par seconde sur un même ennemi ; le plus contraignant de « une fois par tour » et du cooldown. |
| `N_ring` | int | 0–60 | Ennemis distincts touchés par l'anneau pendant la fenêtre. |
| `DPS_orb` | float | 0 à `E[D_hit] × H_e × 60` | DPS total de l'orbe. |

**Plage de sortie** — par ennemi, `H_e = min(2,4/6,283, 1/0,5) = 0,382 /s`, soit 3,21 DPS. Avec 5 ennemis sur l'anneau, 16,04 DPS ; avec 10, 32,09. Aucune valeur négative. Le « une fois par tour » est un plafond dur : `H_e` ne peut jamais dépasser `ω/(2π)`.

**Exemple chiffré** — Orbe (`E[D_hit] = 8,4`, `ω=2,4`, `c=0,5`) : `T_rev = 2,618 s`, `H_e = min(0,382, 2) = 0,382`, `DPS` par ennemi = 3,21 ; cinq ennemis = 16,04.

### F11 — Détonation de l'encensoir

**Expression**

```text
t_det     = d_throw / v + F_w
D_fuse    = E[D_hit] * N_blast
DPS_fuse  = RPS_w * D_fuse
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `d_throw` | float | 0–220 px | Distance du jet jusqu'au point de chute. |
| `v` | float | 250–800 px/s | `weapon.projectile_speed` (300). |
| `F_w` | float | 0,6–1,2 s | `weapon.fuse_seconds` (0,9). |
| `t_det` | float | 0,9–1,9 s | Délai entre le lancer et l'explosion. |
| `N_blast` | int | 0–60 | Ennemis vivants dans `fuse_radius` au moment de la détonation. |
| `DPS_fuse` | float | 0 à `DPS_1 × 60` | DPS soutenu si chaque lancer touche N_blast ennemis. |

**Plage de sortie** — 0 si personne n'est dans le rayon à `t_det` ; jusqu'à `DPS_1 × 60` sur un paquet idéal. Le rayon (`fuse_radius = 70`) n'est pas multiplié par `range_mult` : seule la portée du jet l'est. Un seul jet de critique par détonation, partagé par toutes les cibles.

**Exemple chiffré** — Encensoir (`E[D_hit] = 23,1`, `RPS_w = 0,55`) sur 4 ennemis : `23,1 × 4 = 92,4` par détonation, `DPS_fuse = 50,82`. Sur une cible seule qui reste dans le rayon : `12,71`.

### F12 — Vol de vie de la lame vampire

**Expression**

```text
D_dealt = min(D_rolled, HP_cible_avant)
H       = min(D_dealt * L_w, HP_max - HP_courant) * (0 si élite sinon 1)
HPS     = RPS_w * E[H]
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `D_rolled` | float | `D_w*m_dmg` à `D_w*m_dmg*M_w` | Dégâts tirés, critique compris. |
| `HP_cible_avant` | float | 0–600 | Points de vie de la cible avant le coup ; le sur-dégât ne compte pas. |
| `L_w` | float | 0,15–0,35 | `weapon.lifesteal_ratio` (0,25). |
| `HP_max` | float | 1–300 | Points de vie maximum du joueur. |
| `HP_courant` | float | 0–`HP_max` | Points de vie actuels. |
| `H` | float | 0 à `min(D_hit*L_w, HP_max-HP_courant)` | Soin effectif du coup. |
| `HPS` | float | 0 à `E[D_hit]*L_w*RPS_w` | Soin par seconde sur une cible unique. |

**Plage de sortie** — 0 à PV plein, 0 sur une élite, 0 si la cible meurt sur le coup avec 0 PV restants. Le soin ne dépasse jamais les PV manquants. Aucune valeur négative.

**Exemple chiffré** — Lame vampire (`E[D_hit] = 12,32`, `L_w = 0,25`) : `3,08` PV par coup, `4,62 PV/s` à 1,5 att/s. De 50 à 100 PV, il faut 10,8 s de coups continus. Contre le Seigneur (`is_elite`), le soin est nul et le DPS reste 18,48.

### F13 — Probabilité d'une offre d'arme

**Expression**

```text
W_stat    = Σ(u ∈ améliorations) w_u
W_new     = n_new * w_weapon
n_new     = min(slots_libres, |pool| - armes_portées)
W_upgrade = n_up * w_upgrade
n_up      = |{armes portées dont le niveau < max_level}|
W_weapon  = W_new + W_upgrade      ← une seule ligne d'arme (A2)
W_equip   = w_equip * Σ(e ∈ équipement) poids_rareté(r_e)
W_total   = W_stat + W_weapon + W_equip
P_1(arme) = W_weapon / W_total
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `w_u` | float | 0,5–2,0 | Poids de chaque amélioration (1,0 dans les données actuelles). |
| `w_weapon` | float | 1,0–2,0 | `RunConfig.weapon_offer_weight` (1,4). |
| `n_new` | int | 0–2 | Acquisitions candidates après plafond par slot libre. |
| `w_upgrade` | float | 0,8–2,0 | `RunConfig.weapon_upgrade_weight` (1,4). |
| `n_up` | int | 0–3 | Armes portées sous leur niveau maximum. |
| `W_weapon` | float | 0–4,2 | Poids cumulé des deux types de ligne d'arme ; une seule sera tirée (`n_new + n_up ≤ 3` tant qu'aucune arme n'est au max). |
| `w_equip` | float | 0,5–2,0 | `RunConfig.equipment_offer_weight` (0,9). |
| `poids_rareté` | float | 0,12–1,0 | `EquipmentData.RARITY_WEIGHTS`. |
| `P_1(arme)` | float | 0–1 | Probabilité que le **premier** tirage du panneau soit une arme. |

**Plage de sortie** — 0 quand aucune acquisition ni aucun niveau n'est candidat (trois armes portées au max) ; au maximum quand `W_weapon` domine un pool d'équipement vide. Avec les données actuelles au départ (5 améliorations à 1,0, 2 acquisitions + 1 niveau candidats, 12 équipements de somme de rareté 7,29) : `W_stat = 5,0`, `W_weapon = 4,2`, `W_equip = 6,561`, `W_total = 15,761`, `P_1 = 26,6 %`.

**Invariance voulue.** Comme `w_weapon = w_upgrade = 1,4` et que `slots_libres + armes_portées = 3`, `W_weapon` vaut `4,2` **quel que soit le loadout** tant qu'aucune arme n'est au max : une arme de départ (2 acquisitions + 1 niveau) pèse autant que trois armes montables (0 acquisition + 3 niveaux). La part d'arme du panneau ne dépend donc ni du nombre d'armes portées ni de la taille du catalogue. Elle ne baisse que quand une arme atteint son max : trois armes dont une au max donnent `2,8 / 14,361 = 19,5 %`. La probabilité qu'au moins une arme apparaisse dans les trois tirages est mesurée par simulation sur le vrai chemin d'offre (`tools/weapon_upgrade_sim.gd`, lot 1) : 10,4 panneaux sur 15 en politique aléatoire à poids 1,4, soit 69 % ; aucune formule fermée n'est revendiquée.

**Exemple chiffré** — Départ de run, épée en main, deux slots libres : `P_1(arme) = (2 × 1,4 + 1 × 1,4) / 15,761 = 0,266`. Après trois armes portées, toutes montables : `(0 + 3 × 1,4) / 15,761 = 0,266`. Trois armes dont une au max : `2,8 / 14,361 = 0,195`. Toutes au max : `W_weapon = 0`, `P_1(arme) = 0`.

### Tableau 4.14 — DPS de référence à stats de base

| Arme | `E[D_hit]` | DPS cible unique | Condition de pointe | DPS de pointe |
|---|---|---|---|---|
| Épée longue | 12,60 | 22,68 | 3 cibles dans le cône | 68,04 |
| Dague | 7,84 | 21,95 | exécution à 0,18 s | 43,56 |
| Marteau | 26,94 | 18,86 | 4 cibles dans 160° | 75,44 |
| Arc court | 9,72 | 11,66 | portée maximale (×1,5) | 17,50 |
| Faux | 14,56 | 13,10 | 6 cibles sur 360° | 78,62 |
| Arbalète | 19,30 | 15,44 | 3 ennemis alignés | 39,71 |
| Bâton | 10,50 | 11,55 | 2 sauts | 26,71 |
| Orbe | 8,40 | 3,21 par ennemi | 5 ennemis sur l'anneau | 16,04 |
| Encensoir | 23,10 | 12,71 | 4 ennemis dans le blast | 50,82 |
| Lame vampire | 12,32 | 18,48 | +4,62 PV/s | 18,48 + soin |

Aucune ligne n'est supérieure à toutes les autres : l'épée gagne la constance, la dague l'exécution, le marteau l'interruption, l'arc la distance, la faux l'encerclement, l'arbalète la ligne, le bâton la grappe, l'orbe le passif, l'encensoir la prédiction, la vampire la survie.

## Edge Cases

Chaque cas ci-dessous a un résultat déterministe et doit devenir un test en W2-E4.

| # | Cas | Résultat attendu |
|---|---|---|
| E1 | **La cible meurt pendant la chaîne du bâton.** | La chaîne continue depuis la dernière position de la cible morte ; les ennemis morts sont exclus des candidats. Un ennemi déjà touché par ce cast ne peut pas être choisi à nouveau. Si plus aucun candidat vivant n'existe dans le rayon, la chaîne s'arrête sans erreur. |
| E2 | **L'orbe touche le même ennemi deux fois pendant un tour.** | Interdit. Un ensemble d'ennemis touchés est vidé à chaque tour complet ; un ennemi ne peut être touché qu'une fois par tour, et jamais plus d'une fois par `orbit_hit_cooldown`. Le plafond le plus contraignant gagne. |
| E3 | **Détonation de l'encensoir après la mort du porteur.** | La détonation a lieu à l'heure prévue même si le joueur est mort : le monde continue de s'écouler jusqu'à l'écran de fin. Si la run se termine avant `t_det`, les détonations en attente sont libérées sans dégâts. Les dégâts sont attribués à l'arme, jamais au joueur. |
| E4 | **L'arbalète traverse un ennemi déjà mort.** | L'ennemi mort est ignoré : il ne prend aucun dégât, **n'incrémente pas** le rang `k` et ne consomme pas de chute de perforation. Le carreau continue vers le prochain ennemi vivant. |
| E5 | **Vol de vie sur un boss immunisé.** | Le boss est une élite (`EnemyData.is_elite = true`) : il prend les dégâts normaux, mais `H = 0`. Aucune erreur, aucun soin, le nombre de dégâts s'affiche normalement. Si un futur ennemi non élite doit être immunisé, on ajoute `EnemyData.lifesteal_immune` (défaut faux) plutôt que de changer la règle des élites. |
| E6 | **Deux armes identiques portées.** | Impossible par les offres et par `Inventory.add_weapon` : `has_weapon` compare par `id`. Si un chemin de debug force l'ajout, la seconde est refusée. Deux `.tres` de même `id` sont un défaut de données ; le test de W2-E4 exige des `id` uniques. |
| E7 | **Une arme est offerte alors que les trois slots sont pleins.** | Ne se produit pas **pour une acquisition** : `_build_offers` n'en crée aucune quand `free_weapon_slots() == 0`. Les lignes de niveau, elles, restent proposées (E21). Si un appelant force une acquisition, `Inventory.add_weapon` la refuse et l'offre est un no-op ; W2-E2 journalise un avertissement. Le joueur ne perd jamais un choix dans le flux normal. |
| E8 | **Un reroll alors que les slots sont pleins.** | Le reroll reconstruit le panneau sans aucune acquisition, mais peut y remettre une ligne de niveau si une arme portée est sous son max ; les améliorations et l'équipement restent disponibles. Le compteur de rerolls est débité normalement. |
| E9 | **Le pool d'offres serait vide.** | Impossible : les cinq améliorations ne s'épuisent pas et restent candidates. Si un appelant vide le pool, `_build_offers` retourne un tableau vide, le panneau ne s'ouvre pas et le niveau reste acquis ; aucun blocage de boucle. |
| E10 | **L'arc touche au contact.** | `t = 0` : multiplicateur ×1,0, jamais négatif. La distance est mesurée à l'impact, pas au tir ; une cible qui avance vers la flèche réduit le bonus. |
| E11 | **La cible de l'encensoir meurt avant l'atterrissage.** | Le projectile atterrit à la dernière position connue de la cible et la mèche continue. S'il n'y avait aucune cible au lancer, l'encensoir part vers le point d'aimantation à portée et explose au bout de sa course. |
| E12 | **Deux détonations se chevauchent.** | Chaque détonation est indépendante et inflige ses dégâts à chaque ennemi dans son rayon. Rien ne plafonne le cumul : la cadence de 0,55/s est le seul limiteur. |
| E13 | **La chaîne saute hors de la portée du bâton.** | Autorisé : le rayon de saut (90 px) est mesuré depuis la cible précédente, pas depuis le joueur. `range_mult` ne modifie pas `chain_jump_radius`. |
| E14 | **Le marteau frappe le boss pendant son annonce de slam.** | Les élites sont immunisées à l'interruption : le slam n'est pas annulé, le recul est réduit par `knockback_resistance` (9 px). Seuls les ennemis non élites perdent leur préparation. |
| E15 | **L'exécution de la dague tue un boss.** | Le cooldown est ramené au plancher, mais la run se termine ou le boss meurt : l'effet est sans conséquence. Le plancher reste appliqué pour ne pas dépendre de l'ordre des callbacks. |
| E16 | **Le vol de vie dépasse les PV manquants.** | Le soin est plafonné par `HP_max - HP_courant` ; aucun dépassement, aucun soin « stocké ». À PV plein, `H = 0`. |
| E17 | **Le vol de vie frappe un coup sur-dégât.** | `D_dealt = min(D_rolled, HP_cible_avant)` : un coup de 12 sur une cible à 3 PV ne rend que 25 % de 3, pas de 12. |
| E18 | **Un jeton `mechanic` inconnu.** | La ressource charge quand même. `has_known_mechanic()` retourne faux ; W2-E2 traite l'arme comme `cleave` et émet un `push_warning`. Le test de données de W2-E4 échoue sur tout jeton absent de `MECHANICS`. |
| E19 | **Un projectile touche une cible pendant que le porteur change d'arme.** | Le projectile et le coup en vol capturent la `WeaponData` au moment du tir ; une modification d'inventaire ne change pas les dégâts d'un trait déjà parti. |
| E20 | **`range_mult` et les mécaniques.** | `range_mult` multiplie `range_px` et `orbit_radius` ; il ne multiplie ni `fuse_radius`, ni `chain_jump_radius`. Une amélioration de portée ne doit pas agrandir un blast ou une chaîne sans le dire. |
| E21 | **Une arme atteint son niveau maximum.** | Elle sort du pool de niveaux ; si rien ne reste, le panneau se replie sur les améliorations de stat (E9). Une offre `weapon_upgrade` forcée sur une arme au max est un no-op : `Inventory.upgrade_weapon` retourne faux et le niveau ne dépasse jamais `max_level`. |
| E22 | **Une acquisition et un niveau dans le même panneau.** | Impossible par construction (A2) : une seule ligne d'arme par panneau. Une implémentation qui en montrerait deux échoue au test d'intégration, pas au hasard du tirage. |
| E23 | **Un niveau est choisi pendant que l'arme frappe.** | Le coup déjà parti garde les dégâts calculés à son niveau de tir (E19) ; le niveau suivant s'applique au coup suivant. Le cooldown en cours n'est pas remis à zéro : monter une arme ne donne pas de coup gratuit. |
| E24 | **Une arme est remplacée.** | `Inventory.replace_weapon` oublie le niveau de l'arme sortante ; la nouvelle entre au niveau 1. Le niveau appartient à l'arme, pas à l'emplacement. |
| E25 | **Une nouvelle run démarre.** | `Inventory.setup_starting` vide `weapon_levels` : aucun niveau ne survit d'une run à l'autre, puisque la `WeaponData` est partagée. |

## Dependencies

| Système | Sens | Ce que ce document attend | Propriétaire |
|---|---|---|---|
| `src/data/weapon_data.gd` | fournit | `mechanic`, `MECHANICS`, `has_known_mechanic()`, clés de localisation et champs de mécanique, plus `max_level` et les trois `level_*_step` (lot 1). Les quatre armes existantes gardent leurs valeurs. | W2-E1 (ce document) |
| `src/systems/weapon_system.gd`, `src/actors/projectile.gd` | consomme | Résolution des dix jetons, ciblage, résolution différée de la mèche, orbe, chaîne, perforation, vol de vie. Aucune mécanique n'est implémentée ici. | W2-E2 |
| `src/data/catalogue.tres` | consomme | **Reste à 4 armes jusqu'à W2-E2.** W2-E2 ajoute les six armes et passe `EXPECTED_WEAPONS` à 10 dans le même changement. | W2-E2, test `data_catalogue_test.gd` |
| `design/gdd/enemy-behaviors.md` | croisé | Les colonnes Marcheur à Invocateur, les annonces, `is_elite`, la préparation interruptible, `knockback_resistance`. Ce document ne modifie pas ce GDD ; son propriétaire doit citer `weapons.md` pour la matrice et l'interruption. | W1-E0 (`game-designer`) |
| `design/gdd/classes.md` | croisé | Les armes de départ des trois classes pointent vers des `id` de ce document. Ne pas inventer un `id` d'arme hors de cette liste. | W3-E1 |
| `design/gdd/systems-index.md` | croisé | Doit lister `weapons.md`. Un autre agent le crée ; ce document ne l'édite pas. | Orchestrateur / `game-designer` |
| `EnemyData` | fournit | `max_hp`, `knockback_resistance`, `is_elite` (interruption et vol de vie), les états de préparation W1. | W1-E1/E2, W0-E3 |
| `Stats` / `DamageCalc` | fournit | `damage_mult`, `attack_speed_mult`, `range_mult`, `crit_chance_bonus`, tirage de critique injecté, plus les méthodes à niveau explicite `weapon_damage(weapon, level)`, `weapon_attacks_per_second`, `weapon_range`, `level_*_multiplier` (lot 1). | existant, étendu par le lot 1 |
| `Inventory` | fournit | Trois slots, `has_weapon` par `id`, `free_weapon_slots`, `add_weapon`, `replace_weapon`, plus `weapon_levels`, `level_of`, `upgrade_weapon`, `can_upgrade_weapon` (lot 1). | existant, étendu par le lot 1 |
| `Player.heal` | fournit | Le vol de vie utilise l'API de soin existante, plafonnée par `stats.max_hp`. | existant |
| `Offer` / `main.gd` / `hud.gd` | consomme | Nommer la mécanique dans l'offre, plafonner les acquisitions par slot, ne jamais offrir de doublon, une seule ligne d'arme par panneau. Le lot 1 ajoute `Offer.for_weapon_upgrade`, la décoration au niveau visé, `_upgrade_weapon` et le niveau dans le HUD. W2-E2 modifie `Offer.for_weapon` et `_decorate_offer` ; W8-E2 branche les clés. | W2-E2, W8-E2, lot 1 |
| `RunConfig` | fournit | `weapon_offer_weight = 1,4`, `weapon_upgrade_weight = 1,4` (lot 1), `equipment_offer_weight = 0,9`, `reroll_base = 2`, `reroll_levels = [10, 20]`, poids de butin de boss. | W0-E3, lot 1 |
| `docs/localization-standard.md` | fournit | Convention `weapon.<id>.name` / `weapon.<id>.desc`. Si le standard renomme le motif, W8-E2 met à jour les dix `.tres` en une passe. | W8-E1 |
| `design/art/art-bible.md` | croisé | Silhouettes des six nouvelles armes, couleurs et formes. Les tokens `shape` de ce document sont des intentions ; l'art tranche. | W2-E3 |
| W4 (boutique et prix) | consomme | Si un prix par rareté apparaît, la non-domination est prouvée **par palier de prix**, pas globalement. | W4-E1/E2 |

**Réciprocité.** `enemy-behaviors.md` et `classes.md` sont écrits par d'autres agents et ne sont **pas** modifiés ici (contrainte du brief). Leurs propriétaires doivent citer `weapons.md` pour la matrice 10×10, l'interruption du marteau et les armes de départ. `systems-index.md` doit référencer ce document.

## Tuning Knobs

| Paramètre | Valeur par défaut | Plage sûre | Effet si on sort de la plage |
|---|---|---|---|
| `weapon.damage` | 7–26 | 5–35 | Sous 5, une arme devient un gadget ; au-dessus de 35, elle domine les autres au même prix. |
| `weapon.attacks_per_second` | 0,55–2,8 | 0,4–3,2 | Sous 0,4, la cadence est illisible ; au-dessus de 3,2, les coups s'empilent dans la même image. |
| `weapon.range_px` | 42–380 | 36–420 | Une portée de mêlée sous 36 px ne se lit plus ; au-dessus de 420, l'arbalète/arc trivialise les tireurs. |
| `weapon.arc_degrees` | 40–360 | 30–360 | Sous 30°, le cône rate la cible visée par la visée automatique. 360° est un cas à part (faux, orbe). |
| `weapon.swing_duration` | 0,08–0,28 | 0,06–0,32 | Sous 0,06, l'impact est instantané et illisible ; au-dessus de 0,32, le coup rate une cible qui bouge. |
| `weapon.crit_chance` | 0,03–0,12 | 0,02–0,15 | Au-delà de 0,15, le plafond de 0,75 est atteint trop vite avec l'équipement. |
| `weapon.crit_multiplier` | 2,0–2,2 | 1,8–2,4 | Sous 1,8, le critique ne se sent plus ; au-dessus de 2,4, la variance écrase la lecture. |
| `weapon.knockback` | 0–60 | 0–70 | Au-delà de 70, les ennemis sortent de l'écran et la mêlée se vide. |
| `weapon.projectile_speed` | 300–780 | 250–850 | Sous 250, le projectile rate les cibles rapides ; au-dessus de 850, il traverse sans se voir. |
| `execution_floor` | 0,18 | 0,12–0,25 | Sous 0,12, la dague devient une mitrailleuse ; au-dessus de 0,25, l'exécution ne se sent plus. |
| `stagger_seconds` | 0,6 | 0,3–1,0 | Sous 0,3, l'interruption ne change pas la vague ; au-dessus de 1,0, le marteau verrouille les chargeurs. |
| `distance_damage_bonus` | 0,50 | 0,25–0,75 | Sous 0,25, le tir tendu n'est qu'un chiffre ; au-dessus de 0,75, l'arc domine à distance. |
| `pierce_falloff` | 0,85 | 0,75–0,95 | Sous 0,75, la ligne ne vaut plus le repositionnement ; au-dessus de 0,95, l'arbalète perce sans coût. |
| `chain_jumps` | 2 | 1–3 | À 3, le bâton atteint l'invocateur derrière deux lignes ; au-delà, il devient une arme de zone sans risque. |
| `chain_jump_radius` | 90 | 60–120 | Sous 60, les ennemis doivent être collés ; au-dessus de 120, la chaîne traverse un écran. |
| `chain_falloff` | 0,75 | 0,60–0,90 | Sous 0,60, les sauts ne paient pas ; au-dessus de 0,90, le bâton domine les armes de zone. |
| `orbit_radius` | 46 | 36–60 | Sous 36, l'orbe est dans le corps du joueur ; au-dessus de 60, elle sort de la mêlée. |
| `orbit_speed` | 2,4 | 1,8–3,2 | Sous 1,8, un tour dure plus de 3,5 s ; au-dessus de 3,2, l'orbe devient un mur. |
| `orbit_hit_cooldown` | 0,5 | 0,35–0,80 | Sous 0,35, le même ennemi peut être touché deux fois par tour ; au-dessus de 0,80, l'orbe ne paie plus. |
| `fuse_seconds` | 0,9 | 0,6–1,2 | Sous 0,6, la décision disparaît ; au-dessus de 1,2, le chargeur a toujours quitté le rayon. |
| `fuse_radius` | 70 | 50–90 | Sous 50, le blast ne couvre pas un paquet ; au-dessus de 90, l'encensoir remplace la faux. |
| `lifesteal_ratio` | 0,25 | 0,15–0,35 | Sous 0,15, le soin ne compense pas le contact ; au-dessus de 0,35, la lame vampire devient obligatoire. |
| `RunConfig.weapon_offer_weight` | 1,4 | 1,0–2,0 | Sous 1,0, les armes manquent ; au-dessus de 2,0, le panneau noie les améliorations. |
| `RunConfig.weapon_upgrade_weight` | 1,4 | 0,8–2,0 | Sous 0,8, une arme portée monte à peine (1,6 niveau par run au tirage aléatoire) ; au-dessus de 2,0, la ligne d'arme écrase les stats et l'équipement. **À 1,4, acquisitions et niveaux pèsent le même poids par candidat** : la part d'arme du panneau devient indépendante du loadout (F13). |
| `RunConfig.reroll_base` | 2 | 1–3 | 1 rend le reroll trop rare ; 3 le banalise. |
| `RunConfig.reroll_levels` | [10, 20] | niveaux 8–12 et 18–22 | Trop tôt, le reroll remplace la décision de build ; trop tard, il ne sert plus. |

**Règle de tuning.** Toute modification d'un de ces paramètres doit être justifiée par une ligne du §4.14 et par la matrice §3.7. Un réglage qui rend une arme supérieure ou égale sur les dix colonnes doit être refusé ou compensé.

## Acceptance Criteria

| # | Critère | Comment le vérifier |
|---|---|---|
| AC1 | `src/data/weapon_data.gd` parse sans erreur et expose `mechanic`, `MECHANICS`, `has_known_mechanic()`, les clés et les champs de mécanique. | `--headless --check-only` sur le script, exit 0 ; aucune API existante retirée. |
| AC2 | Les quatre armes existantes fonctionnent à l'identique : mêmes valeurs numériques qu'avant W2-E1, catalogue à 4 armes, `data_catalogue_test.gd` vert. | Diff des quatre `.tres` : seuls les champs ajoutés diffèrent ; la suite reste à 58 tests / 11 suites, exit 0. |
| AC3 | Les six nouveaux `.tres` se chargent et portent chacun un `id` unique, un `mechanic` de `MECHANICS`, `name_key = "weapon.<id>.name"`, `description_key = "weapon.<id>.desc"`. | Test de données W2-E4 : charge les dix `.tres`, vérifie l'unicité et les clés. |
| AC4 | Aucune arme n'est strictement meilleure qu'une autre au même prix. | Encoder les verdicts de la §3.7 (`Très fort`=3, `Fort`=2, `Moyen`=1, `Faible`=0) et vérifier qu'aucune paire A,B ne satisfait « A ≥ B partout et A > B quelque part ». |
| AC5 | Chaque arme a au moins une case `Fort` ou `Très fort` et au moins une case `Faible` dans la matrice. | Lecture automatique de la grille de verdicts ; échec sur une ligne uniforme. |
| AC6 | Trois runs d'affilée proposent des builds différents. | Simulation de trois séquences d'offres avec trois graines, même classe : les ensembles finaux de trois armes diffèrent deux à deux (au moins une arme change). W2-E4. |
| AC7 | Aucune arme n'est offerte **en acquisition** quand les trois slots sont pleins ; une arme au max n'est jamais offerte en niveau ; aucun doublon n'est offert. | Test existant de plafond (acquisitions) + test W2-E4 avec un inventaire plein et un inventaire contenant déjà l'arme ; `weapon_upgrade_offers_test.gd` pour le plafond de niveau. |
| AC8 | Chaque offre d'arme nomme sa mécanique avant les nombres. | Générer une `Offer` pour chacune des dix armes et vérifier que la description contient le texte de `description`/`description_key` en tête. W2-E2. |
| AC9 | Tous les cas limites E1–E25 ont un résultat déterministe et un test. | Un test par cas, ou un test paramétré ; aucun cas sans assertion. |
| AC10 | La matrice 10×10 est complète : 10 lignes, 10 colonnes, aucune case vide. | Lecture du tableau ; 100 cases non vides. |
| AC11 | Le catalogue reste à 4 armes tant que W2-E2 n'a pas implémenté les mécaniques. | `data_catalogue_test.gd` : `EXPECTED_WEAPONS := 4` non modifié, suite verte. |
| AC12 | Une arme portée sous `max_level` est reproposée comme niveau ; une arme au max ne l'est jamais ; un panneau ne porte qu'une ligne d'arme. | `tests/integration/weapon_upgrade_offers_test.gd` (8 tests) vert. |
| AC13 | Le niveau est additif sur la base, appliqué avant les multiplicateurs globaux ; la cadence gagne 5 % par niveau ; le niveau 4 vaut ×1,75 dégâts. | `tests/unit/weapon_levels_test.gd` (12 tests) vert. |
| AC14 | Le niveau est un état de run : remplacement et nouvelle run repartent au niveau 1. | `weapon_levels_test.gd` : remplacement, `setup_starting`, niveaux négatifs lus comme 1. |
| AC15 | Le poids de niveau est choisi sur le vrai chemin d'offre, pas sur un modèle. | `tools/weapon_upgrade_sim.gd` : 200 runs × 15 panneaux × 2 politiques ; à 1,4, 10,4 lignes d'arme et 2,1 niveaux par run en aléatoire, 7,2 niveaux et 13,5 % de runs tout-au-max en greedy. |
| AC16 | L'offre de niveau affiche le niveau visé et les nombres effectifs au niveau visé. | Test d'intégration : titre contient « niv. 2 », description contient « niv. 1 → 2 » et « DPS ». |
