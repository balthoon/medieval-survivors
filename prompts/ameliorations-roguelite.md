# Prompt — Profondeur de jeu de Medieval Survivors

> À coller tel quel dans Claude Code, lancé depuis la racine du dépôt.
> Découpé en 4 lots : le lot 0 se livre seul, les suivants s'enchaînent.

---

## Contexte

Tu travailles sur **Medieval Survivors**, un survivors-like en Godot 4.7 / GDScript (dépôt `Claude-Code-Game-Studios`).

Lis d'abord, dans cet ordre, et applique-les sans exception :

1. `CLAUDE.md` — protocole collaboratif (**Question → Options → Decision → Draft → Approval**), no commit sans instruction
2. `src/CLAUDE.md` — standards de code, valeurs data-driven, tests dans `tests/`, doc comments obligatoires
3. `production/session-state/active.md` — l'état de la session précédente
4. `docs/engine-reference/` — **ne devine aucune API Godot**, vérifie avant d'écrire

Le code est sain : logique pure testable (`WaveDirector`, `Stats`, `Offer`), contenu en ressources `.tres`, et une suite gdUnit4 de référence **109 tests / 17 suites, exit 0** qui doit rester verte. Je ne veux **aucune régression**.

## Diagnostic de départ

Trois manques structurels, déjà audités :

1. **Les armes ne montent jamais en niveau.** `src/main.gd` → `_build_offers` exclut toute arme déjà possédée (`if _inventory.has_weapon(weapon): continue`), et `WeaponData` n'a aucun champ de niveau. Dès que les 3 slots sont remplis, chaque level-up ne propose plus que des multiplicateurs plats.
2. **Aucune sauvegarde.** Aucun `FileAccess` / `ConfigFile` / `user://` dans `src/`. À la mort, `main.gd` recharge la scène et tout est perdu : pas de méta-progression.
3. **Aucune évolution d'arme.** Un `orbit_blade` reste identique toute la run.

Deux défauts annexes :

4. **Offres mortes** : `Stats.weapon_crit_chance` plafonne à 0.75, mais `_build_offers` continue de proposer des upgrades de critique au-delà du cap.
5. **Équipements interchangeables** : ce sont des nombres par slot, sans identité ni synergie.

## Objectif

Faire passer la boucle de jeu de « multiplicateurs plats » à « construction de build ».

---

## Lot 0 — corrections (à livrer seul, en premier)

