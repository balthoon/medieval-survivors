# Équipement — Medieval Survivors

> **Statut** : Designed — modèle de données, passifs et ensembles ; l'implémentation suit ce contrat.
> **Auteur** : game-designer
> **Dernière mise à jour** : 2026-11-10
> **Dernière vérification** : 2026-11-10
> **Pilier servi** : pilier 1 « chaque run est différent » et pilier 3 « le joueur a toujours un choix qui compte » ; le pilier 2 est servi indirectement par les passifs conditionnels.
> **Référence rapide** — Couche : Feature · Priorité : P0 (MVP) · Dépend de : `Catalogue`, `EquipmentData`, `Inventory`, `Stats`, `DamageCalc`, `RunConfig`, `Player.heal` · Est dépendu par : offres de niveau, HUD, boutique W4, localisation W8.

## Overview

L'équipement existe déjà : six emplacements (casque, plastron, bottes, gants, anneau, amulette), une pièce par emplacement, chacune ajoutant une statistique plate. Ce document lui donne une **identité** : chaque pièce peut porter un **passif** — une règle conditionnelle, pas un nombre — et appartenir à un **ensemble** de deux pièces qui accorde un bonus quand les deux sont portées. Le modèle ajoute trois champs à `EquipmentData` (`passive_id`, `passive_value`, `set_id`), une ressource `EquipmentSetData` et un tableau `Catalogue.sets`. Deux passifs (rage, soin) et trois ensembles (Duelliste, Colosse, Coureur des bois) sont livrés en v1. Les statistiques sont **recalculées depuis la base à chaque changement d'équipement** : aucun bonus ne se cumule avec lui-même, et remplacer une pièce retire son passif et son appartenance à l'ensemble. Aucun emplacement, aucun bouton, aucune ressource nouvelle : l'équipement reste une décision de build, pas une seconde couche de power-up.

## Player Fantasy

Ce que le joueur porte doit raconter **comment il joue**, pas seulement combien il tape. Chaque ensemble est une phrase qu'il peut dire à voix haute : « je finis avant eux » (Duelliste), « je tiens la ligne » (Colosse), « je frappe plus souvent qu'eux » (Coureur des bois). Les passifs sont des serments : l'anneau de rubis promet de frapper plus fort **quand la mort est proche** ; l'amulette de sang promet de se refaire **à chaque marche gravie**. Le moment où le joueur choisit entre le heaume ancien et le casque de fer est le moment où il dit ce que sera sa run — et ce choix a un prix visible.

### Aesthetics MDA visées

- **Challenge** : les ensembles sont des objectifs de 5–15 minutes (méso-boucle) que le joueur poursuit à travers les offres.
- **Expression** : deux builds équipés doivent être reconnaissables à l'écran et dans la façon de jouer.
- **Fantasy** : les pièces sont des reliques de la page ; les noms et les couleurs portent la fiction.
- **Sensation** : un critique de Duelliste et un soin d'amulette doivent se voir et s'entendre.

### Besoins psychologiques (SDT)

- **Autonomie** : le casque oppose Duelliste et Colosse ; l'anneau oppose le rubis (rage) à l'argent (Coureur). Aucune pièce n'est un choix par défaut.
- **Compétence** : chaque effet est nommable et lisible dans l'offre ; le joueur sait pourquoi son build fonctionne.
- **Relatedness** : les reliques appartiennent à la même page que les classes ; leur vocabulaire (heaume, cotte, amulette) est cohérent.

### Flow et courbe de difficulté

L'ensemble se complète typiquement entre les vagues 3 et 7 ; le pic du boss 5 est le premier test du build. Un ensemble complété est un relâchement de tension (objectif atteint), la vague suivante en ouvre un autre. La rage maintient la tension à bas PV : elle transforme la peur en puissance, sans jamais être obligatoire. Un joueur qui ne complète aucun ensemble doit encore pouvoir gagner : les pièces seules restent utiles.

## Detailed Design (Detailed Rules)

### 3.1 Le modèle de données

`EquipmentData` gagne trois champs, tous des données pures — la ressource ne contient aucun comportement :

| Champ | Type | Défaut | Rôle |
|---|---|---|---|
| `passive_id` | `StringName` | `&""` | Jeton du passif porté ; vide = aucun passif. |
| `passive_value` | `float` | `0.0` | Magnitude du passif : fraction pour `rage`, points de vie pour `level_up_heal`. Ignoré si `passive_id` est vide. |
| `set_id` | `String` | `""` | Ensemble auquel la pièce appartient ; vide = aucun ensemble. |

`EquipmentSetData` est une nouvelle `Resource` :

| Champ | Type | Défaut | Rôle |
|---|---|---|---|
| `id` | `String` | `""` | Identifiant stable, ASCII, minuscules, jamais traduit. |
| `display_name` | `String` | `""` | Nom affiché, repli français avant W8. |
| `required_pieces` | `int` | `2` | Nombre de pièces portées qui complètent l'ensemble. **2 en v1** ; plage valide 2–6. |
| `stat` | `String` | `"max_hp"` | Canal visé : `damage`, `attack_speed`, `max_hp`, `move_speed`, `crit_chance`, `range`. |
| `amount` | `float` | `0.0` | Fraction pour les stats en pourcentage, points de vie plats pour `max_hp`. |
| `description` | `String` | `""` | Texte d'effet montré au joueur. |

