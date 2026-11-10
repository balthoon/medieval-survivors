# Classes et règles signature

> **Status**: Designed
> **Author**: game-designer (W3-E1)
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: 1 — Chaque run est différent · 3 — Le joueur a toujours un choix qui compte
> **Epic**: W3-E1 — Concevoir les trois classes
> **Suite**: W3-E2 (`ClassData` et règle signature), W3-E3 (silhouettes), W3-E4 (écran)

## Overview

Le jeu propose trois classes jouables, choisies **une fois, avant la vague 1**, sur un écran clavier. Le Chevalier reste la référence du build : 100 PV, 220 px/s, épée longue. La Chasseresse joue à distance (80 PV, 240 px/s, arc court) et ne fait de dégâts utiles qu'en tenant la meute à 200–300 px. Le Pénitent joue la masse (140 PV, 170 px/s, marteau) et doit s'immobiliser pour gagner sa réduction de dégâts et son bonus de frappe.

Chaque classe est un `ClassData` (identifiant stable, PV, vitesse, multiplicateurs de dégâts et de cadence), **une arme de départ existante** et **une règle signature** qui n'appartient qu'à elle. Une signature n'est pas un bonus plat : elle impose une décision positionnelle toutes les quelques secondes. Le Chevalier entretient des piles de Sang-froid en évitant les coups ; la Chasseresse gagne jusqu'à +50 % de dégâts avec la distance parcourue par son projectile ; le Pénitent gagne 20 % de réduction de dégâts et 15 % de dégâts tant qu'il ne bouge pas, avec 0,5 s de grâce au redémarrage.

La classe ne change ni l'arène, ni les vagues, ni le pool d'offres, ni la rareté, ni le nombre de rerolls, ni les boss. Elle change les nombres de départ, l'arme initiale et une règle de combat. Les trois classes doivent battre le premier boss avec trois stratégies différentes : esquiver et entretenir, rester loin, ou s'ancrer et encaisser.

## Player Fantasy

### Fantasy par classe

| Classe | Fantasy en une phrase | Ce que le joueur ressent |
| --- | --- | --- |
| **Chevalier** | « L'équilibre : tenir la ligne juste, sans une égratignure. » | La maîtrise propre. Chaque seconde sans être touché aiguise la lame ; une erreur remet le compteur à zéro. |
| **Chasseresse** | « La distance : la marge est mon arme. » | Le contrôle de l'espace. La meute est un problème de distance, pas de puissance ; être collée est une punition, pas un accident. |
| **Pénitent** | « La masse : je ne cours pas, je pèse. » | Le poids et la patience. S'arrêter est un acte ; le sol appartient à celui qui accepte d'y rester. |

### Aesthetics MDA visées

