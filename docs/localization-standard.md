# Standard de localisation — « né localisé »

| Champ | Valeur |
|---|---|
| Propriétaire | `localization-lead` |
| Épic | W8-E1 — Socle de localisation : clés, CSV, repli |
| Date | 2026-11-09 |
| Langue source | `fr` (français) |
| Première traduction | `en` (anglais) |
| Portée | Tout texte destiné au joueur, dans le jeu livré |

Ce document fait autorité. Toute chaîne destinée au joueur vit dans le système de
localisation, jamais dans le code. Un nouvel ennemi, une nouvelle arme ou un
nouvel écran naît localisé : sa clé existe dans le CSV avant que son texte
n'apparaisse à l'écran.

> **État à la date de ce document.** W8-E1 pose le socle et le prouve sur un jeu
> de clés réel. L'extraction des chaînes existantes (HUD, `main.tscn`, `.tres`)
> est **W8-E2** ; la traduction anglaise complète et le glossaire sont **W8-E3** ;
> le scan automatisé des chaînes en dur et la pseudo-locale sont **W8-E4**. Ce
> standard décrit la cible ; les écarts restants sont listés en §12.

---

## 1. Principe

1. **Une chaîne, une clé, une seule source.** Le texte français est la référence
   (`fr`). L'anglais (`en`) est une traduction, jamais une seconde source.
2. **Le code ne contient pas de texte joueur.** Il contient des clés.
3. **Aucune clé brute à l'écran.** Si une traduction manque, le repli affiche le
   français ; si le français manque aussi, c'est un bug bloquant, pas un
   comportement acceptable.
4. **La mise en forme appartient à la traduction.** Les placeholders (`%d`,
   `%s`, `%f`) et leur ordre sont dans la valeur traduite, pas concaténés dans le
   code.

---

## 2. Où vivent les chaînes

| Emplacement | Ce qu'on y met | Comment ça s'affiche |
|---|---|---|
| **Scènes `.tscn`** (Label, Button, RichTextLabel…) | La **clé** dans `text`, pas le texte | Godot traduit automatiquement `text` à l'affichage (`auto_translate_mode` : mode hérité par défaut, traduit au sommet de l'arbre). Exemple : `text = "hud.wave.label"` |
| **Code `.gd`** | Des **clés** passées à `tr()` | `tr("hud.hp.label")`. Pour un texte paramétré : `tr("hud.wave.banner") % (wave_index + 1)` |
| **Données `.tres`** | Une **clé** dans les champs de texte (`display_name`, etc.), pas un libellé | Le consommateur traduit : `tr(data.display_name_key)`. W8-E2 remplace les libellés actuels par des clés |
| **CSV** `data/localization/strings.csv` | Le texte `fr` et `en` de chaque clé | Source unique importée par Godot en `.translation` |
| **Ce qui n'est pas du texte** | Nombres, symboles de monnaie, dates, durées | Formatés selon la locale (voir §10), pas traduits mot à mot |

**Règle des `.tres`** : un champ de texte de données contient une clé, jamais un
libellé. `display_name = "Squelette"` devient une clé (par exemple
`enemy.squelette.name`) dont la valeur vit dans le CSV. W8-E2 fait la bascule ;
toute nouvelle donnée créée d'ici là suit déjà la règle.

---

## 3. Forme des clés

Notation pointée hiérarchique, segments en `snake_case`, tout en minuscules :

```text
<zone>.<sujet>.<détail>
```

Exemples réels et cibles :

```text
game.title
game.tagline
hud.hp.label
hud.hp.value
hud.wave.label
hud.wave.banner
hud.xp.label
hud.xp.value
hud.level.label
end.victory.title
end.defeat.title
enemy.squelette.name
enemy.loup_maudit.name
weapon.epee_longue.name
menu.settings.audio.volume_label
dialogue.npc.guard.greeting_01
```

Règles :

- **La clé décrit le contexte, pas le texte.** `hud.hp.label`, jamais
  `VIE` ni `vie_label_du_hud`.
- **Une clé = un contexte d'affichage.** Deux écrans qui affichent « Vague »
  avec des contraintes différentes ont deux clés si l'un des deux doit pouvoir
  diverger. On ne réutilise pas une clé pour un sens différent.
- **Identifiants stables.** Le suffixe d'un ennemi ou d'une arme suit son `id`
  technique (`enemy.squelette.name` pour `data/enemies/squelette.tres`), jamais
  son libellé. Le renommage d'un `display_name` ne renomme pas la clé.
- **Renommer ou fusionner une clé** : déplacer les traductions vers la nouvelle
  clé, mettre à jour **toutes** les références (scènes, code, `.tres`), et ne
  retirer l'ancienne clé qu'une fois plus rien ne la cherche.
