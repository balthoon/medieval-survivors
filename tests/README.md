# Tests — Medieval Survivors

Une seule entrée : la commande `commands.test` de `project.yaml`, qui lance
gdUnit4 6.2.2 en headless sur tout `res://tests`. Elle est prouvée : verte elle
sort en `0`, une assertion fausse la fait sortir en `100`.

```bash
"C:/Users/balthazar/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" \
  --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

## Codes de sortie

| Code | Sens | CI |
|---|---|---|
| `0` | tout est passé, aucun orphelin | succès |
| `100` | au moins une assertion a échoué | échec |
| `101` | nœuds orphelins — un test n'a pas libéré ce qu'il a créé | échec |
| `103` | le mode headless n'est pas supporté | échec |
| `104` | version de Godot non supportée par gdUnit4 | échec |
| `105` | erreur de script / de parsing | échec |

`0` avec **zéro test exécuté** est possible et ne prouve rien : la CI (W0-E4)
doit compter les tests exécutés et échouer si le compte est nul.

## Carte de couverture

Les quatre scripts jetables `tools/verify_*.gd` ont été portés en W0-E2, puis
supprimés. Correspondance :

| Ancien script | Suite gdUnit4 | Tests | Ce qui est couvert |
|---|---|---|---|
| `verify_facing.gd` | `integration/facing_targeting_test.gd` | 3 | lame sans ennemi → direction du mouvement ; ennemi hors portée quand même visé ; l'ennemi le plus proche gagne |
| `verify_slice02.gd` | `integration/combat_weapons_test.gd` | 6 | inventaire de départ ; trois armes uniques ; stats d'équipement sans double comptage ; coup de mêlée ; projectile ; offres (pas d'acquisition quand les slots sont pleins, application effective, niveau compris dans l'empreinte) |
| `verify_slice03.gd` | `integration/progression_level_up_test.gd` | 11 | câblage ; courbe d'XP ; stats additives ; critique ; poids de rareté ; texte d'équipement ; timings d'attaque ; invulnérabilité ; signal `hit_landed` ; équipement dominé jamais offert ; reroll |
| `verify_slice04.gd` (règles) | `integration/boss_rules_test.gd` | 10 | câblage boss ; cadence toutes les 5 vagues ; paliers de scaling ; télégraphe ; portée du slam ; résistance au recul ; spawner qui ignore le boss ; finish line ; pas de doublon de slot ; plafond d'offres d'armes |
| `verify_slice04.gd` (combat) | `integration/boss_fight_test.gd` | 3 | apparition d'un unique boss palier 0 + barre ; dégâts du slam dans le rayon seulement ; mort du boss → butin |
| — | `integration/main_scene_bootstrap_test.gd` | 1 | la scène principale expose `Player` et `EnemyManager` |
| — | `integration/data_catalogue_test.gd` | 13 | `data/catalogue.tres` énumère tout le contenu (3 ennemis, 1 boss, 10 armes, équipement, améliorations, vagues, classe) et le charge ; chaque arme a un id unique et un `mechanic` connu ; les 3 ensembles et leurs valeurs design ; chaque `set_id` nomme un ensemble enregistré qui a assez de pièces ; les passifs rage/soin sont portés par leurs pièces ; chaque arme nomme une évolution distincte, absente du catalogue, à plafond plus haut, de même mécanique, avec ses clés et sans seconde évolution (lot 2) |
| — | `integration/spawner_unlock_test.gd` | 7 | les déverrouillages pointent sur `EnemyData.id`, jamais sur `display_name` ; renommer l'un ne déverrouille pas l'autre |
| — | `integration/weapon_mechanics_test.gd` | 13 | les dix mécaniques W2-E2 : bonus de portée de l'arc, falloff de l'arbalète, projectile perforant vs simple, refund d'exécution, chaîne, tour complet de la faux, vol de vie (normal et refusé sur élite), orbe une fois par tour, mèche de l'encensoir, stagger (immunité des élites), description d'offre nommant la mécanique |
| — | `unit/harness_bootstrap_test.gd` | 1 | le harnais lui-même : découverte, assertion, code de sortie |
| — | `unit/run_config_test.gd` | 3 | `data/run_config.tres` se charge ; courbe d'XP (5, 4) et paliers de boss (0.9, 0.35) inchangés par W0-E3 |
| — | `unit/input_map_test.gd` | 6 | les dix actions de run existent ; les lettres sont liées en **physique** (A/D/W/S = ZQSD sur AZERTY) ; axes de manette ; zone morte = `RunConfig.joy_axis_deadzone` ; une touche logique Q ne déclenche pas `move_left` |
| — | `unit/localization_test.gd` | 7 | les ressources `.translation` de `project.godot` sont enregistrées ; une clé se traduit en français et en anglais ; une clé absente de l'anglais retombe sur le français ; une locale sans traduction retombe sur `fr` |
| — | `unit/obstacle_field_test.gd` | 12 | le champ de collision des décors (lot 1) : point libre inchangé ; poussée cercle et rectangle à la distance de contact exacte ; sortie par la face la plus proche ; `slide` libre, diagonal (composante tangentielle gardée) et frontal (coup de pouce latéral) ; formes invalides ignorées ; `PilotArenas.obstacle_field()` = 22 cercles (9 troncs, 12 rochers, 1 autel) et 1 rectangle (tronc tombé), buissons absents ; `VisualPilot` en storybook par défaut et son champ délègue à `PilotArenas` |
| — | `integration/obstacle_collision_test.gd` | 3 | la scène principale partage un unique champ non vide entre le joueur et `EnemyManager` ; un tronc bloque le chevalier poussé vers la droite et ne le laisse jamais dedans ; un squelette apparu au centre d'un tronc est résolu dehors |
| — | `unit/actor_animations_test.gd` | 12 | les minuteries du lot 2 (ADR-0003) : phase de marche figée à l'arrêt, avancée en mouvement, bornée à `[0, TAU)` ; lunge armé sur l'angle de tir, décroît à zéro sans devenir négatif ; ni marche ni lunge ne déplace `position` ; `DeathFade.create` copie art/rayon/teinte, mi-durée = moitié écrasé et moitié transparent, fin = `END_SCALE`, alpha 0, `queue_free` ; `step_visual` avance le temps du dandinement sans déplacer le corps ; phase déterministe dérivée du point d'apparition |
| — | `integration/animation_wiring_test.gd` | 3 | la vraie scène relie `WeaponSystem.attack_started` à `Player.play_attack_lunge` (temps et direction) ; `remove_dead` crée exactement un `DeathFade` à l'endroit de la mort, retire l'ennemi et rend son XP ; `step_all` avance l'horloge d'animation d'un ennemi vivant tout en le faisant avancer |
| — | `unit/stats_caps_test.gd` | 6 | les plafonds de stats d'une offre : `is_capped` pour le bonus du joueur seul, `crit_is_capped_for` pour les armes réellement portées (un bonus de 0,70 sous le plafond devient mort avec une arme à 0,05 de base) ; aucune des deux ne confond les deux questions |
| — | `integration/offer_pool_test.gd` | 4 | le pool ne propose jamais une stat au plafond (crit) ni un équipement au plafond ; un pool entièrement vide se replie sur une amélioration ; un niveau sans aucune offre applicable n'est pas consommé — les deux tests de repli dépensent aussi l'unique évolution de la run pour fermer la branche arme |
| — | `unit/weapon_levels_test.gd` | 12 | lot 1 : pas additif sur la base (niv. 4 = ×1,75, pas ×1,25³) et avant les multiplicateurs globaux ; cadence +5 % par niveau ; portée et rayon d'orbe ; niveau < 1 lu comme 1 ; plafond à `max_level` ; refus si l'arme n'est pas portée ; arme neuve au niveau 1 ; remplacement et nouvelle run repartent au niveau 1 ; `DamageCalc.roll` utilise le niveau demandé et vaut 1 par défaut |
| — | `integration/weapon_upgrade_offers_test.gd` | 9 | lot 1 : une seule ligne d'arme par panneau (acquisition ou niveau, jamais les deux) ; le niveau vise le suivant et affiche les nombres effectifs à ce niveau ; la ligne de nombres suit la locale active (français ou anglais, jamais les deux) ; une arme au max n'est jamais offerte ; le niveau choisi ne remet pas le cooldown à zéro ; une arme neuve entre au niveau 1 ; le poids de niveau vient de `RunConfig` et le butin de boss le remplace |
| — | `unit/equipment_identity_test.gd` | 11 | lot 3 : rage inactive au seuil et au-dessus, ×1,15 en dessous, composée avec le multiplicateur global ; bonus d'ensemble additif avec les pièces et critique toujours plafonné ; comptage des pièces portées, complétion selon `required_pieces`, somme des passifs ; texte de passif vide sans passif, texte d'ensemble formaté |
| — | `integration/equipment_bonuses_test.gd` | 10 | lot 3 dans la vraie run : Duelliste +12 % crit appliqué une seule fois malgré deux recalculs ; remplacer une pièce retire le bonus ; le casque de fer casse Duelliste et permet Colosse ; Rage ×1,15 sous 50 % PV ; amulette rend 8 PV à la montée et le titre du panneau indique le montant réel (+0 à PV pleins) ; l'offre nomme le passif et la ligne d'ensemble (progression puis bonus) ; le HUD affiche la progression des ensembles et le mot d'état de la rage |
| — | `unit/weapon_evolutions_test.gd` | 12 | lot 2 : `has_evolution`/`evolution_level_required` (0 délègue au plafond) ; `evolution_ready` exige port, niveau, catalyseur et verrou libre ; `evolve_weapon` conserve le niveau sous l'id évolué, efface l'entrée de base, pose le verrou ; refus sans condition (rien ne change) ; `has_evolved_from` ; `setup_starting` remet le verrou à vide ; une évolution ne s'enchaîne pas |
| — | `integration/weapon_evolution_offers_test.gd` | 11 | lot 2 sur le vrai panneau : condition incomplète → aucune ligne ; remplie → une ligne, en première position, sans autre ligne d'arme (A2) ; catalyseur requis ; description « conservé » + « max 7 » + DPS ; l'évolution conserve niveau et cooldown ; offerte une fois puis retirée ; la base n'est jamais reproposée en acquisition ; l'arme évoluée peut encore monter ; bannière nommée, teintée et effacée par la vague suivante |

**Total : 189 tests, 25 suites.**

## Conventions

- Nom de fichier `[system]_[feature]_test.gd`, fonction `test_[scenario]_[expected]`
  (`.claude/rules/test-standards.md`).
- Chaque test suit Arrange / Act / Assert et **construit sa propre scène** :
  gdUnit4 peut exécuter les tests dans n'importe quel ordre.
- Une suite qui a besoin de la vraie scène principale précharge
  `tests/fixtures/main_scene_fixture.gd` (pas de `class_name` : la suite doit
  tourner sur un clone dont le cache de classes est ancien) :

  ```gdscript
  const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")

  var main := MainSceneFixture.instantiate(self)
  await MainSceneFixture.await_ready(self)
  MainSceneFixture.silence_waves(main)
  ```

- Tout nœud créé à la main passe par `auto_free(...)`, sinon la run sort en `101`.
- Les assertions texte utilisent `assert_str(...)` — gdUnit4 6.2.2 n'expose pas
  `assert_string`.
- Les messages d'échec d'origine sont conservés via
  `override_failure_message(...)`.
- Ne jamais écrire sous `addons/` : c'est du code vendorisé, remplacé en bloc.

## Contrat de merge (W0-E4)

Aucun merge sur `main` si `commands.test` ne sort pas en `0`, si le compte de
tests exécutés est nul, ou si le code de sortie est `101`, `103`, `104` ou `105`.

Le gate est `.github/workflows/tests.yml`, job **`gdUnit4 suite`** : il installe
Godot `4.7.2-stable` (la version de `project.yaml`), importe le projet en
headless, lance gdUnit4 avec les mêmes arguments que `commands.test` (binaire
Linux au lieu du binaire Windows), puis refuse tout code de
sortie non nul et tout rapport à zéro test. Le job ne devient bloquant
qu'après une première exécution réussie : dans **Settings → Branches → main**,
ajouter `gdUnit4 suite` aux *required status checks*. Tant que ce réglage n'est
pas fait, le workflow signale mais ne bloque pas.
