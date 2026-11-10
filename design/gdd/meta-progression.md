# Méta-progression — Medieval Survivors

> **Statut** : Designed (W7-E1) — modèle, contrat et économie ; l'implémentation est W7-E2.
> **Auteur** : game-designer / economy-designer
> **Dernière mise à jour** : 2026-11-10
> **Dernière vérification** : 2026-11-10
> **Pilier servi** : pilier 1 « chaque run est différent » (un quatrième emplacement élargit l'espace de build) et pilier 3 « le joueur a toujours un choix qui compte » (classe, arène, difficulté) ; ce système ne sert pas le pilier 2.
> **Référence rapide** — Couche : Polish · Priorité : Full Vision (W7) · Dépend de : `EnemyData`, `main.gd`, `HUD`, `ClassData`, Localisation, ADR-0007 · Est dépendu par : W7-E2 (implémentation), W8-E3 (traduction des chaînes méta).

## Overview

Une run peut mourir sans que la session entière soit effacée : chaque ennemi tué laisse de l'**encre**, une monnaie persistante séparée de l'XP, créditée à la fin de la run — victoire à 100 %, défaite à 70 %. L'encre s'accumule entre les sessions dans un fichier local (`user://meta.cfg`, autoload `MetaSave`) et achète **quatre déblocages durables, dans cet ordre** : le quatrième emplacement d'arme, la Chasseresse comme deuxième classe de départ, une variante visuelle d'arène, puis les paliers de difficulté. Aucun déblocage n'achète de puissance permanente : ils achètent de l'espace de décision, du contenu de départ ou du défi. Un écran d'accueil affiche l'encre, les déblocages et un bouton « Jouer » ; un joueur avec un fichier vierge peut lancer et terminer une run complète sans jamais voir une erreur. La méta est un **enregistrement de la marge**, pas un arbre de talents.

## Player Fantasy

Le joueur doit ressentir que **la marge se souvient même quand la page se déchire**. Mourir en vague 6 n'est pas « rien » : une ligne d'encre s'inscrit, visible sur l'écran d'accueil, et rapproche du prochain déblocage. Le plaisir n'est pas celui d'un compteur qui monte pour lui-même ; c'est celui de **rouvrir le jeu avec une option qui n'existait pas** — un quatrième emplacement qui change la lecture des offres, une deuxième classe qui change la position de départ, une arène réencrée qui change la couleur de la page, un palier qui demande de prouver qu'on a compris le Conte.

Ce que le joueur doit pouvoir dire après une défaite : « je n'ai pas gagné, mais j'ai marqué la page — et la prochaine run commence avec une possibilité de plus ». Ce qu'il ne doit jamais ressentir : « je dois farmer la vague 1 », « j'aurais dû sauvegarder avant de mourir », « la méta me rend plus fort sans rien décider ». L'encre est la trace d'un récit, pas une seconde barre d'XP.

**Esthétiques MDA visées.** *Challenge* (les paliers de difficulté donnent une raison de rejouer le même contenu), *Discovery* (la Chasseresse et la variante d'arène sont du contenu à découvrir), *Expression* (le quatrième emplacement et la classe laissent construire autrement). *Fantasy* est servie par le cadre « la marge » déjà ratifié dans `game-concept.md`, sans dialogue ni cinématique.

**Besoins SDT servis.** *Autonomie* : quatre décisions de départ ou de build qui n'existaient pas. *Compétence* : les paliers de difficulté rendent la maîtrise lisible et récompensée en encre. *Relatedness* : faible par nature ; le lien passe par la continuité du monde (« la page garde la trace »), pas par un personnage.

**Lecture Flow.** Le premier déblocage tombe après une à trois runs (80 d'encre) — assez tôt pour que la boucle méta soit comprise dans la première session de 20–30 minutes, assez tard pour que la première mort ne soit pas une récompense automatique. Les deux premiers déblocages sont atteignables en une session de 3 à 5 runs ; les deux suivants demandent plusieurs victoires, ce qui déplace la cible du *flow* vers la maîtrise plutôt que vers le temps passé.

## Detailed Rules

### 3.1 Le contrat : ce qui survit, ce qui ne survit pas

| Élément | Survit à la run ? | Où il vit | Remarque |
|---|---|---|---|
| Encre (solde et cumul à vie) | Oui | `MetaSave` → `user://meta.cfg` | Seule monnaie persistante. |
| Déblocages achetés | Oui | même fichier, liste `[unlocks] purchased` | Quatre identifiants stables. |
| Classes, arène et difficulté sélectionnées | Oui | même fichier, section `[selection]` | Validées au chargement ; repli sur le défaut. |
| Records (`runs`, `wins`, `best_wave`, `best_ink`) | Oui | même fichier, section `[records]` | Informatifs ; ne conditionnent aucun déblocage. |
| XP, niveau, armes, équipement, PV, vagues | Non | état de run, détruit au rechargement | Inchangé par ce document. |
| Or / trophées de la boutique de run | Non | `design/gdd/run-economy.md` (W4) | **Jamais** convertibles en encre et réciproquement. |
| Réglages audio, contrôles, langue | Non | futur `SettingsStore` (W6-E2) | Fichier distinct ; `MetaSave` ne les lit ni ne les écrit. |
| Run en cours (reprise après fermeture) | Non | — | Hors périmètre : quitter une run l'abandonne. |

**Règles de séparation.**

- L'encre n'est **pas** de l'XP et ne s'échange jamais contre elle. L'XP reste une ressource de run, non persistante.
- Les valeurs de gameplay (coûts, taux, multiplicateurs, `ink_value`) ne vivent **jamais** dans la sauvegarde. Le fichier utilisateur ne contient que de l'**état** ; les règles vivent dans `data/meta/meta_config.tres`, `data/meta/unlocks/*.tres` et `data/enemies/*.tres`, chargés depuis `res://`.
- Un déblocage acheté ne modifie que le **point de départ** ou l'**espace disponible** : jamais une statistique du joueur, jamais les dégâts, jamais les PV. C'est la déclaration anti-pilier de `game-concept.md` (« pas de puissance permanente achetée par la méta »), rendue exécutable.
- L'ordre des déblocages est une **donnée** (`MetaConfig.unlocks`, tableau ordonné de `UnlockData`), pas une constante de script.

### 3.2 L'encre : source, valeur et périmètre

- **Source unique : une mort d'ennemi.** Chaque ennemi tué pendant la run ajoute `EnemyData.ink_value` à un accumulateur de run (`_run_ink` dans `main.gd`). Aucune autre source : pas d'encre pour le temps passé, les dégâts infligés, les vagues survécues, les objets ramassés ou la victoire elle-même.
- **Le boss compte.** `seigneur_squelette` porte un `ink_value` explicite (25) ; chaque instance tuée compte une fois. Les deux rencontres (vagues 5 et 10) rapportent donc 50 d'encre sur une victoire.
- **Une valeur par archétype, jamais une constante globale.** `EnemyData.ink_value: int = 1` est un champ de ressource, au même titre que `xp_value`. Un ennemi sans champ explicite vaut 1 ; zéro est une valeur d'auteur légitime et signifie « ne rapporte rien ».
- **Invocation = pas d'encre.** Un ennemi invoqué (les marcheurs du Copiste, `enemy-behaviors.md` §8) suit la même porte de récompense que l'XP : s'il ne donne pas d'XP, il ne donne pas d'encre. La règle est portée par le même interrupteur de récompense que l'XP, jamais par `ink_value` seul.
- **Ennemi non tué = pas d'encre.** Un ennemi qui expire, sort de l'arène ou est retiré par le directeur de vagues ne rapporte rien.
- **Valeurs de référence** (voir F1 pour la table et la justification) : 1 pour le squelette et le loup, 2 pour la Plume et l'orc, 3 pour la Tache, 5 pour le Copiste, 25 pour le Seigneur. Une run victorieuse de référence rapporte environ 285 d'encre (F5).

### 3.3 Le crédit de fin de run

Le crédit est la seule écriture d'encre dans le profil. Il a lieu **une fois**, à la première transition terminale de la run.

```text
encre_créditée = plancher( encre_de_run × taux_résultat × multiplicateur_difficulté )
taux_résultat = 1,00 si victoire · 0,70 si défaite
```

- **Victoire** : 100 %. **Défaite** : 70 %, arrondi à l'entier inférieur (décision A3 du plan : un joueur qui meurt en vague 2 doit tout de même marquer la page).
- **Une seule fois.** `main.gd` porte une garde `_run_settled`. Le premier état terminal — victoire ou mort — crédite et arme la garde ; tout appel ultérieur est un no-op. Une mort et une victoire sur la même frame donnent une **défaite** : c'est la règle de priorité déjà fixée par `classes.md` §4.5 (« la mort gagne »), et le crédit suit le résultat affiché, jamais l'inverse.
- **Quitter n'est pas mourir.** Fermer la fenêtre, revenir à l'accueil ou recharger la scène (`R`) avant un état terminal **n'accrédite rien** : l'accumulateur de run est détruit avec la scène. Ce n'est pas une punition ajoutée, c'est l'absence de résultat. L'exploit est fermé dans les deux sens : quitter avant de perdre donne 0 au lieu de 70 %, quitter avant de gagner donne 0 au lieu de 100 %.
- **Un rechargement après règlement ne recrédite pas.** La garde vit dans l'instance de scène ; une nouvelle scène est une nouvelle run, avec un accumulateur à zéro.
- **L'écran de fin affiche le crédit.** La carte de mort ou de victoire montre `+N encre` et le nouveau solde. Le crédit est calculé avant l'affichage, jamais dans le callback d'affichage.
- **Sauvegarde immédiate.** Le crédit écrit le fichier une fois, avant que l'écran de fin ne soit interactif. Si l'écriture échoue, le crédit reste en mémoire pour la session, un avertissement discret est journalisé, et le jeu ne bloque pas (ADR-0007 §Failure modes).

### 3.4 Les quatre déblocages durables

| Ordre | `id` stable | Nom (fr, clé `meta.unlock.<id>.name`) | Coût | Effet débloqué | Prérequis | Capacité requise dans le build |
|---|---|---|---|---|---|---|
| 1 | `fourth_slot` | Quatrième emplacement | 80 | `Inventory` peut porter 4 armes | — | HUD capable d'afficher 4 lignes d'arme |
| 2 | `second_class` | La Chasseresse | 200 | la classe `chasseresse` devient sélectionnable au départ | `fourth_slot` si disponible | `ClassData` `chasseresse` chargeable |
| 3 | `arena_variant` | Variante d'arène | 400 | une seconde palette/décoration d'arène | `second_class` si disponible | ressource d'art de la variante |
| 4 | `difficulty_tiers` | Paliers de difficulté | 500 | les paliers `veillee` et `marge` deviennent sélectionnables | `arena_variant` si disponible | lignes de difficulté dans `MetaConfig` |

**Coûts et cumul.** Les coûts sont **unitaires** ; le cumul indicatif pour tout acheter est 80, puis 280, puis 680, puis 1 180 d'encre (F4). Les coûts sont des données (`UnlockData.cost`), pas des constantes.

**Règle de prérequis, y compris en cas de capacité absente.** Un déblocage ne peut être acheté que si tous les déblocages **disponibles** qui le précèdent sont achetés. Un déblocage dont la capacité requise manque dans le build (HUD à 3 lignes, classe absente, art absent) est affiché `indisponible` et **ne bloque pas** les suivants : il est ignoré dans la chaîne de prérequis tant qu'il est indisponible. Cette règle évite un blocage de la méta quand une dépendance de contenu arrive après W7 (le quatrième emplacement, notamment, attend le HUD à N lignes). Une fois la capacité livrée, il redevient achetable à son coût propre.

**Détail de chaque déblocage.**

1. **`fourth_slot` — quatrième emplacement.** `Inventory.MAX_WEAPONS` passe de 3 à 4 pour les runs suivantes. Le HUD actuel a exactement trois libellés (`Weapon0Label`…`Weapon2Label`) : tant qu'il n'en affiche pas quatre, l'achat est indisponible. Si le fichier dit « acheté » mais que le build ne sait afficher que trois lignes, la run démarre à **trois** emplacements, sans erreur ; le déblocage reste acquis pour un build ultérieur. Ce déblocage élargit l'espace de build, il n'ajoute aucune statistique. **Tension documentée** : `weapons.md` F13 est écrite pour trois emplacements (`W_weapon = 4,2` quand `w_weapon = w_upgrade = 1,4`) ; le passage à quatre change la part d'arme du panneau. Deux options sont ouvertes à l'équipe armes (voir Dependencies) : renormaliser les poids à `4,2 / MAX_WEAPONS` pour conserver la part, ou accepter une part d'arme plus élevée et re-tuner F13. Ce GDD ne tranche pas à la place du propriétaire de `weapons.md`.
2. **`second_class` — la Chasseresse.** L'identifiant `chasseresse` est celui de `classes.md` §1 ; aucune classe n'est inventée. L'effet est une **présélection** dans l'écran de choix de classe existant (W3-E4) : le joueur voit et peut choisir la Chasseresse, il n'est jamais forcé. Tant que `data/classes/chasseresse.tres` n'existe pas ou est invalide, le déblocage est indisponible. **Tension documentée** : `classes.md` §6.7 écrit « la classe n'est pas un déblocage payant ». La décision de ce GDD (issue du plan validé) est que la **puissance** de classe n'est jamais achetée — les trois classes restent à produit de multiplicateurs proche de 1,00 — mais que l'**accès** à la deuxième classe est un déblocage de contenu. La phrase de `classes.md` doit être amendée par son propriétaire ; ce GDD ne modifie pas ce document. Recommandation de libellé : « la classe n'est pas une puissance achetée ; son accès peut être un déblocage de contenu ».
3. **`arena_variant` — variante d'arène.** Deuxième **peau** de la même arène : palette, décor et grain de page différents, **empreinte au sol, obstacles, rayons, points d'apparition et durée des vagues identiques**. Aucun avantage mécanique, aucune nouvelle arène, aucun second biome — l'anti-pilier « PAS de nouvelle arène ou biome au lancement » est respecté. Si l'art de la variante manque, le sélecteur retombe sur l'arène par défaut.
4. **`difficulty_tiers` — paliers de difficulté.** Ajoute deux paliers au palier par défaut. La difficulté ne change **ni l'XP, ni les offres, ni la composition des vagues, ni la durée** : elle change les PV et les dégâts des ennemis, et le multiplicateur d'encre (F6). Le palier par défaut `conte` reste toujours disponible. Les libellés (`Conte`, `Veillée`, `Marge`) sont des noms de travail ; les clés `meta.difficulty.<id>.name` sont arbitrées par `narrative-director` et `localization-lead`, jamais en dur.

### 3.5 L'écran d'accueil

L'écran d'accueil est la **scène de démarrage** du jeu. Il doit rester utilisable avec un fichier absent, corrompu ou d'une version inconnue.

**Contenu obligatoire.**

| Zone | Contenu | État minimal (fichier vierge) |
|---|---|---|
| En-tête | Titre du jeu, solde d'encre (`meta.ink.balance`), cumul à vie (`meta.ink.lifetime`) | `0` et `0` |
| Déblocages | Quatre cartes ordonnées : nom, description, coût, état (acheté / achetable / trop cher / prérequis / indisponible) | `fourth_slot` achetable à 80, les autres verrouillées par le prérequis ou indisponibles |
| Sélecteurs | Classe (si ≥ 2 classes valides), arène (si variante achetée), difficulté (si paliers achetés) | Aucun sélecteur visible ; Chevalier, arène par défaut, `conte` |
| Action | Bouton « Jouer » (`meta.play`) | **Toujours actif**, même à 0 encre, même sans fichier |
| Statut | Bandeau discret de sauvegarde (`meta.save.unavailable`) | Masqué si aucune erreur |

**Règles d'interaction.**

- « Jouer » lance le flux de départ : écran de choix de classe (W3-E4) si plusieurs classes sont valides, sinon la run directement. La run utilise la classe, l'arène et la difficulté persistées.
- Un achat n'est possible que si `état = achetable` (capacité disponible, prérequis satisfaits, `encre ≥ coût`). Un clic sur une carte non achetable ne fait rien et affiche la raison au survol/focus ; il ne débite jamais.
- Un achat réussi débite le solde **une fois**, ajoute l'identifiant à `purchased`, sauvegarde immédiatement et rafraîchit les quatre cartes. Aucun remboursement, aucune confirmation supplémentaire : le coût est affiché avant le clic.
- Si la sauvegarde échoue après l'achat, l'achat reste valide **pour la session**, le bandeau `meta.save.unavailable` apparaît, et aucune erreur bloquante n'est affichée. Le joueur peut continuer à jouer ; l'achat sera perdu au prochain lancement, ce qui est le comportement documenté (pas de fausse promesse de persistance).
- L'écran ne contient **aucune** chaîne en dur : toutes passent par `data/localization/strings.csv`, avec le français comme repli.
- L'écran est lisible à 1280×720, navigable au clavier seul, et ne repose jamais sur la couleur seule pour distinguer les états (cadre, libellé, focus).

**Retour depuis une run.** La carte de fin affiche `+N encre` et le nouveau solde. `R` relance directement une run avec la même configuration (boucle courte existante) ; `Échap` revient à l'accueil. Une run relancée par `R` ne repasse pas par l'accueil, mais la classe est re-confirmée par l'écran de choix si plusieurs classes sont valides. Aucun achat n'est possible depuis la carte de fin.

### 3.6 Sélection de départ : classe, arène, difficulté

- La **classe** est choisie avant la vague 1 par l'écran W3-E4, qui reste inchangé dans ses entrées et sa lisibilité ; la méta ajoute seulement les classes débloquées au cercle de sélection et mémorise la dernière confirmation. `chevalier` est toujours valide et toujours le repli.
- L'**arène** et la **difficulté** sont choisies sur l'accueil, parmi les options achetées. Le défaut est `default` et `conte`.
- Au chargement et avant chaque run, la sélection est **validée** : classe existe et est débloquée, arène existe et est débloquée, difficulté existe (`conte` toujours). Une sélection invalide retombe sur le défaut et journalise un avertissement ; elle ne bloque jamais le démarrage.
- La sélection est écrite à chaque confirmation, pas à chaque frame. Écrire une sélection est une écriture de profil, donc une sauvegarde immédiate.

### 3.7 Ce que la méta ne fait pas

- **Pas de puissance permanente.** Aucun achat ne touche `damage_mult`, les PV, la vitesse, la cadence, le critique ou une statistique de classe.
- **Pas d'arbre de talents, pas de monnaie multiples, pas de monnaie premium.** Une seule monnaie persistante : l'encre.
- **Pas de conversion encre ↔ XP, encre ↔ or/trophées, encre ↔ équipement.** Les économies restent étanches.
- **Pas de récompense quotidienne, pas de saison, pas de boutique en ligne, pas de publicité.** Le jeu est hors ligne et solo.
- **Pas de farm de la vague 1.** Le crédit partiel à la mort récompense la progression réelle, pas la répétition d'un échec précoce (F5 et §5 E18 le chiffrent).
- **Pas de deuxième arène mécanique.** La variante change la peau, jamais l'empreinte.
- **Pas de blocage par la sauvegarde.** Un fichier absent, tronqué, corrompu ou d'une version future ne doit jamais empêcher « Jouer » (ADR-0007).

### 3.8 Périmètre de W7-E1

| Inclus dans ce document | Différé à W7-E2 ou hors périmètre |
|---|---|
| Modèle d'encre, valeurs par ennemi, formule de crédit | Accumulateur `_run_ink`, garde `_run_settled`, appel depuis `main.gd` |
| Coûts, ordre et effets des quatre déblocages | Fabrique des cartes, débit, écriture, signals |
| Schéma du fichier et politique de migration (ADR-0007) | `ProfileData`, `MetaStore`, autoload `MetaSave`, sauvegarde atomique |
| Contenu et états de l'écran d'accueil | Scène, focus clavier, captures, clés de localisation |
| Règles de sélection et de repli | Application de la classe/arène/difficulté à `main.gd` |
| Critères d'acceptation et cas limites | Tests unitaires et d'intégration correspondants |

**Hors périmètre explicite** : reprise d'une run en cours, plusieurs profils, synchronisation cloud, records en ligne, statistiques détaillées, nouvelle arène mécanique, troisième classe payante, monnaie premium, modificateurs de difficulté personnalisés.

## Formulas

### F1 — Encre par archétype

**Expression**

```text
ink_value(e) = champ EnemyData.ink_value de l'archétype e
valeur par défaut si le champ est absent : 1
valeur négative lue : 0 (jamais de crédit négatif)
```

| `id` | Rôle | `xp_value` | `ink_value` | Justification |
|---|---|---|---|---|
| `squelette` | marcheur de base | 1 | 1 | unité de référence de l'économie. |
| `loup_maudit` | chargeur fragile | 1 | 1 | même encre que le squelette : mourir vite ne paie pas plus. |
| `plume` | tireur | 1 | 2 | tuer la menace à distance est une décision, pas une esquive gratuite ; l'écart avec l'XP est volontaire. |
| `orc` | marcheur lourd | 2 | 2 | suit son XP : il coûte du temps, il rend proportionnellement. |
| `tache` | exploseur | 3 | 3 | idem. |
| `copiste` | invocateur | 5 | 5 | la priorité la plus chère du roster ; tuer le Copiste doit payer. |
| `seigneur_squelette` | boss (élite) | 30 | 25 | valeur fixe et prévisible ; deux occurrences par run, soit 50 sur une victoire. |

**Règles d'auteur.**

- Un sbire vaut **1 à 5**, un boss **20 à 30**, jamais plus de 30. La valeur est une donnée de l'ennemi, jamais une constante de script ni une dérivée de `xp_value` calculée à l'exécution.
- `0` est autorisé et signifie « ne rapporte rien » (invocation, ennemi décoratif). `1` est le plancher implicite d'un ennemi normal.
- **Invariant de roster.** Avec le roster complet de `enemy-behaviors.md` §2 et le modèle F5 (κ = 0,60), une victoire de référence doit rapporter **entre 250 et 320 d'encre**. Un nouvel archétype qui pousse la victoire au-dessus de 320 oblige à re-tuner les coûts (F4) dans le même changement ; il ne se contente pas d'augmenter le robinet.

**Exemple.** Une vague 1 tuée à 100 % (≈14 squelettes) vaut 14 d'encre de base ; un Seigneur vaut 25, soit presque deux vagues 1–2 entières.

### F2 — Encre accumulée pendant la run

**Expression**

```text
encre_de_run = Σ(k = 1..K) ink_value(e_k)
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `K` | int | 0–450 | Nombre d'ennemis tués pendant la run, invocations exclues. |
| `e_k` | `EnemyData` | roster | Archétype du k-ième ennemi tué. |
| `encre_de_run` | int | 0–441 | Accumulateur de run ; remis à zéro à chaque nouvelle scène. |

**Plage de sortie.** 0 (mort avant la première mort d'ennemi), environ 285 pour une victoire de référence (F5), 441 pour la borne théorique « tous les spawns et les deux boss tués » (391 d'encre de sbires + 50 de boss). La borne réelle est plus basse : `max_alive` refuse des spawns et le joueur ne tue pas tout.

**Exemple.** 40 squelettes, 12 loups, 9 Plumes, 4 orcs, 2 Taches et 1 Seigneur : `40×1 + 12×1 + 9×2 + 4×2 + 2×3 + 1×25 = 109`.

### F3 — Crédit de fin de run

**Expression**

```text
encre_créditée = floor( encre_de_run × r × m_d )
r = 1,00 si résultat = victoire
r = 0,70 si résultat = défaite
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `r` | float | 0,70–1,00 | Taux de résultat ; toute autre valeur que victoire/défaite donne 0 et un avertissement. |
| `m_d` | float | 1,00–1,35 | Multiplicateur d'encre du palier de difficulté (F6). |
| `encre_créditée` | int | 0–595 | Montant ajouté au solde et au cumul à vie. |

**Ordre des opérations.** Un **seul** arrondi, à la fin : `floor(base × r × m_d)`. On ne plancher pas `r × m_d` séparément, et on ne plancher pas après le taux de résultat avant d'appliquer la difficulté.

| `encre_de_run` | Résultat | Difficulté | Calcul | Crédit |
|---|---|---|---|---|
| 0 | défaite | `conte` | `floor(0 × 0,70 × 1,00)` | 0 |
| 7 | défaite | `conte` | `floor(7 × 0,70)` | 4 |
| 29 | défaite | `conte` | `floor(29 × 0,70)` | 20 |
| 112 | défaite | `conte` | `floor(112 × 0,70)` | 78 |
| 112 | défaite | `veillee` (1,15) | `floor(112 × 0,70 × 1,15)` | 90 |
| 112 | défaite | `marge` (1,35) | `floor(112 × 0,70 × 1,35)` | 105 |
| 228 | défaite | `conte` | `floor(228 × 0,70)` | 159 |
| 285 | victoire | `conte` | `floor(285 × 1,00)` | 285 |
| 285 | victoire | `veillee` | `floor(285 × 1,15)` | 327 |
| 285 | victoire | `marge` | `floor(285 × 1,35)` | 384 |

**Garantie anti-farm de défaite.** Pour tout palier, `m_d × 0,70 < 1,00` (0,805 pour `veillee`, 0,945 pour `marge`) : une défaite au palier le plus dur crédite toujours **moins** que la même run gagnée au palier par défaut. Voir F6.

### F4 — Coûts de déblocage et cumul

**Expression**

```text
achetable(i) = non acheté(i)
             ∧ capacité_disponible(i)
             ∧ tous les prérequis disponibles sont achetés
             ∧ encre ≥ coût(i)
encre' = encre - coût(i)          après achat
C_k = Σ(i = 1..k) coût(i)          cumul indicatif
```

| Ordre `i` | `id` | `coût(i)` | `C_i` | Part du total |
|---|---|---|---|---|
| 1 | `fourth_slot` | 80 | 80 | 6,8 % |
| 2 | `second_class` | 200 | 280 | 23,7 % |
| 3 | `arena_variant` | 400 | 680 | 57,6 % |
| 4 | `difficulty_tiers` | 500 | 1 180 | 100 % |

**Horizon de déblocage** (modèle F5, départs à 0, aucun achat) :

| Après | Encre disponible | Achat(s) possible(s) | Reste |
|---|---|---|---|
| 1 défaite vague 6 (78) | 78 | aucun (il manque 2) | 78 |
| 1 victoire `conte` (285) | 285 | `fourth_slot` (80) puis `second_class` (200) | 5 |
| 2 victoires (290) | 290 | aucun nouveau (il manque 110 pour 400) | 290 |
| 3 victoires (575) | 575 | `arena_variant` (400) | 175 |
| 4 victoires (460) | 460 | aucun nouveau (il manque 40 pour 500) | 460 |
| 5 victoires (745) | 745 | `difficulty_tiers` (500) | 245 |

Le cumul complet de 1 180 est atteint en **5 victoires** sans défaite, ou plus tôt si des défaites s'y ajoutent ; une session de 3 à 5 runs voit les deux premiers déblocages.

### F5 — Rendement de référence par run

**Expression**

```text
E[encre_de_run] = κ × Σ(w = 1..10) [ A_w × Σ(e) s_(w,e) × ink_value(e) ] + 25 × n_boss_tués
A_w = 20 / I_w
```

| Symbole | Type | Plage | Description |
|---|---|---|---|
| `A_w` | float | 14,3–39,8 | Tentatives de spawn de la vague `w` (`I_w` = intervalle de `enemy-behaviors.md` §9). |
| `s_(w,e)` | float | 0–1 | Part de l'archétype `e` à la vague `w` (table §9 de `enemy-behaviors.md`). |
| `κ` | float | 0,40–0,80 | Taux de conversion « tentatives de spawn → ennemis tués ». **Hypothèse de modèle : 0,60**, à recalibrer par télémétrie/playtest. |
| `n_boss_tués` | int | 0–2 | Un boss tué rapporte 25, jamais deux fois la même instance. |

`κ = 0,60` est une **hypothèse déclarée**, pas une mesure : `max_alive` refuse une partie des tentatives et le joueur n'atteint pas 100 % de kills. Le modèle sert à dimensionner les coûts, pas à promettre un chiffre.

**Encre de base par vague, à 100 % de kills** (avant κ, hors boss) :

| Vague | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | Total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Encre de sbires | 14,3 | 16,2 | 18,5 | 26,8 | 24,8 | 45,1 | 51,3 | 65,9 | 74,9 | 53,2 | 391,1 |
| Boss | — | — | — | — | 25 | — | — | — | — | 25 | 50 |

**Scénarios de crédit** (base arrondie, formules F3) :

| Issue | Base modèle | `conte` | `veillee` | `marge` |
|---|---|---|---|---|
| Mort vague 3 | 29 | 20 | 23 | 27 |
| Mort vague 4 | 45 | 31 | 36 | 42 |
| Mort vague 6, boss 1 tué | 112 | 78 | 90 | 105 |
| Mort vague 9, boss 1 tué | 228 | 159 | 183 | 215 |
| Victoire | 285 | 285 | 327 | 384 |

**Lecture anti-dégénérescence.** Un farm « vague 1 puis mort » vaut `floor(14,3 × 0,60 × 0,70) = 6` d'encre pour environ 25 s de mur d'horloge (20 s de vague + accueil/chargement), soit **0,24 encre/s**. Une victoire `conte` vaut 285 pour environ 220 s, soit **1,29 encre/s** : une run complète est environ **5,4 fois** plus rentable par seconde qu'un suicide précoce. Le crédit partiel A3 aide le joueur qui échoue, il ne récompense pas l'échec répété.

### F6 — Paliers de difficulté et invariants

| `id` | Libellé de travail | PV ennemis | Dégâts ennemis | Encre `m_d` | Disponibilité |
|---|---|---|---|---|---|
| `conte` | Conte | ×1,00 | ×1,00 | ×1,00 | toujours |
| `veillee` | Veillée | ×1,15 | ×1,10 | ×1,15 | après `difficulty_tiers` |
| `marge` | Marge | ×1,30 | ×1,20 | ×1,35 | après `difficulty_tiers` |

**Application.** Les multiplicateurs de PV et de dégâts s'appliquent à **tous** les ennemis, boss compris, en plus des paliers de boss existants :

```text
PV_boss   = PV_base × (1 + boss_hp_per_tier × palier_boss) × hp_d
dégâts    = dégâts_base × (1 + boss_damage_per_tier × palier_boss) × damage_d
```

**Ce que la difficulté ne change pas** : XP, poids et composition des vagues, nombre de vagues, durée, offres, rerolls, butin, `ink_value` par ennemi. Seuls les PV, les dégâts et le multiplicateur de crédit changent.

**Invariants de tuning.**

1. `m_d ≤ hp_d × damage_d` : le bonus d'encre ne dépasse jamais l'augmentation combinée de difficulté (1,15 ≤ 1,265 ; 1,35 ≤ 1,56).
2. `m_d × 0,70 < 1,00` : une défaite au palier le plus dur crédite moins que la même run gagnée en `conte` (0,945 < 1,00).
3. `m_d / (hp_d × damage_d) ≤ 1` : aucun palier n'est une ferme plus rapide par unité de risque.
4. Les paliers sont des **données** (`MetaConfig.difficulties`), jamais des branches de script.

### F7 — Plafonds et bornes

| Grandeur | Borne | Justification |
|---|---|---|
| `encre_de_run` | 441 théorique | La run est finie (10 vagues, deux boss) ; le robinet est borné par le calendrier, pas par un plafond arbitraire. |
| `ink_run_cap` | 0 (désactivé), plage sûre 300–600 | Réservé à un futur mode sans fin ; à 0, aucun plafond n'est appliqué. |
| Solde `ink` | 0 … `int64` | Pas de plafond ; une valeur négative lue est ramenée à 0. |
| Cumul `lifetime` | ≥ solde | Invariant de cohérence ; réparé au chargement (`max(lifetime, balance)`), jamais bloquant. |
| `coût(i)` | > 0 | Un coût nul ou négatif est un défaut de données ; l'achat est refusé et l'erreur journalisée. |
| `ink_value` | 0–30 | Au-delà de 30, un ennemi déforme l'économie ; le test de données échoue. |
| Victoire de référence | 250–320 | Invariant de roster (F1) ; hors bornes, les coûts doivent être re-tunés. |

## Edge Cases

Chaque cas a un résultat déterministe et doit devenir un test en W7-E2. Les cas E1–E5 et E17 sont des exigences de l'ADR-0007 ; les autres sont des règles de jeu.

| # | Cas | Résultat attendu |
|---|---|---|
| E1 | **Le fichier `user://meta.cfg` est absent (premier lancement).** | Profil par défaut : solde 0, cumul 0, aucun déblocage, `chevalier` / arène par défaut / `conte`. Aucun message d'erreur, aucun fichier créé avant la première écriture. « Jouer » est actif et lance une run complète à 3 emplacements. |
| E2 | **Le fichier est tronqué ou illisible.** | `ConfigFile.load` retourne une erreur : tentative de chargement de `meta.cfg.bak` ; si le backup est valide, il est utilisé et un avertissement est journalisé. Sinon, profil par défaut. Le fichier fautif est mis de côté au mieux (`meta.corrupt-<horodatage>.cfg`). **Jamais de crash, jamais de blocage de l'écran d'accueil.** |
| E3 | **Le fichier est syntaxiquement valide mais une clé a le mauvais type ou une valeur impossible.** | Chaque clé est lue séparément avec son type attendu et sa valeur par défaut. Une clé invalide est remplacée, journalisée, et n'empêche pas les autres clés d'être lues. Une encre négative est ramenée à 0 ; un `lifetime` inférieur au solde est réparé à `max(lifetime, balance)`. |
| E4 | **Le fichier vient d'une version plus récente (`version > CURRENT_VERSION`).** | Mode **lecture seule** : les clés connues sont chargées, les clés inconnues sont ignorées, **aucune écriture** n'est effectuée (un `save()` est refusé et journalisé). Un bandeau discret signale « sauvegarde d'une version plus récente ». Le jeu reste jouable ; le fichier n'est jamais écrasé par un build plus ancien. |
| E5 | **Le fichier vient d'une version antérieure (`version < CURRENT_VERSION`).** | Migrations appliquées dans l'ordre (v0 → v1 → …) sur un dictionnaire, puis validation et écriture dans la version courante. Si une migration échoue, le fichier est mis de côté, le profil par défaut est utilisé, un avertissement est journalisé : le joueur perd sa méta mais peut jouer. |
| E6 | **Le joueur quitte la run avant un état terminal** (fermeture, `Échap`, `R`, rechargement). | Aucun crédit. L'accumulateur de run est détruit avec la scène ; la run suivante repart de 0. Ce n'est pas une perte de solde : rien n'avait été crédité. |
| E7 | **Le joueur meurt sur la même frame que le boss final.** | La **défaite gagne**, conformément à `classes.md` §4.5 : la carte affichée est celle de la mort, le crédit est calculé à 70 %, et le panneau de butin ne s'empile pas. Un seul crédit. |
| E8 | **Le crédit de fin de run est appelé deux fois** (signal dupliqué, bug d'ordre). | La garde `_run_settled` de `main.gd` fait du second appel un no-op. Le solde n'augmente qu'une fois ; un test d'intégration appelle la fin deux fois et vérifie le solde. |
| E9 | **Le même boss est tué « deux fois ».** | `Enemy.take_damage` ignore un ennemi déjà mort : une seule mort, un seul crédit. Le boss de la vague 10 est une **nouvelle instance** : elle compte séparément, comme prévu (50 d'encre pour les deux rencontres). |
| E10 | **Un ennemi invoqué est tué.** | 0 encre : il ne donne pas d'XP, il ne donne pas d'encre. La porte de récompense est la même que celle de l'XP. |
| E11 | **Un ennemi est retiré, expiré ou sort de l'arène sans mourir.** | 0 encre. Seule la mort d'un ennemi alimente l'accumulateur. |
| E12 | **Un achat réussit mais la sauvegarde échoue** (disque plein, dossier en lecture seule). | L'achat reste valide **pour la session** ; le solde est débité en mémoire ; le bandeau `meta.save.unavailable` apparaît ; aucune erreur bloquante. Au relancement, l'achat est perdu — comportement documenté, pas de fausse promesse. |
| E13 | **Le joueur achète avec exactement le solde disponible.** | L'achat réussit, le solde tombe à 0, jamais en négatif. Un achat à 1 d'encre de moins est refusé. |
| E14 | **Un achat est tenté sans prérequis ou sans capacité.** | Refusé sans débit, avec la raison affichée (prérequis manquant, capacité indisponible, solde insuffisant). Aucun achat partiel, aucun remboursement. |
| E15 | **Le fichier dit `fourth_slot` acheté mais le HUD ne sait afficher que 3 lignes.** | La run démarre à **3** emplacements, sans erreur ; le déblocage reste acquis et redeviendra effectif dans un build qui affiche 4 lignes. Aucun débit rétroactif, aucun blocage. |
| E16 | **La sélection persistée est invalide** (classe inconnue, arène non débloquée, difficulté inconnue). | Repli sur le défaut (`chevalier`, arène par défaut, `conte`) et avertissement. La run démarre ; l'écran d'accueil affiche la sélection effective, pas la valeur invalide. |
| E17 | **Une valeur d'encre absurde est lue dans le fichier** (négative, énorme). | Négative → 0. Énorme → conservée (pas de plafond de solde), mais `int64` et validation de type empêchent un débordement silencieux ; une valeur non entière est refusée et remplacée par le défaut. |
| E18 | **Un joueur farme « vague 1 puis mort ».** | Ce n'est pas un exploit rentable : 6 d'encre pour ~25 s, soit 0,24 encre/s, contre 1,29 encre/s pour une victoire (F5). Aucun plafond n'est nécessaire ; `ink_run_cap` reste à 0. |
| E19 | **Un joueur choisit `marge` et meurt en vague 9.** | 215 d'encre, soit **moins** qu'une victoire `conte` (285) : l'invariant `m_d × 0,70 < 1` est vérifié. Choisir la difficulté la plus dure ne remplace pas une victoire. |
| E20 | **Un déblocage indisponible précède un déblocage disponible.** | Le prérequis indisponible est ignoré dans la chaîne : le déblocage suivant est achetable. Aucun softlock de la méta quand le HUD ou le contenu arrive après W7. |
| E21 | **Deux instances du jeu sont ouvertes.** | Dernière écriture gagnante, aucune prise de verrou, aucune corruption : chaque instance charge au démarrage et écrit son profil complet. Limitation assumée d'un jeu solo local ; documentée dans l'ADR-0007. |
| E22 | **Le fichier contient un `id` de déblocage inconnu** (venu d'un build futur ou d'une édition manuelle). | Effet ignoré. Sur une sauvegarde de même version, l'identifiant inconnu est **préservé** lors de l'écriture ; sur une version future, le mode lecture seule s'applique (E4). Aucune suppression silencieuse. |
| E23 | **Le joueur termine une run sans tuer un seul ennemi.** | Crédit 0, affichage « +0 encre », aucune erreur, aucune valeur négative. |
| E24 | **La sauvegarde est rechargée après un règlement, puis `R` relance.** | La nouvelle scène est une nouvelle run : accumulateur à 0, aucune re-créditation de la run précédente. La garde de règlement ne survit pas à la scène, et n'a pas à le faire. |

## Dependencies

| Système | Sens | Ce que ce document attend | Propriétaire |
|---|---|---|---|
| `src/data/enemy_data.gd` | fournit | Champ `ink_value: int = 1`, documenté, inclus dans les données de chaque archétype. Aucune constante globale d'encre. | W7-E2, avec le test de données W2-E4/W1-E5 |
| `data/enemies/*.tres` | fournit | Valeurs de F1 sur les quatre archétypes existants ; les trois archétypes cibles de `enemy-behaviors.md` reçoivent la leur à leur livraison. | W1-E5, W7-E2 |
| `design/gdd/enemy-behaviors.md` | croisé | Roster §2, parts et calendrier §9, boss élite, invocations sans XP §8. Ce GDD ne modifie pas ce document ; son propriétaire doit citer `meta-progression.md` pour `ink_value` et la porte de récompense des invocations. | W1-E0 (`game-designer`) |
| `design/gdd/weapons.md` | croisé | État actuel : 3 emplacements, F13 invariante pour 3. Le quatrième emplacement change `n_new + n_up` et donc `W_weapon`. **Décision ouverte** : renormaliser `weapon_offer_weight` / `weapon_upgrade_weight` à `4,2 / MAX_WEAPONS` pour conserver la part, ou re-tuner F13 et §3.8. Ce GDD ne tranche pas à la place du propriétaire. | systems-designer (W2-E1) |
| `design/gdd/classes.md` | croisé | `id` stable `chasseresse`, multiplicateurs de classe, écran W3-E4, règle de mort simultanée §4.5. **Décision ouverte** : §6.7 dit « la classe n'est pas un déblocage payant », alors que le plan validé fait de l'accès à la Chasseresse un déblocage à 200 d'encre. Recommandation : amender la phrase en « la classe n'est pas une **puissance** achetée ; son **accès** peut être un déblocage de contenu », sans toucher aux multiplicateurs. À arbitrer par `creative-director` / propriétaire de `classes.md`. | W3-E1 (`game-designer`) |
| `design/gdd/run-economy.md` | croisé | Étanchéité : l'encre n'entre jamais dans la boutique de run, l'or/trophée n'entre jamais dans la méta. Le GDD économie doit nommer cette frontière ; il est encore `Not Started`. | W4-E1 (`economy-designer`) |
| `design/gdd/systems-index.md` | croisé | Ligne 12 déjà réservée à ce document. **Un autre agent l'édite** ; ce GDD ne le modifie pas. | Orchestrateur / `game-designer` |
| `src/main.gd` | consomme | Accumulateur `_run_ink`, garde `_run_settled`, appel unique de `MetaSave.credit_run(...)` avant l'écran de fin ; application de la classe, de l'arène et de la difficulté au démarrage ; repli si une ressource manque. | W7-E2 (`lead-programmer`) |
| `src/ui/hud.gd`, `scenes/main.tscn` | consomme | Ligne « +N encre » et nouveau solde sur les cartes de mort/victoire ; `Échap` vers l'accueil ; capacité d'afficher **N lignes d'arme** (3 aujourd'hui, 4 pour `fourth_slot`). | W7-E2, `ui-programmer` |
| `src/classes/inventory.gd` | consomme | `MAX_WEAPONS` effectif = 3 + (`fourth_slot` acheté et HUD capable ? 1 : 0). Aucune autre règle d'inventaire ne change. | W7-E2 |
| `data/meta/meta_config.tres`, `data/meta/unlocks/*.tres` | fournit | `MetaConfig` : taux victoire/défaite, table des difficultés, ordre des déblocages. `UnlockData` : `id`, `name_key`, `description_key`, `cost`, `requires`, `capability`. Tous les nombres de ce GDD vivent ici, jamais dans un script. | W7-E1 (ce document), W7-E2 (création) |
| `project.godot` | consomme | Enregistrement de l'autoload `MetaSave` et bascule de la scène de démarrage vers l'accueil. Fichier partagé : séquencement par `production/plans/drastic-upgrade-plan.md` §File collisions. | W7-E2 |
| `docs/localization-standard.md` | fournit | Convention de clés `<zone>.<sujet>.<détail>`, CSV, repli français, extraction. Toute chaîne de l'accueil, des cartes et des cartes de fin passe par là. | W8-E1 (`localization-lead`) |
| `docs/architecture/ADR-0007-save-format.md` | fournit | Format `.cfg`, schéma, version/migration, modes de défaillance, sauvegarde atomique, API de test. Même changeset que ce GDD. | `game-designer` → `lead-programmer` |
| `design/art/art-bible.md` | croisé | Cadre de l'écran d'accueil et **peau** de la variante d'arène, dans la même famille d'encre. Ce GDD ne fixe aucune direction artistique. | `art-director` |
| `production/plans/drastic-upgrade-plan.md` | croisé | W7-E1 (ce document) précède W7-E2 (implémentation) ; `main.gd`, `hud.gd`, `project.godot` et `systems-index.md` sont des fichiers à collision, séquencés. | `producer` |

**Réciprocité.** Les documents croisés ne sont pas modifiés par ce GDD. Leurs propriétaires doivent : citer `meta-progression.md` dans `enemy-behaviors.md` (encre et invocations), `run-economy.md` (étanchéité), `classes.md` (accès à la Chasseresse et option de départ), `weapons.md` (quatrième emplacement et F13), et `systems-index.md` (ligne 12). Les deux tensions nommées ci-dessus sont des **décisions ouvertes** signalées à l'utilisateur ; elles ne sont pas tranchées unilatéralement par ce document.

**Décisions ouvertes signalées.**

1. **Quatrième emplacement contre F13 de `weapons.md`.** La part d'arme du panneau est calibrée pour trois emplacements. À quatre, `W_weapon` passe de 4,2 à 5,6 si les poids restent à 1,4, ce qui augmente la part d'arme. Option A (recommandée) : poids = `4,2 / MAX_WEAPONS`, part constante. Option B : accepter la hausse et re-tuner F13. Décision au propriétaire de `weapons.md`.
2. **Libellé de `classes.md` §6.7.** La phrase « la classe n'est pas un déblocage payant » contredit le plan validé. La recommandation de ce GDD est de distinguer **accès** (déblocage de contenu) et **puissance** (jamais achetée). Décision au `creative-director` et au propriétaire de `classes.md`.

## Tuning Knobs

Chaque knob est classé **feel** (ressenti immédiat), **curve** (forme de la progression économique) ou **gate** (débloque ou verrouille une possibilité). Toute valeur vit dans `data/meta/*.tres`, `data/enemies/*.tres` ou `MetaConfig`, jamais dans un script.

| Paramètre | Valeur par défaut | Plage sûre | Catégorie | Effet hors plage / justification |
|---|---|---|---|---|
| `EnemyData.ink_value` (sbire) | 1–5 (table F1) | 0–5 | curve | Au-delà de 5, un sbire pèse comme un boss et le calendrier ne contrôle plus le robinet. |
| `EnemyData.ink_value` (boss) | 25 | 20–30 | curve | Sous 20, tuer le boss ne se sent pas ; au-delà de 30, la victoire devient un chèque qui masque les sbires. |
| `EnemyData.ink_value` (défaut absent) | 1 | fixe | gate | Un archétype sans champ explicite vaut 1 ; le test de données exige néanmoins la valeur explicite sur chaque `.tres` livré. |
| `MetaConfig.victory_rate` | 1,00 | 0,90–1,10 | curve | Sous 0,90, gagner n'est plus le meilleur résultat ; au-delà de 1,10, l'encre s'inflationne sans nouvelle décision. |
| `MetaConfig.defeat_rate` | 0,70 | 0,50–0,74 | curve | Sous 0,50, mourir en vague 2 ne marque plus la page (raison d'A3) ; au-delà de 0,74, l'invariant `m_marge × r < 1` casse et la défaite au plus dur peut battre une victoire normale. |
| `UnlockData.cost` — `fourth_slot` | 80 | 60–100 | curve | À 60, le premier déblocage tombe avant la première défaite ; à 100, il faut deux à trois runs pour le voir. |
| `UnlockData.cost` — `second_class` | 200 | 150–250 | curve | Doit rester atteignable avec une victoire + une défaite vague 4. |
| `UnlockData.cost` — `arena_variant` | 400 | 300–500 | curve | À 300, l'arène arrive avant que la Chasseresse soit jouée ; à 500, elle glisse après les paliers. |
| `UnlockData.cost` — `difficulty_tiers` | 500 | 375–625 | curve | Le dernier palier doit demander plusieurs victoires, pas une seule. |
| `difficulty.veillee.hp_mult` | 1,15 | 1,05–1,25 | curve | Au-delà de 1,25, la vague 5 devient un mur pour un build non abouti. |
| `difficulty.veillee.damage_mult` | 1,10 | 1,00–1,20 | curve | Doit rester sous le gain d'encre par l'invariant F6. |
| `difficulty.veillee.ink_mult` | 1,15 | 1,00–1,25 | curve | Au-delà de 1,25, il dépasse `hp × damage` et devient une ferme. |
| `difficulty.marge.hp_mult` | 1,30 | 1,15–1,40 | curve | Au-delà de 1,40, la run n'est plus lisible sans build parfait. |
| `difficulty.marge.damage_mult` | 1,20 | 1,05–1,30 | curve | Un contact à ×1,30 tue un Chevalier en moins de quatre contacts ; à vérifier en playtest. |
| `difficulty.marge.ink_mult` | 1,35 | 1,00–1,40 | curve | Plafonné par `m × 0,70 < 1` (1,35 × 0,70 = 0,945). |
| `ink_run_cap` | 0 (désactivé) | 0, ou 300–600 si mode sans fin | gate | Aucun plafond nécessaire tant que la run dure 10 vagues ; à activer si un mode sans fin apparaît. |
| `MetaSave.CURRENT_VERSION` | 1 | fixe par version | gate | Toute incrémentation exige une migration testée (ADR-0007). |
| Capacité `hud_weapon_rows` | 3 (4 quand le HUD est livré) | 3–4 | gate | `fourth_slot` reste indisponible tant que la valeur est 3 ; un fichier acheté avec une capacité 3 ne casse pas la run. |
| `MetaConfig.default_class` | `chevalier` | fixe | gate | Toujours valide, toujours le repli de l'écran de sélection. |
| `MetaConfig.kill_conversion` (κ) | 0,60 | 0,40–0,80 | curve (modèle) | N'est **pas** un knob de jeu : c'est l'hypothèse du modèle F5, recalibrée par télémétrie/playtest, jamais lue par le code. |

**Règle de tuning.** Toute modification d'un `ink_value`, d'un coût, d'un taux ou d'un multiplicateur doit être vérifiée contre : (a) l'invariant de roster F1 (victoire 250–320) ; (b) l'invariant `m_d × 0,70 < 1` (F6) ; (c) le ratio anti-farm F5 (une run complète reste au moins 3× plus rentable par seconde qu'un suicide vague 1). Un réglage qui échoue à l'un des trois est refusé ou compensé dans le même changement.

## Acceptance Criteria

| # | Critère | Comment le vérifier |
|---|---|---|
| AC1 | Le profil fait un aller-retour fidèle : écrire puis relire `balance`, `lifetime`, `purchased`, `selection`, `records` et `version` rend des valeurs identiques. | Test unitaire `ProfileData`/`MetaStore` sur un chemin temporaire injecté ; aucun accès au vrai `user://meta.cfg`. |
| AC2 | Un fichier absent donne un profil par défaut et l'écran d'accueil s'ouvre avec « Jouer » actif ; une run complète peut être lancée, jouée et terminée. | Test d'intégration « nouveau joueur » avec un chemin vierge + capture de l'accueil à 0 encre. |
| AC3 | Un fichier tronqué ou corrompu ne crashe pas : le jeu démarre sur le backup s'il est valide, sinon sur les défauts, avec un avertissement et le fichier fautif mis de côté. | Test unitaire avec trois fixtures : tronquée, illisible, clé mal typée ; assertion « aucune exception, valeurs par défaut attendues ». |
| AC4 | La migration v0 → v1 fonctionne ; un fichier `version > CURRENT_VERSION` n'est **jamais** réécrit et reste jouable en lecture seule. | Deux tests : fichier sans `version` migré et sauvegardé en v1 ; fichier v2 chargé, `save()` refusé, contenu du fichier inchangé. |
| AC5 | Le crédit respecte exactement F3 : 285 victoire `conte` = 285 ; 285 défaite `conte` = 199 ; 112 défaite `conte` = 78 ; 112 défaite `marge` = 105 ; 0 = 0. | Test paramétré sur `credit_run` avec ces cinq lignes ; arrondi vérifié au plancher, une seule fois. |
| AC6 | Un seul crédit par run : un double appel de règlement ne crédite qu'une fois ; une mort et une victoire sur la même frame donnent une défaite à 70 %. | Test d'intégration sur `main.gd` : deux appels, solde inchangé au second ; scénario de mort simultanée. |
| AC7 | Quitter ou relancer avant un état terminal n'accrédite rien ; `R` après un règlement ne recrédite pas. | Test d'intégration : quitter en vague 3, solde inchangé ; recharger après règlement, solde inchangé. |
| AC8 | L'encre du boss compte une fois par instance (50 pour les deux rencontres) et les invocations valent 0. | Test unitaire de l'accumulateur : roster avec deux boss, une invocation, un ennemi retiré ; total attendu. |
| AC9 | L'achat est atomique : solde exact accepté, solde insuffisant refusé, prérequis et capacité vérifiés, débit une seule fois, persistance après rechargement. | Test unitaire `purchase()` sur les quatre états ; rechargement du store après achat. |
| AC10 | Un joueur avec un fichier vierge joue à **3** emplacements, Chevalier, arène par défaut, `conte`, sans aucune erreur ni écran bloquant. | Test d'intégration « blank file » + capture de la run vague 1. |
| AC11 | `fourth_slot` est indisponible tant que `hud_weapon_rows = 3` ; s'il est acheté dans le fichier mais que la capacité manque, la run démarre à 3 emplacements sans crash. | Test unitaire de disponibilité + test d'intégration de repli. |
| AC12 | Les paliers de difficulté appliquent les multiplicateurs de F6 aux PV/dégâts ennemis et au crédit, sans toucher à l'XP, aux vagues ni aux offres ; les quatre invariants F6 tiennent. | Test paramétré sur les trois paliers ; assertions sur les multiplicateurs et sur `m_d × 0,70 < 1`. |
| AC13 | Tous les nombres de la méta sont data-driven : aucun coût, taux, multiplicateur ou `ink_value` n'est une constante de script. | Scan des scripts (`grep` des littéraux 80/200/400/500/0,70/1,15/1,35) + lecture des `.tres`. |
| AC14 | Toutes les chaînes de l'accueil, des cartes et des cartes de fin ont une clé dans `strings.csv` avec repli français ; aucune clé brute à l'écran. | Test de localisation (clés présentes) + capture de l'accueil et d'une carte de fin. |
| AC15 | L'écran d'accueil affiche le solde, le cumul à vie, les quatre cartes avec coût et état, et « Jouer » ; il est navigable au clavier seul et lisible à 1280×720. | Capture retenue `production/qa/evidence/w7-e1-meta-home.png` + test clavier (focus visible, aucun état sans focus). |
| AC16 | La suite complète reste verte, sans suppression ni désactivation de test existant. | Commande de test du projet, exit 0 ; rapport de suite joint à la story W7-E2. |