- **Chevalier** : *Challenge* (éviter), *Expression* (tenue de la ligne), *Mastery* au sens de la compétence lisible. C'est la classe qui enseigne l'arène.
- **Chasseresse** : *Challenge* (gestion de la distance), *Fantasy* (l'archer de la marge), *Sensation* (trait qui part loin).
- **Pénitent** : *Sensation* (impact lourd, recul, hitstop), *Challenge* (timing d'ancrage et d'esquive), *Fantasy* (la masse de la page).

### Besoins psychologiques (SDT)

- **Autonomie** : trois réponses viables à la même arène, choisies au départ. Aucune classe n'est un tutoriel déguisé ; chacune gagne à être jouée autrement.
- **Compétence** : chaque signature a une feedback immédiat et nommable — piles de Sang-froid, bande de distance, état d'ancrage. Le joueur doit pouvoir dire *pourquoi* il a réussi ou échoué.
- **Relatedness** : la fiction de la page et de la marge porte les trois figures ; aucune classe n'est une autre histoire. La Chasseresse et le Pénitent sont des figures de la même page que le Chevalier.

### Flow et courbe de difficulté

- **Vague 1** : chaque classe enseigne sa question sans ennemi nouveau. Le Chevalier apprend à ne pas être touché, la Chasseresse à tenir la bande 200–300 px, le Pénitent à s'arrêter et balayer.
- **Vagues 3–4** : le loup (130 px/s) punit la Chasseresse qui recule en ligne droite et le Pénitent qui veut courir. L'orc (56 PV) récompense le balayage groupé du Pénitent et le maintien des piles du Chevalier (4 coups au lieu de 5).
- **Vague 5** : le premier Seigneur est le test de lecture de chaque signature. Le Chevalier esquive et garde ses piles, la Chasseresse tient 300 px, le Pénitent s'ancre entre deux slams.
- **Dents de scie** : une vague de tension (3–4), un relâchement au level-up, le pic du boss 5, puis une remontée à la vague 10. La classe ne change pas la courbe ; elle change la réponse du joueur.

## Detailed Design (Detailed Rules)

### 1. Les trois classes

Les identifiants sont **stables, ASCII, minuscules, jamais traduits ni renommés** après sauvegarde. Les noms affichés sont des clés de localisation (W8-E1) ; le français ci-dessous est le repli.

| id | Nom affiché (fr) | PV | Vitesse | `damage_mult` | `attack_speed_mult` | Arme de départ | Signature |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `chevalier` | Chevalier | 100 | 220 px/s | 1,00 | 1,00 | `epee_longue` | `sang_froid` |
| `chasseresse` | Chasseresse | 80 | 240 px/s | 0,90 | 1,20 | `arc_court` | `trait_de_marge` |
| `penitent` | Pénitent | 140 | 170 px/s | 1,15 | 0,85 | `marteau` | `ancrage` |

**Pourquoi ces multiplicateurs.** Le produit `damage_mult × attack_speed_mult` est proche de 1,00 pour les trois classes (Chevalier 1,00 ; Chasseresse 1,08 ; Pénitent 0,98). La classe ne donne pas un avantage de DPS brut : elle change le **profil** des coups (petits et rapides, ou gros et lents) et laisse la signature faire la différence situationnelle. Les valeurs sont additives avec les améliorations existantes : `damage_mult` final = multiplicateur de classe + somme des bonus d'amélioration et d'équipement.

#### 1.1 Chevalier — `chevalier`

- **Rôle** : la référence. Il enseigne l'arène, la portée de l'épée et l'esquive.
- **Départ** : 100 PV, 220 px/s, `epee_longue` (12 dégâts, 1,8 att/s, 64 px, 90°, 5 % critique ×2, 28 recul).
- **Vague 1** : entrer dans la portée de 64 px, balayer plusieurs squelettes dans le cône de 90°, ressortir avant le contact. Le premier level-up arrive vers 5 XP, soit 5 squelettes, au milieu de la vague.
- **Signature `sang_froid`** : voir 2.1.

#### 1.2 Chasseresse — `chasseresse`

- **Rôle** : la distance et la mobilité. Elle ne gagne pas en restant collée.
- **Départ** : 80 PV, 240 px/s, `arc_court` (9 dégâts, 1,2 att/s, 320 px, projectile 620 px/s, 8 % critique ×2). Multiplicateurs : dégâts ×0,90, cadence ×1,20.
- **Vague 1** : rester à 200–300 px du squelette le plus proche, laisser l'arc tirer automatiquement sur la cible la plus proche dans 320 px, tourner autour de l'arène. À moins de 100 px, l'arc perd tout bonus de distance et met trois tirs par squelette ; à 300 px, deux tirs suffisent.
- **Signature `trait_de_marge`** : voir 2.2.
- **Arme de départ** : l'arc court est déjà dans le pool du build ; W3-E2 n'ajoute aucune arme. Les armes à projectile supplémentaires arrivent avec W2-E1/E2.

#### 1.3 Pénitent — `penitent`

- **Rôle** : la masse, la patience, le placement. Il ne peut pas courir ; il peut tenir.
- **Départ** : 140 PV, 170 px/s, `marteau` (26 dégâts, 0,7 att/s, 80 px, 160°, 60 recul, 3 % critique ×2,2). Multiplicateurs : dégâts ×1,15, cadence ×0,85.
- **Vague 1** : marcher jusqu'à la meute, s'arrêter 0,75 s, balayer 160° (le marteau tue un squelette en un coup à 29,9 dégâts), encaisser, faire un pas, se ré-ancrer. Il ne chasse pas un ennemi isolé : il laisse la meute se grouper.
- **Signature `ancrage`** : voir 2.3.

### 2. Règles signature

Une signature est une règle **exécutable** : déclencheur, effet, formule, plafond. Elle n'ajoute aucun bouton, aucun ciblage manuel et aucune ressource à dépenser. Les valeurs sont des exports de données (voir 7), jamais des constantes de code.

#### 2.1 Chevalier — `sang_froid`

**Déclencheur.** Le temps sans avoir subi de dégâts s'accumule pendant que la run n'est pas en pause. Chaque seconde pleine accorde une pile de Sang-froid, jusqu'à 10 piles.

**Effet.** Chaque pile ajoute +2 % de dégâts à toutes les armes du Chevalier. Le bonus est un **multiplicateur de signature** appliqué après le multiplicateur de dégâts de base et avant le critique (voir 4.2). À 10 piles : ×1,20.

**Remise à zéro.** Tout événement qui retire au moins 1 PV au joueur remet les piles à 0 et le chronomètre à 0. L'invulnérabilité de 0,4 s après un coup ne protège pas les piles : le premier coup les annule.

**Plafond.** 10 piles, +20 %. Pas de décroissance tant que le joueur n'est pas touché. La pause (panneau de level-up, butin de boss) ne fait pas avancer le chronomètre.

**Lecture.** Le joueur doit voir les piles (compteur ou jauge) et le moment de la remise à zéro. Un état sans feedback est un échec d'acceptation.

#### 2.2 Chasseresse — `trait_de_marge`

**Déclencheur.** Un projectile touche un ennemi. La distance `d` est la distance réellement parcourue par le projectile au moment de l'impact (`Projectile.travelled`).

**Effet.** Le multiplicateur de distance est :

```text
m_distance = 1 + bonus_max × clamp((d - d_min) / (d_plein - d_min), 0, 1)
```

avec `d_min = 100 px`, `d_plein = 300 px`, `bonus_max = 0,50`.

- `d ≤ 100` : ×1,00.
- `d = 200` : ×1,25.
- `d ≥ 300` : ×1,50 (plafond, même si une future arme porte plus loin).

**Portée de la règle.** Elle s'applique à **tous les projectiles de la Chasseresse**, pas seulement à l'arc de départ : toute arme à projectile qu'elle ramasse en profite. Elle ne s'applique **pas** aux armes de mêlée, qui restent à ×1,00. Ce n'est pas une punition : la mêlée reste une option de survie à courte portée, simplement sans le bonus de la marge.

**Ordre des opérations.** Jet de critique, puis multiplicateur de distance, puis application des dégâts. Un critique à 300 px vaut donc ×2 (critique) ×1,50 (marge). Le montant final, bonus compris, est celui porté par `hit_resolved` et par les nombres flottants.

**Pourquoi 100/300.** L'arc court porte à 320 px. La bande 200–300 px est la seule où la Chasseresse est à la fois en sécurité et à pleine puissance. À 100 px, elle est déjà en danger ; le bonus doit donc commencer à décroître avant.

#### 2.3 Pénitent — `ancrage`

**Déclencheur.** Le Pénitent est **immobile** : sa position n'a pas varié de plus de 0,5 px sur les 0,1 dernières secondes. Tenir une direction contre le bord de l'arène compte comme immobile, car la position ne change pas. Après 0,75 s d'immobilité, il est **ancré**.

**Effet pendant l'ancrage.**
- Dégâts reçus ×0,80 (réduction de 20 %).
- Dégâts d'arme ×1,15 (multiplicateur de signature, avant le critique).
- Recul infligé ×1,25 (le marteau passe de 60 à 75 px avant résistance de la cible).

**Fin de l'ancrage.** Dès que la position varie de plus de 0,5 px, l'ancrage persiste **0,5 s de grâce**, puis tombe. S'il s'arrête à nouveau, le chronomètre de 0,75 s repart de zéro : un pas coûte toujours 1,25 s de buff (0,5 s de grâce + 0,75 s de ré-ancrage), pas seulement le pas.

**Plancher de dégâts.** Les dégâts reçus après réduction ne descendent jamais sous **1,0 PV**. L'ancrage ne peut pas créer un état invulnérable. La réduction s'applique aux dégâts de contact et au slam du boss.

**Lecture.** L'état ancré doit être lisible sans couleur seule : par exemple, une ombre au sol qui se resserre ou un anneau d'encre qui se ferme (W3-E3 décide la forme). Le joueur doit savoir quand il perd l'ancrage avant de le perdre.

### 3. Ce qu'une classe ne change pas

- **Pas de ciblage manuel.** La visée automatique sur l'ennemi le plus proche reste celle du build (décision verrouillée). La Chasseresse ne vise pas : elle choisit sa distance.
- **Pas de changement de hitbox.** Le rayon du joueur reste **14 px** pour les trois classes. Le Pénitent lit « large » par sa silhouette et son marteau, pas par une hitbox plus grosse : une hitbox plus grande serait une pénalité invisible et contredirait la bible d'art (« le joueur reste la plus petite forme occupée »).
- **Pas de changement de contrôles.** Mêmes actions de déplacement, même `ui_accept`, mêmes `choice_1..3`, même `reroll`. La classe n'ajoute aucun bouton.
- **Pas de changement de structure.** 10 vagues de 20 s, boss aux vagues 5 et 10, 3 armes maximum, 3 offres par level-up, 2 rerolls de base. La classe ne change ni la cadence des vagues, ni le pool, ni les raretés.
- **Pas de changement en cours de run.** La classe est lue une fois au démarrage ; aucune offre, aucun achat, aucun level-up ne la remplace.
- **Pas de puissance permanente.** La classe n'est pas un déblocage de méta et ne convertit rien en puissance permanente (décision du chef d'équipe n°3).