`Catalogue` gagne `sets: Array[EquipmentSetData]` et une résolution `set_by_id(id)` qui retourne `null` pour un identifiant inconnu. Un ensemble est **ouvert par `set_id`** : le catalogue ne liste pas ses pièces membres ; toute pièce portée dont le `set_id` correspond compte. Cette règle évite une liste de membres désynchronisée des `.tres` et permet d'ajouter une troisième pièce plus tard sans réécrire l'ensemble.

Les douze pièces livrées et leurs nouveaux champs :

| id | Nom | Emplacement | Rareté | `stat` | `amount` | `passive_id` | `passive_value` | `set_id` |
|---|---|---|---|---|---|---|---|---|
| `casque_ancien` | Heaume ancien | casque | rare | crit_chance | 0.06 | — | — | `duelliste` |
| `gants_precis` | Gants de duelliste | gants | epique | crit_chance | 0.10 | — | — | `duelliste` |
| `casque_fer` | Casque de fer | casque | commun | max_hp | 15.0 | — | — | `colosse` |
| `plastron_mailles` | Cotte de mailles | plastron | epique | max_hp | 45.0 | — | — | `colosse` |
| `bottes_rapides` | Bottes du vent | bottes | rare | move_speed | 0.16 | — | — | `coureur_des_bois` |
| `anneau_argent` | Anneau d'argent | anneau | peu_commun | attack_speed | 0.08 | — | — | `coureur_des_bois` |
| `anneau_rubis` | Anneau de rubis | anneau | legendaire | damage | 0.22 | `rage` | 0.15 | — |
| `amulette_sang` | Amulette de sang | amulette | mythique | max_hp | 60.0 | `level_up_heal` | 8.0 | — |
| `plastron_cuir` | Plastron de cuir | plastron | commun | max_hp | 20.0 | — | — | — |
| `bottes_cuir` | Bottes de cuir | bottes | commun | move_speed | 0.08 | — | — | — |
| `gants_fer` | Gants ferrés | gants | peu_commun | damage | 0.10 | — | — | — |
| `amulette_lune` | Amulette de lune | amulette | rare | range | 0.15 | — | — | — |

Règles de robustesse :

- `passive_id` vide : `passive_value` est ignoré, même non nul. Un passif ne se devine pas.
- `set_id` vide : la pièce ne compte pour aucun ensemble.
- `id` reste l'identité stable qui repère les doublons ; il ne conditionne ni le passif ni l'appartenance à un ensemble (voir E5).
- Les champs existants (`stat`, `amount`, `rarity`) gardent leur comportement : chaque pièce ajoute sa statistique, de façon additive, et le critique est plafonné à `Stats.CRIT_CAP = 0.75`.

### 3.2 Les trois ensembles

| id | Nom | Pièces requises | `stat` | `amount` | Effet affiché | Membres v1 |
|---|---|---|---|---|---|---|
| `duelliste` | Duelliste | 2 | crit_chance | 0.12 | +12 % de chances de coup critique | `casque_ancien` + `gants_precis` |
| `colosse` | Colosse | 2 | max_hp | 30.0 | +30 points de vie | `casque_fer` + `plastron_mailles` |
| `coureur_des_bois` | Coureur des bois | 2 | attack_speed | 0.10 | +10 % de vitesse d'attaque | `bottes_rapides` + `anneau_argent` |

Règles :

- Le bonus s'applique **si et seulement si** le nombre de pièces portées dont le `set_id` correspond est supérieur ou égal à `required_pieces`, et il s'applique **une seule fois**, quel que soit le nombre de pièces au-delà du seuil.
- Le bonus est **additif dans le même canal que la statistique visée**, exactement comme une pièce : il entre dans `crit_chance_bonus` (plafonné à 0,75), dans `max_hp` (valeur plate) ou dans `attack_speed_mult` (fraction additive). Ce n'est jamais un multiplicateur séparé.
- Le bonus n'est jamais stocké : il est recalculé depuis la base à chaque changement. Remplacer une pièce membre le retire en même temps qu'elle.
- Un ensemble n'est pas une pièce : il ne s'offre pas, ne se remplace pas, n'a ni rareté ni poids d'offre. Il est **gagné** en portant ses pièces.

**Pourquoi 2 pièces et pas 3.** Une run dure 20 minutes et compte une dizaine de panneaux de level-up. Un ensemble de 2 pièces se complète dans cette fenêtre et reste une promesse tenable ; un ensemble de 3 pièces exigerait trois pièces précises sur des emplacements disputés et ne se compléterait qu'exceptionnellement. Le seuil de 2 est aussi ce qui garde le duel de casque lisible : avec 3 pièces, une pièce hors casque pourrait compléter les deux ensembles et le choix disparaîtrait.

### 3.3 Le duel du casque — le choix de build voulu

Duelliste et Colosse exigent tous deux le casque (`casque_ancien` contre `casque_fer`), et `Inventory.SLOTS` ne contient qu'un emplacement `casque`. **Une run ne peut donc pas compléter les deux ensembles.** C'est intentionnel, pas un accident de données :

- **Duelliste** totalise +28 % de critique (6 % + 10 % + 12 %) sur deux emplacements. Avec un critique ×2, cela vaut +28 % de dégâts espérés, avant plafond.
- **Colosse** totalise +90 PV (15 + 45 + 30) sur deux emplacements. Sur un Chevalier à 100 PV, la barre passe à 190 PV.
- Les deux ensembles ne sont pas sur le même axe : l'un accélère la mort des ennemis, l'autre retarde celle du joueur. Aucun ne domine l'autre sur toutes les colonnes du tableau 4.6.
- Le pivot est autorisé et chiffré (4.7) : remplacer `casque_fer` par `casque_ancien` coûte 45 PV (15 + 30) et rapporte 6 % de critique, ou 28 % si `gants_precis` est déjà porté. Le joueur peut changer d'avis, mais il paie.