**0.1 — Offres mortes.**
Ajouter `Stats.is_capped(stat: String) -> bool` (aujourd'hui : `crit_chance` ≥ 0.75). Dans `_build_offers`, écarter toute offre d'upgrade dont la stat est au plafond. Un test doit prouver qu'un panel ne contient jamais une offre inapplicable.

**0.2 — Passifs d'équipement.**
Ajouter sur `EquipmentData` : `passive_id: StringName` (défaut vide) et `passive_value: float`. Un passif est une **règle**, pas un nombre : commence par deux implémentations réelles (ex. « +X % dégâts sous 50 % de PV », « soin de X PV à chaque niveau gagné »). Si `passive_id` est vide, le comportement actuel ne change pas.

**0.3 — Bonus de set.**
Deux pièces d'équipement partageant le même `set_id` accordent un bonus déclaré en `.tres`. Régler `Stats` en conséquence, sans jamais doubler un modificateur.

Livrable : diff + tests + suite complète verte.

---

## Lot 1 — Niveaux d'armes (priorité absolue)

C'est la brique qui change chaque run. Elle va plus loin que le lot 0 en valeur joueur.

**Données**
- `WeaponData` : `max_level: int = 5`, `level_damage_step`, `level_cadence_step`, `level_range_step` (fractions, ex. 0.25 / 0.10 / 0.05). **Aucune valeur en dur** : elles vivent dans les `.tres` de `res://data/weapons/`, avec un repli si le fichier est incomplet.
- `Inventory` : suit le niveau de chaque arme possédée (nouvelle structure indexée par `WeaponData`, pas un tableau parallèle fragile).
- `Stats` / `WeaponSystem` : appliquent le multiplicateur de niveau **avant** les multiplicateurs globaux, dans un ordre documenté.

**Offres**
- `Offer` : nouveau `kind = "weapon_upgrade"` portant l'arme et son niveau cible.
- `_build_offers` : ne **plus** exclure les armes possédées. Proposer « <Arme> +1 » tant que `niveau < max_level`, en réutilisant `_decorate_offer` pour afficher les chiffres **effectifs** (dégâts, att/s, DPS, portée) du niveau suivant — pas du niveau actuel.
- Pondération : `RunConfig` reçoit un `weapon_upgrade_weight` (défaut à valider avec moi). Une arme au niveau maximum sort du tirage.
- Une arme nouvellement acquise démarre au niveau 1 et n'est pas proposée en upgrade dans le même panel.

**UI**
- Le panneau doit distinguer visuellement **nouvelle arme** et **amélioration d'arme**.
- Le HUD affiche le niveau à côté de l'icône de chaque arme.

**Tests (gdUnit4, dans `tests/`)**
- montée 1 → max_level, refus au-delà
- un panel ne propose jamais une arme au niveau max
- les multiplicateurs de niveau se composent correctement avec les bonus globaux
- non-régression : 3 slots, pas de doublon d'arme

---

## Lot 2 — Évolutions d'armes

- `WeaponData` : `evolves_into: WeaponData` (null par défaut) et une condition d'évolution déclarative (niveau d'arme requis + éventuellement un `passive_id` d'équipement possédé).
- Quand la condition est remplie, l'évolution devient une **offre dédiée**, mise en avant dans le panel (priorité d'affichage, traitement visuel distinct), **une seule évolution par run**.
- Effet de feedback : anneau, son et texte dédiés, réglés dans `RunConfig`.
- Tests : condition non remplie → jamais proposée ; remplie → proposée une fois puis retirée ; l'arme évoluée hérite correctement des niveaux.

---

## Lot 3 — Méta-progression et sauvegarde

- Autoload `MetaSave`, fichier `user://meta.tres` (ou `.cfg` : tranche et justifie), avec `version: int` et migration.
- **Résilience obligatoire** : fichier absent, tronqué ou corrompu → démarrage normal sur des valeurs par défaut, log discret, jamais de crash ni de blocage.
- Monnaie persistante (« encre ») : montant par ennemi tué, fonction de `EnemyData` (pas une constante globale), créditée à la fin de la run, victoire **ou** mort.
- Déblocages durables, dans l'ordre : 4ᵉ slot d'arme, 2ᵉ classe de départ, variante d'arène, paliers de difficulté.
- Écran d'accueil : total d'encre, déblocages, bouton « Jouer ».
- Tests : round-trip save/load, migration depuis une version antérieure, fichier corrompu, valeurs par défaut.

**Interdit** : rendre le jeu injouable sans sauvegarde. Un nouveau joueur doit pouvoir lancer une run complète avec un fichier vierge.

---

## Contraintes non négociables

- **Zéro valeur de gameplay en dur.** Tout va dans `RunConfig` / les `.tres`.
- **Doc comment sur toute API publique**, dans le style existant du dépôt (anglais).
- **Tests gdUnit4** pour chaque système touché ; la référence de départ **109 tests / 17 suites (exit 0)** doit rester verte, sans suppression ni désactivation.
- **Ne casse pas** : les 10 mécaniques d'arme (`WeaponData.MECHANICS`), la localisation (`name_key` / `description_key`), les formats de `.tres` existants.
- **Pas de commit** sans mon accord explicite. Propose des messages référençant un ID de story.
- **Vérifie les API Godot 4.7** dans `docs/engine-reference/` avant usage — ne devine jamais.

## Déroulé attendu