- **Contexte et limites** : chaque clé est documentée au point d'appel (commentaire
  au-dessus de l'appel `tr()`, ou dans le champ de la donnée) avec l'écran, la
  longueur maximale si l'élément est contraint, et les variables. Les clés
  contraintes sont listées dans le tableau de §9.

---

## 4. Format du CSV

- **Chemin** : `data/localization/strings.csv` (unique fichier pour le socle ;
  voir §12 pour le découpage futur).
- **Encodage** : UTF-8 **sans BOM**. Les accents sont autorisés et attendus.
- **Séparateur** : virgule. Toute valeur contenant une virgule, un guillemet ou
  un saut de ligne est **entre guillemets** ; un guillemet interne se double.
- **Première ligne** : l'en-tête. La première colonne contient les clés ; les
  colonnes suivantes sont des codes de locale.

```csv
keys,fr,en
game.title,Medieval Survivors,Medieval Survivors
game.tagline,Un conte de survie médiévale,
hud.hp,VIE,HP
hud.wave,Vague,Wave
hud.xp,XP,XP
hud.level,NIV.,LVL
end.victory.title,Victoire !,Victory!
end.defeat.title,Mort au combat,Slain in battle
```

Règles de contenu :

- **La colonne `fr` est obligatoire et non vide** pour toute clé. C'est la
  source et le repli.
- **Une cellule `en` vide est autorisée** : elle signifie « pas encore traduit »,
  et le repli affiche le français. C'est le cas de `game.tagline` dans le socle ;
  W8-E3 le traduira.
- **Ne jamais écrire une clé dans une colonne de locale**, ni un texte dans la
  colonne `keys`.
- **Pas de ligne de commentaire.** Le lecteur CSV la traiterait comme une clé.
  Le contexte vit au point d'appel (§3), pas dans le CSV.
- Une locale absente du CSV n'existe pas pour le jeu : elle tombe entièrement
  dans le repli.

---

## 5. Repli

Ordre appliqué : **`fr`**.

```text
locale demandée (« en ») → clé absente → français (« fr ») → clé absente → bug
```

- Réglé dans `project.godot` :
  ```ini
  [internationalization]

  locale/fallback="fr"
  locale/translations=PackedStringArray("res://data/localization/strings.fr.translation", "res://data/localization/strings.en.translation")
  ```