**Conséquence sur l'anneau.** Coureur des bois exige `anneau_argent` ; la rage vit sur `anneau_rubis`. Porter le rubis, c'est renoncer à Coureur des bois ; porter l'argent, c'est renoncer aux 22 % de dégâts et à la rage. Le choix n'est pas un simple duel de DPS : les bottes du vent apportent 16 % de vitesse de déplacement, qui est une statistique de survie et de repositionnement, pas de dégâts. `Colosse + anneau_rubis` (190 PV, rage sous 95 PV) est une combinaison légitime : l'ensemble Colosse reste complet et la rage s'ajoute sur l'anneau.

**Ensembles compatibles.** Seul Duelliste + Colosse est impossible (un seul casque). Duelliste + Coureur et Colosse + Coureur sont possibles sur quatre emplacements et empilent leurs bonus dans leurs canaux respectifs, chacun une fois.

### 3.4 Les passifs

| `passive_id` | Nom affiché | Porteur v1 | `passive_value` | Agrégation | Moment de lecture |
|---|---|---|---|---|---|
| `rage` | Rage | `anneau_rubis` | 0.15 | Somme des `passive_value` des pièces portées ayant ce jeton. | À la résolution de chaque coup. |
| `level_up_heal` | Soin | `amulette_sang` | 8.0 | Somme des `passive_value` des pièces portées ayant ce jeton. | À chaque niveau gagné. |

Le nom de conception du second passif est **soin** ; son jeton stable est `level_up_heal`, pour rester aligné sur `Stats.level_up_heal` et sur le texte d'effet de `EquipmentData`. Un seul jeton par règle : un passif inconnu ne s'exécute pas (E9).

**Rage.** Tant que `hp / max_hp < RunConfig.rage_hp_threshold`, chaque coup inflige `× (1 + rage_bonus)`. Le seuil est strict : à exactement 50 %, le bonus est inactif. Le multiplicateur est **multiplicatif**, appliqué après `damage_mult` ; il ne s'ajoute pas à `damage_mult`. Avec l'anneau de rubis seul, la pièce donne ×1,22 au-dessus du seuil et ×1,22 × 1,15 = ×1,403 en dessous. La lecture se fait au moment où le coup est résolu, pas au moment du tir (E1).

**Soin.** À chaque niveau gagné, le joueur récupère la somme des `passive_value` de soin des pièces portées, plafonnée par `max_hp`. Pas de sur-soin, pas de stock, pas de soin rétroactif : l'amulette équipée au niveau 4 ne paie pas les niveaux 1 à 3. Le soin est appliqué à l'instant où le niveau est gagné, avant l'ouverture du panneau, pour que la barre derrière le panneau montre déjà la valeur rendue. Deux niveaux successifs paient deux soins, chacun plafonné séparément.

Aucun passif de la v1 ne se déclenche à l'équipement, à la mort d'un ennemi, au contact ou sur un minuteur. Un nouveau déclencheur exige un nouveau jeton et une révision de ce document.

### 3.5 Ordre de calcul et non-doublement

Le recalcul suit toujours le même ordre :

1. `Stats.from_class` construit les statistiques de base de la classe.
2. Chaque amélioration (`apply_upgrade`) s'ajoute.
3. Chaque pièce portée (`apply_equipment`), dans l'ordre de `Inventory.SLOTS`, s'ajoute.
4. Chaque ensemble complété s'ajoute **une fois**, dans le canal de sa statistique.
5. Les totaux de passifs (`rage_bonus`, `level_up_heal`) sont lus depuis les pièces portées.
6. À la résolution d'un coup : `damage × M_niveau × damage_mult × rage_mult`, puis le critique.
7. Au niveau gagné : le soin.

La règle qui rend le non-doublement structurel : les étapes 2 à 5 partent **des statistiques de base à chaque recalcul**, jamais du résultat précédent. Remplacer une pièce reconstruit tout ; un ensemble complété puis cassé ne laisse aucun résidu. Un double appel au recalcul avec le même inventaire produit exactement les mêmes valeurs.

### 3.6 Lisibilité et interface

- Une offre d'équipement qui **complète** un ensemble nomme l'ensemble et son bonus avant les nombres : « Complète Duelliste : +12 % critique ». Une offre qui ne le complète pas ne doit pas le suggérer.
- Le panneau d'équipement du HUD montre la progression des ensembles proches ou complétés : « Duelliste 1/2 », « Colosse 2/2 ». Aucun signal ne repose sur la couleur seule.
- L'état **rage** est visible sans couleur seule (icône, contour ou jauge) : le joueur doit savoir quand le bonus est actif, puisque ses dégâts changent.
- Le soin de niveau affiche le montant **réellement rendu** et la barre ; à PV pleins, il affiche 0, jamais un « +8 » mensonger.
- Le bonus d'ensemble est attribué à l'ensemble, pas à une pièce, dans les textes d'offre et de HUD.

### 3.7 Ce que l'équipement ne fait pas (v1)