### 4. Interactions avec les systèmes existants

#### 4.1 Level-up : 3 offres, 3 armes maximum

- Le pool d'offres reste **identique pour les trois classes** : aucune pondération spécifique de classe, aucune rareté spécifique. La variété vient du tirage, pas de la classe (Pilier 1).
- L'arme de départ est dans l'inventaire dès le départ ; `Inventory.has_weapon` la compare par `id` et l'exclut des offres. Elle ne peut donc jamais être reproposée.
- Les offres d'arme sont plafonnées au nombre d'emplacements libres (`free_weapon_slots`). Avec 3 armes, un reroll ne produit aucune ligne d'arme : trois offres de stat ou d'équipement restent disponibles si le pool le permet.
- **Affichage des offres** : le DPS affiché est le **plancher garanti**, multiplicateurs de classe compris, sans bonus de signature situationnel. Pour la Chasseresse, une arme à projectile affiche son DPS à bout portant et mentionne « jusqu'à +50 % au loin » ; gonfler l'offre avec le meilleur cas serait mensonger.

#### 4.2 Équipement et rareté

- Les multiplicateurs de classe vivent sur les **stats de base** reconstruites à chaque changement (`_recompute_stats` : classe + améliorations, puis équipement par-dessus). Remplacer une pièce ne doit jamais doubler le multiplicateur de classe.
- La rareté et les poids d'offre (`EquipmentData.RARITY_WEIGHTS`) ne changent pas selon la classe. Une classe ne reçoit pas plus d'équipement rare.
- Les pièces `max_hp` ajoutent des PV plats (`amount`) après le calcul de classe ; elles ne multiplient pas les PV de classe.

#### 4.3 Reroll

- `reroll_base = 2`, `+1` aux niveaux 10 et 20 : inchangé pour les trois classes.
- Sur l'écran de sélection de classe, `R` ne fait **rien** : ce n'est pas un reroll. Le reroll n'existe qu'en run, une fois le panneau de level-up ou de butin ouvert.

#### 4.4 Boss toutes les 5 vagues

- Aucune classe ne change `boss_every_waves`, `total_waves`, le palier de boss (`boss_tier`), les PV (`480 × (1 + 0,9 × palier)`) ni les dégâts (`× (1 + 0,35 × palier)`).
- La classe change seulement la capacité du joueur à tenir la distance, à esquiver et à tuer. Le premier boss (vague 5, palier 0, 480 PV) est le test d'acceptation de chaque classe.

#### 4.5 Victoire, butin et mort simultanée

- Un coup de signature qui met le boss à 0 PV déclenche le panneau de butin **une seule fois** : `Enemy.take_damage` ignore un ennemi déjà mort, et `_collect_pickups` ouvre le panneau sur la même frame.
- Aucune signature n'inflige de dégâts après la mort (pas de dégâts sur la durée). Une signature ne peut donc pas « re-tuer » un boss ou ouvrir deux panneaux.
- Si le joueur meurt sur la même frame que le boss, **la mort gagne** : la run est perdue, le panneau de butin ne doit pas s'empiler sur la carte de mort. C'est un cas limite existant, rendu plus probable par les dégâts de signature ; W3-E2 doit le tester et W3-E4 doit garantir la priorité de la carte de mort.

### 5. Écran de sélection de classe — contrat pour W3-E4