- Une clé absente d'`en` affiche le texte français. Une locale sans traduction
  du tout (`de`, `es`… tant qu'elles ne sont pas livrées) affiche tout en
  français.
- **Ne jamais laisser une clé brute atteindre l'écran.** Si le français manque
  aussi, `TranslationServer.translate()` renvoie la clé : c'est un bug de
  contenu (ligne absente ou clé mal orthographiée), pas un repli acceptable.
- Godot 4.7 n'expose pas de setter de repli à l'exécution : le repli vient de la
  configuration projet, pas d'un appel de code. Ne pas tenter
  `TranslationServer.set_fallback_locale()` — elle n'existe pas.

---

## 6. Procédure d'import Godot (CSV → `.translation`)

L'importateur `csv_translation` de Godot lit le CSV et génère **un fichier par
locale, à côté du CSV** :

```text
data/localization/strings.csv            ← source, versionné
data/localization/strings.csv.import     ← descripteur d'import, versionné
data/localization/strings.fr.translation ← généré, ignoré par git (*.translation)
data/localization/strings.en.translation ← généré, ignoré par git (*.translation)
```

`*.translation` est dans `.gitignore` : il est **régénéré à chaque import** et
ne se commite pas. Toute machine (et la CI) doit donc importer le projet avant
de lancer le jeu ou les tests.

### Commandes exactes

1. Éditer `data/localization/strings.csv`.
2. Importer en headless (binaire console de `project.yaml → engine.path`,
   variante `_console`) :

   ```bash
   "C:/Users/balthazar/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" \
     --headless --path "C:/Users/balthazar/Documents/Code/Claude-Code-Game-Studios" \
     --editor --quit
   ```

   Après une modification du CSV, la sortie contient une étape
   `reimport | strings.csv` et se termine par le code `0`.
3. Vérifier que les deux `.translation` ont été régénérés :

   ```bash
   ls -la data/localization/*.translation
   ```

4. Lancer la suite (elle prouve le pipeline) :

   ```bash
   "C:/Users/balthazar/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe" \
     --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
   ```

`strings.csv.import` est produit par l'éditeur. Il est versionné ; ne pas le
réécrire à la main. Si l'import ajoute une locale, il faut aussi l'ajouter au
tableau `internationalization/locale/translations` de `project.godot` (§8).

---

## 7. Faire naître un nouvel ennemi, une nouvelle arme, un nouvel écran

La procédure est la même pour les trois ; seuls le préfixe de clé et le type de
données changent. Un contenu n'est **pas** terminé tant que ces étapes ne sont
pas faites.

### Nouvel ennemi (`data/enemies/<id>.tres`)

1. Choisir l'`id` technique stable (`squelette`, `loup_maudit`…).
2. Dans `strings.csv`, ajouter au minimum :
   - `enemy.<id>.name` — nom affiché (barre de boss, bestiaire) ;
   - toute annonce ou description joueur : `enemy.<id>.telegraph_01`, etc.
   La colonne `fr` est remplie ; `en` vide tant que W8-E3 n'a pas traduit.
3. Dans la ressource, faire pointer le champ de texte sur la clé (W8-E2 aura
   déjà remplacé `display_name` par une clé ; d'ici là, ajouter la clé et
   signaler l'écart).
4. Au point d'affichage, traduire avec `tr(data.display_name_key)`.
5. Ajouter l'ennemi à la suite de tests de localisation si son nom est affiché
   dans un écran couvert (sinon, W8-E4 le fera via la parité).

### Nouvelle arme (`data/weapons/<id>.tres`)

Même schéma : `weapon.<id>.name`, plus `weapon.<id>.description` si l'arme en a
une. Le suffixe `id` suit le nom de fichier, jamais le libellé français.

### Nouvel écran

1. Lister les textes visibles (titre, libellés, boutons, messages, états vides).
2. Pour chacun, créer une clé sous la zone de l'écran (`menu.`, `hud.`, `end.`…).
3. Dans la scène, mettre la clé dans `text` ; pour le texte construit en code,
   utiliser `tr()`.
4. Définir les limites de longueur des éléments contraints (§9) et les noter au
   point d'appel.
5. Vérifier l'écran en `fr` **et** en `en` (capture conservée dans
   `production/qa/evidence/` pour une story UI, conformément à
   `.claude/docs/run-and-observe.md`).

---

## 8. Ajouter une langue

Décision de portée : **le `producer`**, pas ce standard. Une fois la langue
décidée :

1. Ajouter une colonne de locale au CSV (`keys,fr,en,de`), remplir les valeurs.
2. Réimporter (§6) : Godot génère `strings.de.translation`.
3. Ajouter le chemin `res://data/localization/strings.de.translation` au tableau
   `internationalization/locale/translations` de `project.godot`.
4. Mettre à jour la matrice de polices (§11) si les caractères ne sont pas
   couverts.
5. Ajouter la langue à la suite de tests de locale et au plan de QA
   (`qa-lead`), y compris les formats (§10).

Le repli reste `fr` tant qu'une décision explicite ne le change pas.

---

## 9. Contraintes de longueur et mise en page

- Allemand et finnois peuvent dépasser l'anglais de 30 à 40 % ; le chinois et le
  japonais sont souvent plus courts mais demandent une taille de police plus
  grande.
- Les conteneurs de texte utilisent l'auto-dimensionnement quand c'est possible
  (`autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` sur les libellés
  multilignes).
- Toute clé affichée dans un élément de largeur fixe reçoit une **longueur
  maximale** notée au point d'appel et transmise au traducteur. Le socle actuel
  n'a pas encore de tableau de limites ; W8-E2 doit le produire pour chaque
  chaîne extraite, et W8-E4 le vérifie en pseudo-locale.
- Aucune troncature silencieuse : un texte qui ne rentre pas est un bug de mise
  en page, à remonter à `ux-designer`.

---

## 10. Formats dépendants de la locale

Une chaîne traduite ne suffit pas : les valeurs doivent suivre la locale.

| Élément | Règle | Aujourd'hui |
|---|---|---|
| Nombres | Séparateur décimal selon la locale (`1,5` en fr, `1.5` en en) | W8-E2/E4 : formater via l'API de locale, pas `%f` brut dans les cas localisés |
| Dates | Ordre JJ/MM/AAAA vs MM/DD/AAAA selon la locale | Non utilisé dans le socle |
| Heures | 24 h vs 12 h | Non utilisé dans le socle |
| Monnaie | Symbole et position selon la locale | Non utilisé dans le socle (la monnaie de run arrive en W4) |
| Pluriels | Une forme par catégorie CLDR de la locale | Voir ci-dessous |

**Pluriels.** Godot 4.6+ sait porter les pluriels directement dans le CSV (sans
Gettext) et a ajouté des colonnes de contexte. Le socle W8-E1 n'a **aucune
chaîne au pluriel** : ne pas inventer la syntaxe avant la première chaîne
concernée. Quand elle arrivera (W8-E2/E3), la règle est : une clé par catégorie
CLDR de la locale (`_one`, `_few`, `_many`, `_other`…), `_other` toujours
présent y compris pour couvrir les fractions, et une traduction par catégorie
dans chaque colonne de locale. La syntaxe exacte de l'importateur 4.7 doit être
vérifiée dans l'éditeur au moment de l'ajout, puis figée ici.

**Ordre des mots.** Jamais de concaténation de fragments traduits. Un texte
paramétré est une seule clé contenant les placeholders. Exemple de la forme à
adopter quand le HUD paramétré sera extrait (ces clés ne sont pas encore dans le
socle W8-E1) :

```csv
hud.hp.value,VIE %d / %d,HP %d / %d
hud.wave.banner,VAGUE %d,WAVE %d
```

Le traducteur peut alors déplacer le placeholder selon l'ordre de sa langue.

---

## 11. Polices et caractères

- Le socle `fr`/`en` tient dans une police Latin-extended.
- Toute nouvelle langue doit être vérifiée contre une **matrice langue → police**
  avant d'être annoncée : CJK, cyrillique, arabe/hébreu (avec façonnage RTL),
  devanagari, thaï, coréen. Une police dédiée peut peser plusieurs mégaoctets :
  l'impact sur le build est arbitré avec `technical-director`.
- Une locale RTL demande le miroir de l'interface et le rendu bidirectionnel ;
  rien de tel n'est livré ni promis à ce stade.

---

## 12. Interdits, et comment les vérifier

### Interdits

1. **Texte joueur en dur** dans `src/**/*.gd`, `scenes/**/*.tscn` ou
   `data/**/*.tres` : toute chaîne destinée à l'écran passe par une clé.
2. **Clé en dur traduite à la main** : on écrit `tr("hud.hp")`, jamais
   `if locale == "en": "HP"`.
3. **Concaténer des morceaux traduits** pour former une phrase.
4. **Réutiliser une clé** pour un sens ou un contexte différent.
5. **Renommer une clé sans migrer ses traductions et toutes ses références.**
6. **Éditer `strings.*.translation` à la main** : ils sont générés, et ignorés
   par git.
7. **Ajouter une colonne de locale sans l'import et sans l'entrée
   `project.godot`.**
8. **Laisser une clé sans colonne `fr`.**

### Vérification manuelle (avant W8-E4)

```bash
# Textes littéraux assignés dans le code (hors commentaires, hors appels tr()).
rg -n --glob '!addons/**' --glob '!tests/**' '\.text\s*=\s*"[^"]+"' src scenes

# Libellés encore en dur dans les données.
rg -n 'display_name\s*=\s*"[^"]+"' data

# Chaînes de format joueur construites à la main.
rg -n --glob '!addons/**' --glob '!tests/**' '"[^"]*%[dsf][^"]*"' src
```

Un littéral est conforme s'il correspond à une **clé** (minuscules, segments
`snake_case` séparés par des points), pas à un texte affichable. Tant que W8-E2
n'a pas extrait les chaînes existantes, ces commandes trouvent du texte légitime
(le travail à faire) ; elles deviennent un gate à part entière avec le scan de
W8-E4.