- Aucun septième emplacement : les six emplacements existants sont la limite.
- Aucun bouton, aucune activation manuelle, aucun temps de recharge, aucune ressource à dépenser.
- Aucun niveau d'équipement : une pièce n'a pas de niveau et ne s'améliore pas.
- Aucun ensemble au-delà de `required_pieces = 2`.
- Aucun reroll spécifique à l'équipement : les rerolls normaux du level-up s'appliquent.
- Aucun changement de `RunConfig.equipment_offer_weight` (0,9) ni du filtre d'offres existant dans ce document.
- Aucun passif qui se déclenche sur une mort, un coup reçu ou un minuteur.

## Formulas

### 4.1 Variables

| Variable | Définition | Plage v1 |
|---|---|---|
| `damage` | Dégâts de base d'une arme (`WeaponData.damage`). | 7–26 |
| `M_niveau` | `1 + level_damage_step × (niveau − 1)`, multiplicateur de niveau de l'arme. | 1,00–1,75 |
| `damage_mult` | Multiplicateur global de dégâts : somme additive des améliorations et des pièces. | 1,00–2,50 environ |
| `rage_bonus` | Somme des `passive_value` des pièces portées avec `passive_id = &"rage"`. | 0–0,30 |
| `rage_mult` | `1` ou `1 + rage_bonus` selon le seuil. | 1,00–1,30 |
| `R` | `RunConfig.rage_hp_threshold`. | 0,3–0,6 ; défaut 0,5 |
| `hp`, `HP_max` | Points de vie courants et maximum courant. | 0–250 environ |
| `crit_chance` | Chance de critique finale d'une arme, après bonus et plafond. | 0–0,75 |
| `crit_multiplier` | Multiplicateur de critique propre à l'arme. | 2,0–2,2 |
| `n(s)` | Nombre de pièces portées dont `set_id = s.id`. | 0–6 |
| `required_pieces` | Seuil de complétion d'un ensemble. | 2 en v1 |
| `soin` | Somme des `passive_value` de soin des pièces portées. | 0–15 par niveau |

### 4.2 Dégâts effectifs et rage

```text
rage_mult = 1 + Σ passive_value(p)
            pour p porté, p.passive_id = &"rage", et hp / HP_max < R
          = 1
            sinon (dont hp / HP_max = R exactement)

D = damage × M_niveau × damage_mult × rage_mult
D_critique = D × crit_multiplier
```

- La rage est un multiplicateur **après** `damage_mult` ; elle ne s'y ajoute pas.
- Le seuil est strict : à `hp / HP_max = 0,5` avec `R = 0,5`, `rage_mult = 1`.
- Exemple : épée longue, niveau 3 (`level_damage_step = 0,25`, donc `M_niveau = 1,50`), `damage_mult = 1,42` (anneau de rubis +22 %, amélioration Dégâts +20 %), `hp = 45 / 150`, `R = 0,5`.
  - `45 / 150 = 0,30 < 0,5` → `rage_mult = 1,15`.
  - `D = 12 × 1,50 × 1,42 × 1,15 = 29,394`.
  - Critique ×2 : `58,788`.
  - À `hp = 75 / 150` (exactement 0,5) : pas de rage, `D = 25,56`. À `76 / 150` : idem.
  - L'anneau seul, niveau 1, sans amélioration : au-dessus du seuil `12 × 1,00 × 1,22 = 14,64` par coup ; en dessous `14,64 × 1,15 = 16,836`. Le bonus est bien `×1,15`, pas `+15` dégâts.

### 4.3 Application d'un bonus de statistique (pièce ou ensemble)

Pour les statistiques en pourcentage :

```text
M_stat = 1 + Σ piece.amount(stat) + Σ set.amount(set.stat = stat, set complété)
```

Pour `max_hp`, qui est plat :

```text
HP_max = base_max_hp + Σ piece.amount(max_hp) + Σ set.amount(max_hp)
```

Pour le critique, qui est un bonus additif plafonné :

```text
crit_bonus  = clamp(Σ piece.amount(crit_chance) + Σ set.amount(crit_chance), 0, 0,75)
crit_chance = clamp(weapon.crit_chance + crit_bonus, 0, 0,75)
```

- Un bonus d'ensemble vaut exactement ce qu'une pièce de même `amount` vaudrait : il s'ajoute, il ne se multiplie pas.
- Exemple Duelliste : `crit_bonus = 0,06 + 0,10 + 0,12 = 0,28` ; épée longue à 5 % → `crit_chance = 0,33` ; espérance de dégâts `1 + 0,33 × (2,0 − 1) = 1,33`.
- Exemple Coureur des bois : `attack_speed_mult = 1 + 0,08 + 0,10 = 1,18` ; avec l'amélioration Cadence (+15 %) → `1,33`. Le +10 % de l'ensemble vaut le même poids qu'une pièce à +10 %.
- Exemple Colosse : `HP_max = 100 + 15 + 45 + 30 = 190` sur un Chevalier.
- Le plafond de critique n'est pas un knob d'équipement : l'ensemble ne peut pas le relever. Une somme nominale de 0,80 est lue 0,75.

### 4.4 Comptage d'un ensemble

```text
n(s) = |{ p porté : p.set_id = s.id }|
bonus(s) appliqué si n(s) >= s.required_pieces, une seule fois
```

- `n = 0` : aucun membre. `n = 1` : un membre sur deux, aucun bonus. `n = 2` : bonus.
- Un `n = 3` hypothétique donnerait toujours un seul bonus, jamais deux.
- Le comptage porte sur les six emplacements équipés, pas sur le catalogue ni sur l'historique de la run. Une pièce remplacée sort du compte immédiatement.