L'écran existe dès la tranche verticale (W3-E4). Il est **clavier uniquement** pour l'acceptation ; la manette et le remappage avancé restent en phase 18 (décision du chef d'équipe n°1).

**Placement et temps.** L'écran s'affiche **avant la vague 1**. L'horloge de vague ne démarre pas, aucun ennemi n'apparaît et aucune bannière de vague ne s'affiche tant que la classe n'est pas confirmée. Le joueur lit sans pression de temps.

**Entrées.**
- `move_left` / `move_right` (ou `A`/`D`, `Q`/`D` en AZERTY selon les actions existantes) : cycle entre les trois classes, avec bouclage.
- `choice_1`, `choice_2`, `choice_3` : sélection directe de la classe 1, 2 ou 3.
- `ui_accept` (`Entrée` / `Espace`) : confirme la classe sélectionnée et démarre la run.
- Aucune autre action : `reroll`, `restart`, `mute` n'ont pas d'effet ici.

**Contenu d'une carte de classe.** Silhouette (W3-E3), nom, fantasy en une phrase, trois lignes de stats (PV, vitesse, arme de départ), nom de la signature et sa règle en une phrase, et une ligne « ce que vous faites en vague 1 ». Aucune promesse de mécanique qui n'existe pas encore (pas de « flèches perforantes » avant W2-E2).

**Sélection par défaut.** `chevalier`. Si W7 ajoute un « choix de départ » mémorisé, il peut présélectionner une classe, mais l'écran reste modifiable ; W3 ne dépend pas de W7.

**Lisibilité et accessibilité.**
- La sélection ne repose **jamais sur la couleur seule** : encadré, position, forme et focus clavier. La couleur d'accent (rouge tabard) peut renforcer, pas nommer.
- Lisible à 1280×720, même famille d'encre que le HUD, aucun or (l'or reste la récompense d'XP).
- Le focus est toujours visible et ne peut pas se perdre ; aucune confirmation double (une garde `_confirming` ou une confirmation sur relâchement).
- Les touches de déplacement pressées pendant la lecture ne doivent pas produire un burst de mouvement au démarrage de la vague 1 : l'entrée est relue à zéro après la confirmation.

**Cas dégradés.** Si une classe est invalide (arme de départ absente, signature inconnue), elle est affichée désactivée avec la raison, et ne peut pas être confirmée. Si aucune classe n'est valide, la run démarre sur `catalogue.starting_class` (le Chevalier) et journalise une erreur ; elle ne crashe pas. Si une seule classe est valide, l'écran l'affiche seule et reste confirmable.

### 6. Identité visuelle — contrat pour W3-E3

W3-E1 ne fixe pas les tons finaux : c'est le rôle de `art-director` (W3-E3), dans la bible d'art. Les contraintes sont fermes :

- **Trois tons d'une seule teinte + un seul accent par acteur.** Pas de deuxième accent.
- **L'accent unique est le rouge tabard** `Color(0.706, 0.208, 0.196)`, déjà défini comme « l'accent du joueur ». Les trois classes doivent rester reconnaissables comme *le joueur* : un foulard, une ceinture ou une doublure rouge, jamais une deuxième couleur.
- **Aucune couleur inventée.** Les bases se choisissent parmi les rôles existants : Acier du chevalier `0.400, 0.455, 0.541`, Encre `#29241F` / `0.16, 0.14, 0.12`, Os `0.851, 0.812, 0.702` en détail seulement. Le vert orc, le gris froid du loup, le violet du boss et l'or sont réservés à leurs porteurs.
- **L'or est interdit** : il ne marque que le paiement du joueur (XP, butin, victoire). Aucun or sur une carte de classe, un contour, un rang ou un ornement.
- **Silhouette d'abord.** Trois contours différents à 100 % sur l'herbe, sans couleur. Le Chevalier est équilibré (heaume rond, deux épaules) ; la Chasseresse est fine, verticale, avec un arc dans le dos ou une capuche ; le Pénitent est large et bas, avec un marteau qui dépasse. Le Pénitent lit la masse **dans le contour**, pas dans une hitbox plus grande (14 px pour tous).
- **Feedback de signature.** W3-E3 fournit une forme lisible pour l'ancrage (ombre qui se resserre, anneau qui se ferme) et, avec W3-E4, pour les piles de Sang-froid et la bande de distance. Aucun feedback ne repose sur la couleur seule.

### 7. Questions ouvertes (à trancher hors W3-E1)

1. **Classe et « choix de départ » W7** : l'inclusion de la classe dans le choix méta reste ouverte (Open Question 7 du concept). W3-E1 fige les `id` stables pour que W7 puisse le faire sans migration.
2. **Nom de la deuxième rencontre du boss** : sans impact sur les classes ; reste une question de fiction (W1-E0 / narrative).
3. **Armes à projectile supplémentaires** : la Chasseresse n'a qu'un projectile dans le pool actuel. W2-E1/E2 doit en livrer au moins deux de plus avant le portail W9, sinon son build à distance reste mono-arme.
4. **Chemin des données** : le build stocke les ressources dans `data/` (`res://data/classes/`), alors que les standards citent `assets/data/`. W3-E2 doit suivre le build existant (`data/classes/`) ; l'écart est signalé au chef d'équipe, pas corrigé ici.

## Formulas

### 4.1 Variables

| Variable | Définition | Unité / plage |
| --- | --- | --- |
| `hp_class` | `ClassData.max_hp` | 70–160 PV |
| `speed_class` | `ClassData.move_speed` | 150–260 px/s |
| `dmg_mult_class` | `ClassData.damage_mult` | 0,85–1,25 |
| `as_mult_class` | `ClassData.attack_speed_mult` | 0,75–1,30 |
| `bonus_dmg` | Somme des améliorations et équipements `damage` | 0,0–1,5 (fraction) |
| `bonus_as` | Somme des améliorations et équipements `attack_speed` | 0,0–1,5 (fraction) |
| `bonus_speed` | Somme des améliorations et équipements `move_speed` | 0,0–1,0 (fraction) |
| `bonus_hp` | Somme des `max_hp` plats (améliorations + équipement) | 0–200 PV |
| `weapon.damage` | Dégâts de base de l'arme | 7–26 |
| `weapon.aps` | Attaques par seconde de base | 0,7–2,8 |
| `crit_chance` | Critique de l'arme + bonus, plafonné à 0,75 | 0,0–0,75 |
| `crit_mult` | Multiplicateur de critique de l'arme | 2,0–2,2 |
| `stacks` | Piles de Sang-froid | 0–10 |
| `d` | Distance parcourue par le projectile à l'impact | 0–320 px |
| `r` | Réduction de dégâts d'Ancrage | 0 ou 0,20 |

### 4.2 Dégâts d'un coup

```text
base_mult    = dmg_mult_class + bonus_dmg
signature    = 1,0 + 0,02 × stacks                         (Chevalier)
             = 1,0 + 0,50 × clamp((d - 100) / 200, 0, 1)  (Chasseresse, projectile)
             = 1,15                                       (Pénitent, ancré)
             = 1,0                                        (sinon)
hit_damage   = weapon.damage × base_mult × signature
if critique: hit_damage = hit_damage × crit_mult
```

- Le critique est tiré **avant** l'application du multiplicateur de signature ; les deux se multiplient.
- Pour un projectile, `d` n'est connu qu'à l'impact : `Projectile._resolve_hit` applique `signature` au montant déjà roulé, puis émet `hit_resolved` avec le montant final.
- Pour une mêlée, `d` n'existe pas ; `signature` est évalué avant l'application.
- Le montant final est celui utilisé par les nombres flottants, le son d'impact et le seuil de hitstop lourd (`heavy_hit_damage = 22`).

### 4.3 Cadence et DPS

```text
aps          = weapon.aps × (as_mult_class + bonus_as)
crit_factor  = 1 + crit_chance × (crit_mult - 1)
DPS          = hit_damage_moyen × aps × crit_factor
```

`hit_damage_moyen` inclut le multiplicateur de signature dans les conditions mesurées. Pour une comparaison honnête, on donne toujours deux chiffres : **plancher** (signature à 1,0) et **plafond** (signature à son maximum).

### 4.4 PV effectifs et dégâts reçus

```text
max_hp        = hp_class + bonus_hp
raw_damage    = contact_damage × (1 + 0,35 × palier)     (ou slam_damage × ...)
taken         = max(1,0, raw_damage × (1 - r))
effective_hp  = max_hp / (1 - r)                          (r = 0,20 si ancré, sinon 0)
hits_to_die   = ceil(max_hp / taken)
```

Exemples (palier 0 : contact 16, slam 22 ; palier 1 : contact 21,6, slam 29,7) :

| Classe | `max_hp` | `r` | PV effectifs | Slam palier 0 | Coups pour mourir | Slam palier 1 | Coups pour mourir |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Chevalier | 100 | 0 | 100 | 22,0 | 5 | 29,7 | 4 |
| Chasseresse | 80 | 0 | 80 | 22,0 | 4 | 29,7 | 3 |
| Pénitent | 140 | 0 | 140 | 22,0 | 7 | 29,7 | 5 |
| Pénitent ancré | 140 | 0,20 | 175 | 17,6 | 8 | 23,8 | 6 |

### 4.5 Vitesse de déplacement

```text
speed = speed_class × (1 + bonus_speed)
```

| Classe | Base | +12 % (une amélioration Vitesse) | +24 % (deux) |
| --- | --- | --- | --- |
| Chevalier | 220 | 246 | 273 |
| Chasseresse | 240 | 269 | 298 |
| Pénitent | 170 | 190 | 211 |

Le loup (130 px/s) et l'orc (55 px/s) restent plus lents que les trois classes même sans amélioration ; la charge du loup en W1 devra dépasser 170 px/s pour que le Pénitent ne puisse pas la courir (voir 5, cas limite).

### 4.6 Exemples chiffrés — niveau 6 de référence

Fixture commune : niveau 6 (5 choix), arme de départ + 2 armes, une amélioration Dégâts (+20 %), une amélioration Cadence (+15 %). Pas d'équipement. Toutes les armes à portée. Les valeurs sont des DPS papier, pas des DPS réels en mouvement.

| Classe | Armes (départ + 2) | `base_mult` | `as_mult` | DPS toutes armes à portée | DPS selon la signature | TTK boss 480 PV |
| --- | --- | --- | --- | --- | --- | --- |
| Chevalier | épée + dague + arc | 1,20 | 1,15 | 77,7 | ×1,20 = 93,2 (10 piles) | 6,2 s → 5,1 s |
| Chasseresse | arc + dague + épée | 1,10 | 1,35 | 83,6 au contact (marge ×1,0) | 17,3 (arc seul à < 100 px) ; 25,98 (arc seul à 300 px) | 5,7 s au contact risqué → 18,5 s à 300 px |
| Pénitent | marteau + dague + arc | 1,35 | 1,00 | 70,8 | ×1,15 = 81,5 (ancré) | 6,8 s → 5,9 s |

Lecture de la ligne Chasseresse : au contact, ses trois armes font 83,6 DPS mais elle perd le bonus de distance et expose ses 80 PV ; à 300 px, seule l'arc tire, pour 25,98 DPS, soit 18,5 s pour tuer le boss. C'est le pari de la classe : la sécurité coûte du temps, le contact coûte des PV.

### 4.7 Vérification de la vague 1

Spawn de la vague 1 : une toutes les 1,4 s, soit 0,71 ennemi/s. Squelette : 20 PV.

| Classe | Dégâts par coup | Coups par squelette | Cadence | Temps par squelette | Débit (ennemis/s) | Tient la vague ? |
| --- | --- | --- | --- | --- | --- | --- |
| Chevalier | 12 | 2 | 1,8/s | 1,11 s | 0,90 | Oui, avec du cône |
| Chasseresse à 300 px | 12,15 (avec marge) | 2 | 1,44/s | 1,39 s | 0,72 | Juste, sans marge de retard |
| Chasseresse à moins de 100 px | 8,1 | 3 | 1,44/s | 2,08 s | 0,48 | Non : la meute grossit |
| Pénitent | 29,9 | 1 | 0,595/s | 1,68 s | 0,60 (mono-cible) | Oui par le balayage 160° : il doit grouper |

La Chasseresse doit utiliser sa signature pour tenir la vague 1 ; c'est la preuve que la règle n'est pas décorative. Le Pénitent doit laisser la meute se grouper ; c'est la preuve que son identité est le placement, pas la poursuite.

### 4.8 Écarts acceptables

- Aucune classe ne doit avoir à la fois le meilleur DPS plafond et la meilleure survie. Le Chevalier a le plafond conditionnel le plus simple ; la Chasseresse a le plafond le plus haut mais la survie la plus basse ; le Pénitent a la meilleure survie mais le plafond de DPS le plus bas.
- Sur 5 runs par classe, le taux de victoire du boss 5 doit rester dans une bande de 20 points entre classes. Un écart plus grand est un signal de réglage, pas une réussite.

## Edge Cases

Chaque cas dit ce qui se passe, pas « gérer proprement ».

### 5.1 Arme de départ refusée ou échangée au level-up

- **Reproposée ?** Non. L'arme de départ est ajoutée à l'inventaire au démarrage ; `Inventory.has_weapon` la compare par `id` et l'exclut de toutes les offres, y compris après un reroll.
- **Échangée ?** Le chemin d'offre actuel ne remplace jamais une arme : `_build_offers` n'ajoute une arme que s'il reste un emplacement libre, et `Inventory.replace_weapon` n'est appelé par aucune offre. L'arme de départ ne peut donc pas être perdue en W3. Si W2/W4 ajoute un jour un remplacement, la signature ne doit pas en dépendre : elle vit sur les stats et le projectile, pas sur l'arme.
- **Doublon d'identifiant différent ?** Une arme avec un autre `id` mais des stats proches reste proposable ; c'est une arme différente pour l'inventaire. Aucune règle de classe ne l'interdit.
- **Arme de départ absente ou nulle ?** La classe est invalide. Le validateur de données de W3-E2 échoue ; l'écran W3-E4 ne permet pas de la confirmer ; si elle est malgré tout la seule classe du catalogue, la run démarre sans arme (comportement actuel de `add_weapon(null)`) et journalise une erreur — elle ne crashe pas, mais elle est injouable.

### 5.2 Signature qui tue le boss

- Le multiplicateur de signature est appliqué **au moment du coup**. Si le coup met le boss à 0 PV, `Enemy.take_damage` enregistre la mort et `_collect_pickups` ouvre le panneau de butin une fois, sur la même frame.
- Aucune signature n'inflige de dégâts après la mort : pas de poison, pas de rémanence, pas de deuxième résolution. Un boss déjà à 0 PV ignore tout nouveau coup.
- **Mort simultanée** : si le joueur passe à 0 PV sur la même frame que le boss, la mort gagne. La run est perdue, le panneau de butin ne s'empile pas sur la carte de mort, et le boss mort ne compte pas comme une victoire. W3-E2 doit couvrir ce cas par un test ; W3-E4 doit garantir la priorité visuelle de la mort.
- **Butin et level-up** : les gemmes d'XP du boss tombent avant le panneau de butin ; les montées de niveau achetées par ces gemmes arrivent après le choix de butin. La signature ne change pas cet ordre.

### 5.3 Chasseresse qui ne prend jamais de dégâts

C'est un résultat de maîtrise, pas un bug. Mais il ne doit pas être gratuit :

- **80 PV** : une erreur coûte 4 coups de slam palier 0, 3 au palier 1.
- **Plancher de dégâts à courte portée** : sous 100 px, l'arc perd tout bonus et met trois tirs par squelette ; la classe devient nettement moins efficace, pas seulement plus vulnérable.
- **La meute** : la vague du boss 5 autorise 42 ennemis simultanés (`18 + 6 × 4`) et un spawn toutes les 1,34 s. La Chasseresse doit tuer 0,74 ennemi/s pour tenir ; son arc à 300 px en tue 0,72/s. La marge est nulle : un retard, et la meute lui coupe la retraite.
- **W1-E0** : le chargeur (loup) et l'ennemi à distance sont les réponses de design à une classe qui fuit en ligne droite. Leur télégraphe doit rester lisible (≥ 0,6 s) sans exiger de visée manuelle.
- **Seuil de réglage** : si, sur 10 runs de test, la Chasseresse meurt avant la vague 5 dans moins de 10 % des cas, on augmente la pression de meute (W1-E0) avant de toucher à ses chiffres. Une classe à distance sans risque est un échec de variété, pas une réussite de puissance.

### 5.4 Pénitent face à un chargeur

- La cible W1-E0 est un loup qui s'aplatit et trace une ligne au sol pendant **0,85 s**, puis charge plus vite que 170 px/s.
- Le Pénitent ne peut pas courir la charge. Sa réponse est un **pas perpendiculaire** d'environ 35 px (rayon joueur 14 + rayon loup 11 + marge 10), soit 0,21 s à 170 px/s. Le télégraphe de 0,85 s laisse quatre fois le temps nécessaire.
- Le coût est l'ancrage : le pas déclenche la grâce de 0,5 s, puis les 0,75 s de ré-ancrage. Le Pénitent choisit entre garder sa réduction et esquiver. C'est la question de la classe, pas un piège.
- Si le télégraphe descend sous 0,6 s ou si la charge est plus lente que 170 px/s, la question disparaît : W1-E0 doit respecter ces deux bornes.

### 5.5 Reroll d'une offre d'arme quand les emplacements sont pleins

- Avec 3 armes, `free_weapon_slots()` vaut 0 ; `_build_offers` n'ajoute aucune **acquisition**. Un reroll ne peut donc pas produire une ligne d'acquisition morte ; une ligne de **niveau** reste possible tant que l'arme visée est sous son `max_level` (lot 1, `weapons.md` §3.8).
- Si un reroll survient après l'acquisition d'une arme, le panneau est reconstruit et le nombre d'emplacements libres est recalculé. Aucune acquisition ne peut être sélectionnée sans emplacement ; une ligne de niveau reste valide.
- Si un chemin futur appelait `_gain_weapon` avec 3 armes, `add_weapon` renvoie faux et l'offre est consommée sans effet : c'est un choix perdu. W3-E2 doit ajouter un test « aucune acquisition quand 3 armes » pour que ce chemin reste impossible.

### 5.6 Valeurs extrêmes et division par zéro

- `max_hp ≤ 0` : classe invalide (le joueur meurt au démarrage). Le validateur rejette.
- `move_speed ≤ 0` : classe invalide (le joueur ne peut plus esquiver). Le validateur rejette.
- `damage_mult ≤ 0` ou `attack_speed_mult ≤ 0` : classe invalide. `Stats.weapon_attacks_per_second` plancher déjà à 0,001, donc pas de division par zéro à l'exécution, mais le validateur rejette quand même pour ne pas livrer une classe qui ne fait rien.
- `attack_speed_mult` très grand (> 3) : la cadence devient illisible et les projectiles saturent l'écran. La plage sûre de la section 7 plafonne à 1,30 pour la classe ; les améliorations peuvent s'y ajouter, mais W3-E2 doit tester le plafond pratique.
- `stacks` hors 0–10 : clampé par la règle ; un débordement de chronomètre ne crée pas de pile 11.
- `d` négatif ou nul : `clamp` renvoie 0, multiplicateur 1,00. Un projectile créé dans un ennemi ne gagne pas de bonus négatif.
- `r > 1` : impossible par construction (0,20 max) ; le plancher `max(1,0, ...)` protège quand même.

### 5.7 Écran de sélection — cas limites de design

- **Aucune classe valide** : la run démarre sur le Chevalier du catalogue et une erreur est journalisée. L'écran ne bloque pas le jeu.
- **Une seule classe valide** : carte unique, focus dessus, confirmation possible ; l'écran ne demande pas de choisir entre une option et du vide.
- **Trois classes valides** : ordre fixe `chevalier`, `chasseresse`, `penitent` ; le bouclage gauche/droite est autorisé.
- **Confirmation double** : la touche `ui_accept` maintenue ne doit pas confirmer deux fois. Une garde d'état ou une confirmation sur relâchement ; après confirmation, l'écran se ferme et la run démarre une seule fois.
- **Focus perdu** : le focus revient toujours à la carte sélectionnée ; aucun état sans focus visible.
- **Touches de déplacement maintenues à la confirmation** : la vague 1 ne doit pas commencer avec un déplacement hérité. L'entrée est relue à zéro après la fermeture de l'écran.
- **Manette / souris** : non requises pour l'acceptation W3-E4. Si elles fonctionnent via les actions existantes, tant mieux ; elles ne doivent pas casser le clavier et ne bloquent pas la story.
- **Texte manquant** : une clé de localisation absente retombe sur le français (`display_name`), jamais sur la clé brute.
- **Écran et horloge** : aucune seconde de vague ne s'écoule avant la confirmation ; aucun ennemi n'est instancié ; la bannière « VAGUE 1 » n'apparaît qu'après.

## Dependencies

Les dépendances sont bidirectionnelles : chaque ligne dit ce que ce document fournit et ce qu'il exige.

### 6.1 W3-E2 — `ClassData` et règle signature (gameplay-programmer)

**W3-E1 fournit** : les trois `id`, les valeurs de stats, les trois règles signature avec déclencheur/effet/formule/plafond, l'ordre exact des multiplicateurs, les cas limites et les critères d'acceptation.

**W3-E2 doit fournir** :
- `ClassData` étendu avec, au minimum : `id`, `name_key`, `tagline_key`, `max_hp`, `move_speed`, `damage_mult`, `attack_speed_mult`, `weapon`, `signature` (`sang_froid` | `trait_de_marge` | `ancrage` | vide) et les paramètres de signature. `display_name` reste le repli français tant que W8-E1 n'a pas livré ses clés.
- `Stats.from_class` initialise `damage_mult` et `attack_speed_mult` depuis la classe ; les améliorations et l'équipement s'y ajoutent (additif), jamais en multiplication du multiplicateur de classe.
- L'application de la signature au bon endroit : mêlée avant `enemy.take_damage` ; projectile dans `Projectile._resolve_hit`, après le jet de critique et avant `take_damage`, avec le montant final dans `hit_resolved`.
- La réduction de dégâts d'Ancrage dans le chemin de dégâts du joueur, avec plancher 1,0.
- Un validateur de données qui échoue sur `id` dupliqué/vide, arme de départ absente, signature inconnue, stats ≤ 0.
- Des tests unitaires sur les trois signatures, les formules 4.2–4.5 et les cas 5.1–5.6.

**Ce que W3-E2 ne doit pas faire** : ajouter des pondérations d'offre par classe, changer les raretés, changer les rerolls, changer le hitbox, ou écrire une valeur de gameplay en dur.

### 6.2 W3-E3 — Silhouettes des trois classes (art-director)

**W3-E1 fournit** : les `id`, les fantasies, l'intention de silhouette (équilibré / fin / large), les contraintes de couleur (section 6), le hitbox fixe de 14 px et la nécessité d'un feedback de signature lisible.

**W3-E3 fournit** : trois contours distincts à 100 % sur l'herbe, les tons dérivés de rôles existants, l'accent tabard unique, les clés d'art par classe et les formes de feedback (ancrage, piles, bande de distance). W3-E3 ne peut pas introduire de couleur hors palette, d'or, ni une hitbox plus grande.

### 6.3 W3-E4 — Écran de sélection de classe (ui-programmer)

**W3-E1 fournit** : le contenu des cartes, les entrées clavier, la sélection par défaut, les cas dégradés, les exigences de lisibilité et de non-double-confirmation, le fait que l'horloge ne démarre pas avant la confirmation.

**W3-E4 fournit** : l'écran clavier, la capture dans `production/qa/evidence/`, le branchement de la classe choisie vers `main.gd` (`Player.setup`, `Stats.from_class`, `Inventory.setup_starting`) et la garantie qu'aucun changement de classe n'est possible en run.

### 6.4 W2-E1 / W2-E2 — Armes (systems-designer, gameplay-programmer)

**W3-E1 fournit** : la dépendance aux armes existantes (`epee_longue`, `arc_court`, `marteau`), la règle « toute arme à projectile profite de `trait_de_marge` » et l'exigence d'au moins deux projectiles supplémentaires avant W9.

**W2-E1/E2 fournit** : les dix armes et leurs mécaniques, dont au moins deux armes à projectile pour que le build de la Chasseresse existe. L'affichage du DPS d'une offre doit utiliser les stats de classe (sinon deux joueurs voient deux DPS différents pour la même arme). Aucune arme n'est verrouillée par classe.

### 6.5 W1-E0 — Comportements ennemis (game-designer)

**W3-E1 fournit** : les bornes dont les classes dépendent — chargeur avec télégraphe ≥ 0,6 s et vitesse de charge > 170 px/s, ennemi à distance qui punit la fuite en ligne droite, aucune attaque exigeant un ciblage manuel.

**W1-E0 fournit** : les cinq comportements et leurs annonces. Sans le chargeur et l'ennemi à distance, la Chasseresse et le Pénitent perdent une partie de leur question ; c'est un risque de balance à signaler au portail W9, pas une raison de changer les classes.

### 6.6 W4-E1/E2 — Économie

**W3-E1 fournit** : la classe est choisie avant la première boutique ; aucune classe ne change les prix, le stock ou la monnaie.

**W4-E1/E2 fournit** : une monnaie qui n'est pas de l'or, des prix et un stock indépendants de la classe, et aucune vente de changement de classe. La boutique ne doit pas proposer une arme que la classe possède déjà (même règle `has_weapon` que les offres).

### 6.7 W7 — Méta-progression

**W3-E1 fournit** : les `id` stables (`chevalier`, `chasseresse`, `penitent`) pour les sauvegardes et le choix de départ.

**W7 fournit** : si le choix de départ inclut une classe, il peut présélectionner mais pas imposer ; aucune puissance permanente achetée par la méta (décision n°3). La classe n'est pas un déblocage payant.

### 6.8 W8-E1 — Localisation

**W3-E1 fournit** : les clés à créer (`class.<id>.name`, `class.<id>.tagline`, `class.<id>.signature.name`, `class.<id>.signature.text`, `class.<id>.wave1`) et la règle « les `id` ne sont jamais traduits ».

**W8-E1 fournit** : le pipeline de clés, le CSV et le repli français. Une clé absente retombe sur le français, jamais sur la clé brute.

### 6.9 W9-E1 — Portail vertical

**W3-E1 fournit** : les critères d'acceptation de la section 8, notamment « chaque classe survit à son premier boss avec une stratégie différente » et « deux runs de classes différentes ne se ressemblent pas à la vague 3 ».

**W9-E1 fournit** : le run complet de 10 vagues, la capture par classe et la mesure du taux de victoire. Le portail ne peut pas être vert si la Chasseresse n'a pas reçu ses projectiles W2.

### 6.10 Bible d'art et index

- **Bible d'art** (`design/art/art-bible.md`) : source des rôles de couleur. Toute couleur de classe vient d'un rôle existant ; l'or reste la récompense ; un seul accent par acteur. W3-E1 ne modifie pas la bible ; W3-E3 peut l'amender avec preuve.
- **`design/gdd/systems-index.md`** : un autre agent l'écrit. W3-E1 ne le touche pas ; l'entrée `classes` doit y être ajoutée par ce propriétaire.
- **Chemin des données** : W3-E2 écrit dans `data/classes/` (convention du build), pas dans `assets/data/`. L'écart avec les standards est signalé au chef d'équipe.

## Tuning Knobs

Toutes les valeurs vivent dans `data/classes/*.tres` (ou une sous-ressource de signature), jamais dans le code. Catégories : **feel** (ressenti immédiat, réglé au playtest), **curve** (forme de la progression, réglée au calcul), **gate** (pacing, réglé à la durée de session).

### 7.1 Stats de classe

| Clé | Défaut | Plage sûre | Catégorie | Raison |
| --- | --- | --- | --- | --- |
| `chevalier.max_hp` | 100 | 90–110 | curve | Référence du build ; ne pas dépasser 110 sans revoir le boss. |
| `chevalier.move_speed` | 220 | 200–240 | feel | Vitesse historique ; la changer change tout le jeu, pas seulement la classe. |
| `chevalier.damage_mult` | 1,00 | 0,95–1,05 | curve | Référence ; toute déviation doit être compensée par la signature. |
| `chevalier.attack_speed_mult` | 1,00 | 0,95–1,05 | feel | Référence de cadence. |
| `chasseresse.max_hp` | 80 | 70–90 | curve | Paie la portée ; sous 70, une seule erreur de lecture tue. |
| `chasseresse.move_speed` | 240 | 220–260 | feel | Doit rester au-dessus du loup (130) sans rendre la fuite triviale. |
| `chasseresse.damage_mult` | 0,90 | 0,85–1,00 | curve | Compense la cadence ; ne pas descendre sous 0,85 (la vague 1 devient injouable). |
| `chasseresse.attack_speed_mult` | 1,20 | 1,10–1,30 | feel | Profil « petits coups rapides » ; au-delà de 1,30, les projectiles saturent. |
| `penitent.max_hp` | 140 | 120–160 | curve | Paie la lenteur ; au-delà de 160, l'ancrage devient trop indulgent. |
| `penitent.move_speed` | 170 | 150–190 | feel | Doit rester au-dessus du loup (130) pour pouvoir esquiver, et sous 200 pour ne pas courir. |
| `penitent.damage_mult` | 1,15 | 1,05–1,25 | curve | Gros coups ; compensé par la cadence 0,85. |
| `penitent.attack_speed_mult` | 0,85 | 0,75–0,95 | feel | La lenteur est l'identité ; sous 0,75, le marteau devient illisible. |

### 7.2 Signatures

| Clé | Défaut | Plage sûre | Catégorie | Raison |
| --- | --- | --- | --- | --- |
| `sang_froid.stack_interval_s` | 1,0 | 0,5–2,0 | feel | Une pile par seconde : lisible, atteignable en 10 s propres. |
| `sang_froid.damage_per_stack` | 0,02 | 0,01–0,03 | curve | +20 % au plafond ; au-delà, le Chevalier domine le DPS. |
| `sang_froid.max_stacks` | 10 | 5–15 | curve | 10 piles = 10 s propres ; 15 rend le plafond trop rare. |
| `trait_de_marge.d_min_px` | 100 | 60–160 | feel | En dessous, la Chasseresse est déjà en danger. |
| `trait_de_marge.d_full_px` | 300 | 240–340 | feel | Doit rester sous la portée de l'arc (320) pour être atteignable. |
| `trait_de_marge.bonus_max` | 0,50 | 0,25–0,75 | curve | +50 % au plafond ; au-delà, la classe n'a plus besoin de ses autres armes. |
| `ancrage.delay_s` | 0,75 | 0,40–1,50 | feel | Assez long pour être une décision, assez court pour être utilisable entre deux slams. |
| `ancrage.grace_s` | 0,50 | 0,20–1,00 | feel | Permet un micro-pas sans perdre le buff ; au-delà de 1,0, le pas devient gratuit. |
| `ancrage.damage_reduction` | 0,20 | 0,10–0,30 | curve | 20 % = 175 PV effectifs à 140 PV ; au-delà de 0,30, l'ancrage frôle l'invulnérabilité. |
| `ancrage.damage_bonus` | 0,15 | 0,05–0,25 | curve | Compense la cadence 0,85 et la perte de mobilité. |
| `ancrage.knockback_bonus` | 0,25 | 0,00–0,50 | feel | Rend le balayage lisible ; le boss résiste à 85 %, donc l'effet reste marginal sur lui. |

### 7.3 Knobs de gate

Aucun knob de gate n'appartient aux classes. Les portes de pacing restent `WaveData.boss_every_waves = 5` et `WaveData.total_waves = 10`, possédées par W1-E0/W0-E3. Une classe ne doit jamais modifier ces valeurs.

### 7.4 Règle de réglage

- On règle d'abord **feel** (vitesse, cadence, temps d'ancrage), puis **curve** (PV, multiplicateurs, bonus de signature), jamais les deux dans le même passage.
- Toute valeur hors plage sûre exige une note dans le `.tres` et une story de réglage dédiée.
- Un changement de `max_hp`, `damage_mult` ou `attack_speed_mult` de classe est un changement de design : il passe par `/propagate-design-change design/gdd/classes.md` avant d'être commité.