1. **Questions bloquantes d'abord**, regroupées : courbe de niveau (linéaire ou exponentielle ?), 3 ou 4 slots, l'encre est-elle l'XP ou une monnaie séparée, priorité lot 1 vs lot 3.
2. **Plan des 4 lots** : ordre, fichiers touchés, décisions à valider, estimation.
3. **Puis lot par lot** : diff proposé → tests → résultat de la suite complète → mon accord → commit.
4. **Une ADR** par décision structurante (niveaux d'armes, format de sauvegarde), dans `docs/architecture/`.

N'écris **aucune ligne de code** avant mon accord sur le plan.

---

# Avenant — décisions validées après revue du plan

## Séquence retenue

1. **0.1** — offres mortes (correctif, seul, immédiat)
2. **1** — niveaux d'armes
3. **3** — identité d'équipement (passifs + sets), *ex-0.2 / 0.3*
4. **2** — évolutions
5. **4** — méta + sauvegarde (+ 4ᵉ slot)

> **Correction d'ordre** : les évolutions passent **après** l'identité d'équipement. Si le catalyseur d'évolution est un `passive_id` d'équipement, le placer avant le lot 3 est une inversion de dépendance : il dépendrait d'un champ qui n'existe pas encore. Variante acceptable : catalyseur = niveau d'arme seul au lot 2, puis enrichissement au lot 3 — mais dans ce cas assume-le explicitement, ne le découvre pas en cours de route.

## Décisions confirmées

- **Courbe linéaire additive**, l'évolution est le pic multiplicatif. Valeurs dans les `.tres`.
- **Trois slots.** Le 4ᵉ est un déblocage méta, quand le HUD sait afficher N lignes.
- **Encre séparée de l'XP.** `ink_value` par `EnemyData`, boss inclus.

## Amendements imposés

**A1 — Cadence : ramener +8 % à +5 % par niveau.** La cadence est l'axe le plus dégénéré : elle multiplie les DPS, le nombre de coups et donc les procs de critique et les mécaniques. Préciser dans l'ADR l'**ordre d'application** : bonus de niveau sur la stat de l'arme, **puis** multiplicateurs globaux. Écrire un test avec les valeurs attendues par niveau (dégâts, DPS, portée).

**A2 — Budget de panels.** 5 niveaux × 3 armes = 12 upgrades, + 3 acquisitions = **15 panels**, soit la totalité des level-ups d'une run de 10 vagues. Garde-fous obligatoires : `max_level = 4` pour la v1, et **jamais plus d'une offre d'arme par panel**.

**A3 — Encre : crédit partiel à la mort.** Créditer 100 % en victoire et ~70 % en défaite, ou poser des jalons par vague. Un joueur qui meurt en vague 2 et ne touche rien ne revient pas.

**A4 — Panel vide : risque introduit par 0.1.** Filtrer les offres plafonnées peut vider le pool. Dans `src/main.gd`, `_offer_choices` fait `if choices.is_empty(): return` **après** que `_check_level_up` a déjà consommé le niveau : le joueur perd un level-up en silence. Exiger une **offre de repli garantie** (ex. soin) et un test prouvant qu'un level-up affiche toujours au moins un choix.

**A5 — Arme évoluée : conserve son niveau.** Pas de remise à zéro, pas d'arrivée maxée. L'évolution garde le niveau courant et **relève `max_level`** (ex. 5 → 8) : la marge de progression reste visible et le pic de puissance vient du changement d'arme lui-même.

**A6 — Localisation.** Toute chaîne nouvelle (« +1 », textes d'évolution, écran méta) passe par `strings.csv` et les clés `name_key` / `description_key`. Aucune chaîne en dur.

**A7 — Documentation avant code.** Amender `design/gdd/weapons.md` (§3.1 et le contrat « un level-up ne remplace pas une arme ») et ses critères d'acceptation **avant** le lot 1. Un document de design méta, même court, avant le lot 4. Une ADR par décision structurante.

## Deuxième levier, hors périmètre de ce prompt

La variété des vagues reste le prochain chantier après celui-ci : `WaveDirector` ne gère aujourd'hui que la décroissance de l'intervalle, la croissance du `max_alive` et le boss périodique. Aucune composition de vague, aucune vague d'élites, aucun événement. À traiter dans un prompt séparé.