### 4.5 Soin de niveau

```text
soin = Σ passive_value(p)
       pour p porté et p.passive_id = &"level_up_heal"

hp' = min(hp + soin, HP_max)
```

- Exemple : `amulette_sang` (+60 PV max) portée par un Chevalier, `HP_max = 160`, `soin = 8`.
  - Niveau gagné à `hp = 60` → `68 / 160`.
  - Niveau gagné à `hp = 158` → `160 / 160` : 2 PV rendus, 6 perdus, aucun stock.
  - Niveau gagné à `hp = 160` → `160 / 160` : 0 rendu, aucun soin stocké.
  - Devenu niveau 4 avec l'amulette puis niveau 12 : 8 niveaux × 8 = 64 PV rendus au maximum, chaque soin plafonné séparément.
- Le soin est lu à l'instant où le niveau est gagné, depuis l'équipement porté à cet instant. Une amulette équipée après le niveau ne le paie pas.

### 4.6 Tableau de référence — Chevalier, niveau 1, sans amélioration

Hypothèses : Chevalier (100 PV, 220 px/s), épée longue niveau 1 (12 dégâts, 1,8 attaque/s, critique ×2), aucune amélioration, cible unique, espérance de critique (pas de tirage). Le DPS espéré vaut `12 × 1,8 × (1 + crit_chance) × damage_mult`.

| Build | Critique | PV max | Cadence × | Vitesse (px/s) | DPS espéré | Seuil de rage |
|---|---|---|---|---|---|---|
| Aucun équipement | 0,05 | 100 | 1,00 | 220 | 22,68 | — |
| Duelliste (`casque_ancien` + `gants_precis`) | 0,33 | 100 | 1,00 | 220 | 28,73 | — |
| Colosse (`casque_fer` + `plastron_mailles`) | 0,05 | 190 | 1,00 | 220 | 22,68 | — |
| Coureur des bois (`bottes_rapides` + `anneau_argent`) | 0,05 | 100 | 1,18 | 255,2 | 26,76 | — |
| `anneau_rubis` seul | 0,05 | 100 | 1,00 | 220 | 27,67 (31,82 sous le seuil) | 50 PV |
| Colosse + `anneau_rubis` | 0,05 | 190 | 1,00 | 220 | 27,67 (31,82 sous le seuil) | 95 PV |

Lecture : Duelliste gagne sur les dégâts, Colosse sur les PV, Coureur sur la cadence et la mobilité, le rubis sur les dégâts conditionnels. Aucun build n'est premier sur toutes les colonnes. Le tableau est la référence de non-domination de la v1 ; il est recalculé à chaque changement de montant.

### 4.7 Coût chiffré d'un pivot de casque

Situation de départ : Chevalier, `casque_fer` + `plastron_mailles` (Colosse), `HP_max = 190`, `crit_chance = 0,05`.

| Pivot | PV max | Critique | Delta |
|---|---|---|---|
| `casque_fer` → `casque_ancien`, sans `gants_precis` | 145 | 0,11 | −45 PV, +6 % critique ; Colosse perdu, Duelliste incomplet |
| `casque_fer` → `casque_ancien`, avec `gants_precis` | 145 | 0,33 | −45 PV, +18 % critique par rapport à Colosse + gants ; Duelliste complété |

Le pivot est donc toujours possible, toujours chiffrable, et jamais gratuit. C'est la garantie que le duel de casque reste une décision et non un verrou.

## Edge Cases