## Acceptance Criteria

### 8.1 Critères fonctionnels (testables automatiquement)

1. **Validité des données.** Un test gdUnit4 charge `data/classes/*.tres` et échoue si : un `id` est vide ou dupliqué ; un `id` n'est pas l'un de `chevalier`, `chasseresse`, `penitent` ; l'arme de départ est nulle ou absente du catalogue ; la signature est inconnue ; `max_hp ≤ 0`, `move_speed ≤ 0`, `damage_mult ≤ 0` ou `attack_speed_mult ≤ 0`.
2. **Stats de départ.** `Stats.from_class` renvoie le tableau de la section 1 pour les trois classes ; `Player.setup` fixe `hp = max_hp` ; `Inventory.setup_starting` contient exactement l'arme de départ, une fois.
3. **Sang-froid.** Après 0 s / 1 s / 10 s / 11 s sans dégâts : 0 / 1 / 10 / 10 piles ; multiplicateur 1,00 / 1,02 / 1,20 / 1,20. Un coup qui retire ≥ 1 PV remet à 0. La pause n'accumule pas.
4. **Trait de marge.** Un projectile à `d = 0 / 100 / 200 / 300 / 320` donne ×1,00 / ×1,00 / ×1,25 / ×1,50 / ×1,50 ; une mêlée donne ×1,00 ; un critique à 300 px donne ×2 ×1,50 ; `hit_resolved` porte le montant final.
5. **Ancrage.** Immobile 0,74 s : non ancré ; 0,75 s : ancré ; mouvement 0,49 s : encore ancré ; 0,51 s : plus ancré ; s'arrêter à nouveau repart de 0,75 s. Dégâts reçus ×0,80, plancher 1,0, sur contact et slam.
6. **PV effectifs.** Les exemples du tableau 4.4 passent : Pénitent ancré 140 / 0,8 = 175 ; slam palier 0 = 17,6 ; 8 coups pour mourir ; palier 1 = 23,8 ; 6 coups.
7. **Level-up.** Pour chaque classe : l'arme de départ n'apparaît jamais en **acquisition** ; avec 3 armes, `_build_offers` ne produit aucune acquisition et un reroll rend 3 offres sans acquisition (les lignes de niveau restent possibles, lot 1) ; `reroll_base = 2` et les rerolls de niveau 10/20 sont inchangés ; remplacer un équipement recalcule les stats depuis la classe sans doubler le multiplicateur.
8. **Boss 5.** Une fixture headless (niveau 6, arme de départ + 2 armes, Dégâts +20 %, Cadence +15 %, joueur placé à sa bande idéale, armes à portée) tue le boss palier 0 (480 PV) en ≤ 20 s pour les trois classes ; le panneau de butin s'ouvre exactement une fois.
9. **Mort simultanée.** Si le joueur et le boss tombent à 0 PV sur la même frame, la run est une défaite, aucun panneau de butin ne s'ouvre, et la carte de mort est la seule affichée.
10. **Écran (W3-E4).** Test clavier : `move_left/right` cycle avec bouclage, `choice_1/2/3` sélectionnent directement, `ui_accept` confirme, une confirmation maintenue ne confirme qu'une fois, le focus ne se perd pas, aucune touche de déplacement n'entre dans la vague 1, l'horloge de vague est à 0 avant confirmation. Capture retenue dans `production/qa/evidence/`.
11. **Reproductibilité.** Les tests de signature n'utilisent aucun aléa non injecté ; les critiques sont testés avec un `RandomNumberGenerator` seedé.