### Ce qui n'est pas du texte joueur

Commentaires, noms de classes, chemins de ressources, identifiants internes,
messages de `push_error`/`push_warning` destinés aux développeurs. Ils restent en
anglais ou en français dans le code et ne vont pas dans le CSV.

---

## 13. Preuve et tests

La suite `tests/unit/localization_test.gd` (gdUnit4) prouve le socle :

- le repli projet vaut `fr` ;
- le CSV déclare les colonnes `keys`, `fr`, `en` ;
- les deux `.translation` sont enregistrés dans `project.godot` et existent ;
- une clé se traduit en français en locale `fr` et en anglais en locale `en` ;
- une clé sans traduction anglaise retombe sur le français ;
- une locale sans traduction retombe sur le français.

Commande : `commands.test` de `project.yaml` (voir `tests/README.md`). Les tests
restaurent la locale qu'ils ont trouvée, pour ne pas contaminer les autres
suites.

---

## 14. Limites connues à la date de W8-E1

| Sujet | État | Suite |
|---|---|---|
| Chaînes existantes (HUD, `main.tscn`, `.tres`) | **Non extraites** — encore en dur | W8-E2 |
| Traduction anglaise complète + glossaire fr/en | Partielle (socle de preuve) | W8-E3 |
| Scan automatisé des chaînes en dur, parité, pseudo-locale | Manuel seulement | W8-E4 |
| Pluriels, dates, nombres, monnaie | Non utilisés dans le socle | Au premier besoin, W8-E2/E3 |
| RTL, CJK, polices dédiées | Hors périmètre | Selon décision de portée du `producer` |
| Découpage du CSV par écran/système | Un seul fichier `strings.csv` | Quand le volume le justifie (W8-E2/E3) |
