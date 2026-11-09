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
| `verify_slice02.gd` | `integration/combat_weapons_test.gd` | 6 | inventaire de départ ; trois armes uniques ; stats d'équipement sans double comptage ; coup de mêlée ; projectile ; offres (pas d'arme quand les slots sont pleins, application effective) |
| `verify_slice03.gd` | `integration/progression_level_up_test.gd` | 11 | câblage ; courbe d'XP ; stats additives ; critique ; poids de rareté ; texte d'équipement ; timings d'attaque ; invulnérabilité ; signal `hit_landed` ; équipement dominé jamais offert ; reroll |
| `verify_slice04.gd` (règles) | `integration/boss_rules_test.gd` | 10 | câblage boss ; cadence toutes les 5 vagues ; paliers de scaling ; télégraphe ; portée du slam ; résistance au recul ; spawner qui ignore le boss ; finish line ; pas de doublon de slot ; plafond d'offres d'armes |
| `verify_slice04.gd` (combat) | `integration/boss_fight_test.gd` | 3 | apparition d'un unique boss palier 0 + barre ; dégâts du slam dans le rayon seulement ; mort du boss → butin |
| — | `integration/main_scene_bootstrap_test.gd` | 1 | la scène principale expose `Player` et `EnemyManager` |
| — | `integration/data_catalogue_test.gd` | 7 | `data/catalogue.tres` énumère tout le contenu (3 ennemis, 1 boss, 4 armes, équipement, améliorations, vagues, classe) et le charge |
| — | `integration/spawner_unlock_test.gd` | 7 | les déverrouillages pointent sur `EnemyData.id`, jamais sur `display_name` ; renommer l'un ne déverrouille pas l'autre |
| — | `unit/harness_bootstrap_test.gd` | 1 | le harnais lui-même : découverte, assertion, code de sortie |
| — | `unit/run_config_test.gd` | 3 | `data/run_config.tres` se charge ; courbe d'XP (5, 4) et paliers de boss (0.9, 0.35) inchangés par W0-E3 |
| — | `unit/input_map_test.gd` | 6 | les dix actions de run existent ; les lettres sont liées en **physique** (A/D/W/S = ZQSD sur AZERTY) ; axes de manette ; zone morte = `RunConfig.joy_axis_deadzone` ; une touche logique Q ne déclenche pas `move_left` |

**Total : 58 tests, 11 suites.**

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