### 8.2 Critères expérientiels (playtest)

1. **Chaque classe survit à son premier boss avec une stratégie différente.** Trois runs filmés ou observés : le Chevalier esquive et entretient ses piles ; la Chasseresse reste à 200–300 px et tue à la marge ; le Pénitent s'ancre, balaie, se désancre pour le slam et se ré-ancre. Un observateur doit nommer la stratégie sans qu'on la lui dise.
2. **Deux runs de classes différentes ne se ressemblent pas à la vague 3.** Sur les trois premières vagues, au moins deux des trois premiers choix de level-up diffèrent entre deux classes, et le joueur décrit une action principale différente (esquiver / tenir la distance / s'ancrer).
3. **Aucune classe strictement meilleure.** 5 runs par classe : taux de victoire du boss 5 ≥ 60 % pour chacune, écart médian de TTK du boss ≤ 30 %, et aucune classe n'a à la fois le meilleur TTK et le meilleur taux de survie.
4. **La signature se lit.** 3/3 testeurs savent dire, après 10 s sur l'écran de classe, ce que fait la signature et à quoi elle les engage. En jeu, le feedback de signature est visible sans couleur seule.
5. **La Chasseresse n'est pas gratuite.** Si elle meurt avant la vague 5 dans moins de 10 % des runs de test, la pression de meute (W1-E0) est augmentée avant de toucher à ses chiffres.
6. **Le Pénitent n'est pas un mur.** Il ne doit pas finir un run sans jamais esquiver : un Pénitent qui reste ancré en permanence doit perdre ou frôler la mort au boss 5. Sinon, la réduction de 20 % est trop haute.
7. **L'écran est lisible.** Les trois cartes tiennent à 1280×720, la fantasy et la signature se lisent sans défilement, la sélection ne repose pas sur la couleur seule, et aucun or n'apparaît.
8. **Le portail W9 peut mesurer la promesse du brief.** Chaque classe termine un run complet de 10 vagues avec W2 livré, et la capture du run entier montre trois boucles de décision distinctes.