| # | Cas | Résultat attendu |
|---|---|---|
| E1 | **La rage traverse le seuil pendant qu'un coup est en vol.** | Le multiplicateur est lu **au moment où le coup est résolu**, pas au tir. Un projectile parti à 60 / 100 PV qui touche alors que le joueur est à 40 / 100 applique ×1,15 ; parti à 40 / 100 puis soigné à 60 / 100 avant l'impact, il applique ×1,00. La `WeaponData` et le niveau restent ceux capturés au tir (règle de `weapons.md` E19) ; la rage, elle, dépend de l'état du joueur et n'est pas snapshottée. Chaque coup lit `hp / HP_max` à sa propre résolution. |
| E2 | **Soin à PV pleins.** | `hp' = min(hp + soin, HP_max)` : 0 PV rendu, aucun stock, aucune erreur. Le feedback affiche le montant réellement rendu (0), jamais le montant nominal (8). |
| E3 | **Une pièce est remplacée en cours de run.** | `Inventory.equip` remplace la pièce de l'emplacement ; le recalcul repart de la base. Le passif et l'appartenance à l'ensemble de la pièce sortante disparaissent dans le même recalcul. Si `HP_max` baisse, les PV courants sont plafonnés à la nouvelle valeur ; le remplacement ne soigne jamais. |
| E4 | **Un ensemble est complété par la pièce qui en remplace une autre.** | La nouvelle pièce entre et l'ancienne sort dans le même `equip` ; le comptage est fait après l'échange. L'ensemble complété s'applique une fois ; l'ensemble auquel l'ancienne pièce appartenait n'est plus compté. Aucun bonus transitoire : le bonus n'est jamais stocké, seulement recalculé. |
| E5 | **Un passif est porté par une pièce dont l'`id` est vide.** | Le passif s'applique normalement : `id` repère les doublons, il ne conditionne pas les effets. La pièce est un défaut de données ; le test de validité du catalogue échoue sur tout `id` vide ou dupliqué. Deux pièces sans `id` sur des emplacements différents appliquent chacune leur effet ; sur le même emplacement, la dernière équipée gagne, sans erreur. |
| E6 | **`set_id` inconnu du catalogue.** | Ignoré à l'exécution : la statistique propre de la pièce s'applique, aucun bonus d'ensemble n'est accordé, un `push_warning` est émis. Le test de données échoue sur tout `set_id` qui ne résout pas vers une entrée de `Catalogue.sets`. Un identifiant inconnu ne doit jamais accorder un bonus deviné. |
| E7 | **Deux pièces du même ensemble, une seule portée.** | `n = 1 < required_pieces = 2` : aucun bonus. La statistique propre de la pièce s'applique normalement. Aucun effet « à moitié » n'est accordé. |
| E8 | **Une pièce appartient à un ensemble et porte un passif.** | Les deux s'appliquent indépendamment : la statistique de la pièce, son passif, et sa contribution au comptage de l'ensemble. Aucun ordre de lecture entre `set_id` et `passive_id` : le même recalcul lit les deux champs. Une pièce de test avec `set_id = duelliste` et `passive_id = rage` compte pour Duelliste et déclenche la rage sous le seuil. |
| E9 | **`passive_id` inconnu.** | Aucun effet, `push_warning`, et le test de données échoue sur tout jeton absent de `{ rage, level_up_heal }`. Un jeton inconnu ne retombe pas sur un passif par défaut. |
| E10 | **`passive_value` nul ou négatif.** | Zéro est un no-op à l'exécution : la pièce n'est qu'une pièce de statistique. Une valeur négative est ignorée à l'exécution (comptée 0) et le test de données échoue, car elle sortirait des plages sûres. Aucune valeur négative ne doit transformer un anneau légendaire en malus silencieux. |
| E11 | **Le plafond de critique est atteint.** | Le bonus d'ensemble entre dans `crit_chance_bonus` puis est plafonné à 0,75, comme une pièce. Duelliste + plusieurs améliorations Precision peuvent atteindre le plafond ; le tableau 4.6 et les tests utilisent la valeur plafonnée, jamais la somme nominale. L'ensemble ne relève pas `Stats.CRIT_CAP`. |
| E12 | **L'amulette de sang est équipée en cours de run.** | Aucun soin rétroactif : seuls les niveaux gagnés après l'équipement paient. Les +60 PV max relèvent le plafond mais ne remplissent pas les PV courants (`hp` reste inchangé, seulement plafonné à la baisse). La barre montre donc une portion vide plus grande ; c'est le soin par niveau qui la remplit, pas l'équipement. |
| E13 | **Le joueur meurt sur la même frame qu'un niveau.** | La mort gagne : le niveau n'est pas gagné, aucun soin n'est payé, aucun panneau ne s'ouvre. Si le panneau ne peut pas être construit (pool d'offres vide), le niveau n'est pas consommé et le soin n'est pas payé non plus. |
| E14 | **Deux ensembles sont complétés en même temps.** | Autorisé sauf Duelliste + Colosse (un seul casque). Duelliste + Coureur et Colosse + Coureur empilent leurs bonus, chacun une fois, dans leurs canaux respectifs. Un fixture qui force les deux casques ne doit accorder que l'ensemble du casque réellement porté. |
| E15 | **Une nouvelle run démarre.** | `Inventory.setup_starting` vide l'équipement : aucun passif, aucun ensemble, aucun soin en attente ne survit d'une run à l'autre. Les `EquipmentData` et `EquipmentSetData` sont partagés et ne portent aucun état de run. |

## Dependencies

| Système | Sens | Ce que ce document attend | Propriétaire |
|---|---|---|---|
| `src/data/equipment_data.gd` | fournit | `passive_id`, `passive_value`, `set_id`, la liste des jetons connus, et un `effect_text` qui couvre les passifs (rage et soin). | ce document |
| `src/data/equipment_set_data.gd` (nouveau) | fournit | `id`, `display_name`, `required_pieces`, `stat`, `amount`, `description`. Aucune logique. | implémentation |
| `src/data/catalogue.gd`, `data/catalogue.tres` | fournit | `sets: Array[EquipmentSetData]`, `set_by_id`, les trois ensembles et la résolution de chaque `set_id` des pièces. | implémentation, test de données |
| `src/classes/inventory.gd` | fournit | `equip`, remplacement par emplacement, `passive_total(&"rage")`, `passive_total(&"level_up_heal")`, comptage des ensembles par `set_id`. | existant, étendu |
| `src/classes/stats.gd` | fournit | `rage_bonus`, `rage_hp_threshold`, `level_up_heal`, application additive des ensembles, plafond `CRIT_CAP = 0,75`. | existant, étendu |
| `src/classes/damage_calc.gd` | consomme | Multiplicateur de rage lu à la résolution, avant le critique. | existant, étendu |
| `src/main.gd` | fournit et consomme | `_recompute_stats` depuis la base, application des ensembles une fois, soin de niveau avant l'ouverture du panneau, garde de mort. | existant, étendu |
| `src/data/run_config.gd` | fournit | `rage_hp_threshold = 0,5`. | ce document |
| `src/actors/player.gd` | fournit | `heal` plafonné à `stats.max_hp`. | existant |
| `src/classes/offer.gd`, `src/ui/hud.gd` | consomme | Nommer l'ensemble à la complétion, afficher la progression « 1/2 » ou « 2/2 », rendre la rage visible sans couleur seule, afficher le soin réellement rendu. | offres / UI |
| `design/gdd/weapons.md` | croisé | `M_niveau` et la règle de snapshot E19 pour le niveau et la ressource d'arme ; ce document ne modifie pas les armes. | systems-designer |
| `design/gdd/classes.md` | croisé | Statistiques de base et signatures ; l'équipement s'ajoute après la classe ; aucune classe n'est exclue d'un ensemble. | game-designer |
| `design/gdd/systems-index.md` | croisé | Doit lister ce document. | orchestrateur / game-designer |
| `docs/localization-standard.md` | fournit | Clés `equipment.<id>.name`, `equipment.<id>.desc`, `equipment.set.<id>.name`, `equipment.passive.<id>`. | localization-lead (W8) |
| W4 — boutique et prix | consomme | Si un prix par rareté apparaît, un ensemble se juge sur le prix de ses deux pièces, jamais sur un prix du bonus. | economy-designer |

**Réciprocité.** `weapons.md` et `classes.md` sont écrits par d'autres agents et ne sont **pas** modifiés ici. Leurs propriétaires doivent citer `equipment.md` pour le multiplicateur de rage (appliqué après `damage_mult`, avant le critique) et pour les statistiques d'ensemble qui s'ajoutent aux leurs. `systems-index.md` référence ce document. Le bonus d'ensemble ne crée aucune dépendance circulaire : il lit `Catalogue.sets` et les pièces portées, et n'écrit rien.

## Tuning Knobs

Tous les montants vivent dans les `.tres` (`data/equipment/*.tres`, `data/sets/*.tres` ou une sous-ressource de `catalogue.tres`), jamais dans le code. Catégories : **feel** (ressenti, playtest), **curve** (forme de la progression, calcul), **gate** (pacing et seuils).

| Paramètre | Défaut | Plage sûre | Catégorie | Effet hors plage |
|---|---|---|---|---|
| `anneau_rubis.passive_value` (`rage`) | 0,15 | 0,05–0,30 | curve | Sous 0,05, le bonus est imperceptible ; au-delà de 0,30, l'anneau de rubis domine tous les autres anneaux et le choix Coureur disparaît. |
| `amulette_sang.passive_value` (`level_up_heal`) | 8,0 | 4–15 | curve | Sous 4, l'amulette n'est qu'un +60 PV ; au-delà de 15, le soin remplace l'esquive sur une dizaine de niveaux. |
| `RunConfig.rage_hp_threshold` | 0,5 | 0,3–0,6 | gate | Sous 0,3, la fenêtre est trop létale pour être recherchée ; au-delà de 0,6, le bonus est presque toujours actif et la condition disparaît. |
| `duelliste.amount` | 0,12 | 0,08–0,16 | curve | Sous 0,08, l'ensemble vaut moins qu'une pièce de critique ; au-delà de 0,16, le plafond de 0,75 est atteint trop tôt. |
| `colosse.amount` | 30,0 | 20–40 | curve | Sous 20, l'ensemble ne paie pas le duel de casque ; au-delà de 40, le build Colosse trivialise la vague 10. |
| `coureur_des_bois.amount` | 0,10 | 0,06–0,14 | curve | Sous 0,06, l'ensemble est invisible ; au-delà de 0,14, la cadence sature les panneaux d'offres. |
| `EquipmentSetData.required_pieces` | 2 | 2–3 (2 en v1) | gate | À 3, l'ensemble ne se complète plus dans une run de 20 minutes et le duel de casque disparaît au profit d'une pièce hors casque. |
| `RunConfig.equipment_offer_weight` | 0,9 | 0,6–1,2 | gate | Existant, non modifié ici. Trop haut, l'ensemble se complète avant que le joueur ait vu l'alternative ; trop bas, il ne se complète jamais. |

**Règle de réglage.**

- On règle d'abord le seuil (`rage_hp_threshold`) au playtest, puis les montants au calcul, jamais les deux dans le même passage.
- Toute modification d'un `amount` de pièce ou d'ensemble exige de rejouer le tableau 4.6 et les critères 3 à 6. Un réglage qui rend un build premier sur toutes les colonnes doit être refusé ou compensé.
- Un changement de `required_pieces` est un changement de design : il passe par `/propagate-design-change design/gdd/equipment.md` avant d'être commité.
- Le plafond `Stats.CRIT_CAP = 0,75` n'est pas un knob d'équipement. Aucun ensemble ne doit le relever pour se rendre viable.

## Acceptance Criteria

### 8.1 Critères fonctionnels (testables automatiquement)

1. **Validité des données.** Un test gdUnit4 charge les douze `.tres` et échoue si : un `id` est vide ou dupliqué ; un emplacement n'est pas dans `Inventory.SLOTS` ; une `stat` est inconnue ; une rareté n'est pas dans `EquipmentData.RARITY_WEIGHTS` ; un `passive_id` n'est pas dans `{ vide, rage, level_up_heal }` ; un `passive_value` non vide sort de sa plage (rage 0,05–0,30 ; soin 4–15) ; un `set_id` non vide ne résout pas vers `Catalogue.sets`. (Catalogue, condition remplie/non remplie)
2. **Ensembles au catalogue.** `Catalogue.sets` contient exactement `duelliste`, `colosse` et `coureur_des_bois` ; chaque ensemble a `required_pieces = 2`, une `stat` connue, un `amount` dans sa plage, une `description` non vide, et exactement deux pièces membres dans le catalogue v1. `set_by_id` retourne `null` pour un identifiant inconnu. (Catalogue)
3. **Bonus appliqué une seule fois.** Sur un Chevalier avec `casque_ancien` + `gants_precis`, `crit_bonus = 0,28`. Deux recalculs successifs avec le même inventaire donnent exactement la même valeur. Un fixture avec une troisième pièce `duelliste` donne toujours 0,28, jamais 0,40. (Non-doublement)
4. **Ensemble incomplet.** Une seule pièce Duelliste donne 0,06 (heaume) ou 0,10 (gants), jamais 0,28. Une seule pièce Colosse n'ajoute pas les 30 PV. Une seule pièce Coureur n'ajoute pas les 10 % de cadence. (Condition non remplie)
5. **Remplacement.** Chevalier 100 PV, `casque_fer` + `plastron_mailles` : 190 PV. Remplacer `casque_fer` par `casque_ancien` : 145 PV, pas de Colosse, critique 0,11. Remplacer `gants_precis` hors d'une paire Duelliste : `crit_bonus` passe de 0,28 à 0,06. Aucune valeur résiduelle. (Remplacement)
6. **Rage — seuil.** Avec `anneau_rubis` et `R = 0,5` : à 50 / 100 PV, `rage_mult = 1,00` ; à 49 / 100, 1,15 ; à 51 / 100, 1,00. Avec deux pièces de rage à 0,15 et 0,05, `rage_mult = 1,20` sous le seuil. (Rage, condition)
7. **Rage — coup en vol.** Un projectile parti à 60 / 100 PV et résolu à 40 / 100 applique ×1,15 ; parti à 40 / 100 et soigné à 60 / 100 avant l'impact, il applique ×1,00. Le niveau et la `WeaponData` restent ceux du tir (`weapons.md` E19). (Rage, snapshot)
8. **Rage — formule.** Épée niveau 3, `damage_mult = 1,42`, 45 / 150 PV : `D = 29,394 ± 0,001` ; critique ×2 = 58,788. À 75 / 150 PV : `D = 25,56`, sans rage. (Formule)
9. **Soin.** `amulette_sang`, `HP_max = 160` : niveau gagné à 60 PV → 68 ; à 158 PV → 160 avec 2 PV rendus et 6 perdus ; à 160 PV → inchangé avec 0 rendu. Des niveaux 4 à 12 rendent au plus 64 PV. (Soin)
10. **Soin — pas rétroactif, pas sur équipement.** Équiper `amulette_sang` au niveau 4 ne soigne pas et ne paie que les niveaux 5 et suivants. L'équiper à PV pleins relève le maximum sans remplir la barre. Aucun passif ne se déclenche à l'équipement ni dans `_process`. (Déclencheurs)
11. **Données inconnues.** `set_id` inconnu : la statistique de la pièce s'applique, aucun ensemble, avertissement. `passive_id` inconnu : aucun effet, avertissement. `passive_id` vide : `passive_value` ignoré. `passive_value` négatif : ignoré, avertissement, et le test de données échoue. Une pièce sans `id` mais avec un passif applique son passif ; le test de données échoue. Aucun crash. (Robustesse)
12. **Pièce à ensemble et passif.** Un fixture avec `set_id = duelliste` et `passive_id = rage` compte pour Duelliste et déclenche la rage sous le seuil ; les deux valeurs apparaissent dans le même recalcul, sans ordre imposé. (Interaction)
13. **Deux ensembles.** Duelliste + Coureur sur quatre emplacements : les deux bonus s'appliquent une fois. Colosse + Coureur : idem. Duelliste + Colosse avec un seul casque : seul l'ensemble du casque porté s'applique ; un fixture qui force les deux ne les accorde jamais tous les deux. (Coexistence)
14. **PV et remplacement.** Équiper +60 PV max à PV pleins laisse les PV courants inchangés. Remplacer `amulette_sang` par `amulette_lune` à 150 / 160 PV donne `HP_max = 100` et `hp = 100` : jamais au-dessus du maximum, jamais négatif. (Plafonnement)
15. **Tableau de référence.** Les six lignes du tableau 4.6 sont reproduites à 0,01 près par le calcul réel, avec un critique injecté ou en espérance. (Modèle)
16. **Offre et HUD lisibles.** Une offre qui complète un ensemble nomme l'ensemble et son bonus avant les nombres ; sinon elle ne le suggère pas. Le HUD affiche la progression d'ensemble sans couleur seule et l'état de rage sans couleur seule. (Lisibilité)

### 8.2 Critères expérientiels (playtest)

1. **Le build se nomme.** Après 10 secondes sur le HUD, 3 testeurs sur 3 savent dire quel ensemble ils poursuivent et ce qu'il donnera.
2. **Le duel de casque est un vrai choix.** 5 runs Duelliste et 5 runs Colosse : taux de victoire du boss 5 ≥ 60 % pour chaque build, aucun build n'est à la fois le meilleur en temps de tuer et le meilleur en survie, et aucun testeur ne déclare l'un « évidemment meilleur ».
3. **La rage se sent sans être obligatoire.** Une run avec l'anneau de rubis montre l'état de rage sans couleur seule ; le joueur sait dire quand il est actif ; une run sans l'anneau reste viable.
4. **Le soin est visible et honnête.** Chaque level-up avec l'amulette montre le montant réellement rendu ; à PV pleins, aucun faux soin n'est affiché.
