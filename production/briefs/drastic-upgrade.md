# Brief — faire de Medieval Survivors un vrai jeu

**Statut :** prêt pour l'équipe
**Écrit le :** 2026-11-09
**À lire avant de commencer :** `CLAUDE.md`, `design/art/art-bible.md`,
`production/session-state/active.md`, `project.yaml`

---

## 1. Mission

Nous avons une tranche verticale qui fonctionne : un chevalier survit à dix
vagues, monte de niveau, affronte deux boss, récupère du butin, et gagne ou
meurt. C'est correct, vérifié par des scripts, et dessiné d'une seule main.
C'est aussi **superficiel** : chaque run se ressemble, tous les ennemis font la
même chose, et il n'y a rien à décider entre deux vagues.

Votre travail : la faire passer de *« une tranche qui marche »* à *« un jeu
auquel un inconnu joue vingt minutes sans une minute ennuyeuse ou cassée »*.

C'est la barre. Pas « plus de contenu ». Vingt minutes, pas une minute ennuyeuse.

---

## 2. Où en est le jeu — des faits, pas des impressions

### Exécution

| | |
|---|---|
| Moteur | Godot 4.7.2 stable, GDScript, Forward+ |
| Fenêtre | 1280×720 fixe |
| Forme du run | 10 vagues × 20 s, boss aux vagues 5 et 10, victoire quand le chrono de la dernière vague est écoulé et son boss mort |
| Entrées | déplacement clavier (WASD/ZQSD physique + flèches), visée automatique sur l'ennemi le plus proche, touches 1–3 pour choisir, R pour relancer, M pour couper le son. **Aucun déplacement à la manette.** |
| Audio | 8 effets ponctuels dans `assets/audio/sfx/`. **Aucune musique, aucun mixage par bus.** |
| Persistance | aucune. Rien ne se débloque, rien n'est sauvegardé. |
| Langue | chaînes françaises codées en dur dans `src/ui/hud.gd` et la scène |

### Inventaire du contenu

| Type | Nombre | Où |
|---|---|---|
| Classes | **1** (`chevalier`) | `data/classes/` |
| Armes | 4 (dague, épée longue, marteau, arc court) | `data/weapons/` |
| Ennemis | 3 archétypes + 1 boss, tous *marchent vers toi et te touchent* | `data/enemies/` |
| Équipement | 12 (2 par emplacement du corps) | `data/equipment/` |
| Améliorations | 5 (dégâts, cadence, précision, vitalité, vitesse) | `data/upgrades/` |
| Vagues | 1 ressource de réglage | `data/waves/base_wave.tres` |

### Carte du code (les points d'extension)

| Sujet | Fichier |
|---|---|
| Orchestration du run, événements de vague, boss, XP, offres | `src/main.gd` (≈880 lignes) |
| Horloge et cadence des vagues | `src/classes/wave_director.gd` (logique pure, testable) |
| Comportement des ennemis | `src/actors/enemy.gd`, `src/systems/enemy_manager.gd` |
| Armes | `src/systems/weapon_system.gd`, `src/actors/weapon_view.gd`, `src/actors/projectile.gd` |
| Art | `src/art/ink_style.gd` (primitives), `src/art/actor_art.gd` (la distribution) |
| HUD | `src/ui/hud.gd`, `src/ui/hud_frame.gd` |
| Stats, inventaire, offres, dégâts | `src/classes/` |

### La dette que vous héritez (ne faites pas semblant qu'elle n'existe pas)

- `design/gdd/game-concept.md` décrit encore **The Conductor**, un autre jeu. Il
  n'existe aucun GDD pour Medieval Survivors.
- `project.yaml` dit `project.stage: Concept`. Ce n'est pas le stade Concept.
- Les constantes de palier de boss et le chemin du boss sont codés en dur dans
  `src/main.gd`.
- `CLASS_PATH`, `ENEMY_PATHS`, `WEAPON_PATHS` sont des tableaux codés en dur.
- La suite de tests, ce sont `tools/verify_*.gd` — des scripts jetables, pas
  gdUnit4. `commands.test` pointe vers un addon gdUnit4 qui n'est pas installé.

---

## 3. Ce que « drastique » veut dire ici

Trois piliers. Chaque chantier doit servir l'un d'eux ; refusez tout travail qui
n'en sert aucun.

1. **Chaque run est différent.** Même classe, mêmes armes, mêmes ennemis, même
   ordre = le joueur s'arrête au bout de trois runs. La variété n'est pas du
   volume de contenu, c'est de l'**espace de décision**.
2. **Chaque ennemi pose une question différente.** Aujourd'hui les quatre posent
   « sais-tu reculer ? ». Un chargeur pose « sais-tu esquiver sur une
   annonce ? », un ennemi à distance pose « sais-tu fermer la distance ? », un
   exploseur pose « sais-tu le tuer à temps ? ».
3. **Le joueur a toujours un choix qui compte.** Entre les vagues, pendant une
   vague, au level-up. Si la réponse est toujours « prends plus de dégâts », il
   n'y a pas de jeu.

---

## 4. Chantiers

Chaque chantier a un propriétaire qui rend compte au producteur. Les
propriétaires découpent leurs propres stories ; ne sautez pas le niveau.

### W0 — Colonne vertébrale qualité (continu, tous les propriétaires)

- Monter une vraie suite de tests (gdUnit4 ou un équivalent documenté),
  convertir les quatre `tools/verify_*.gd`, et faire en sorte que
  `project.yaml → commands.test` l'exécute. Aucune fonctionnalité ci-dessous
  n'est « finie » sans un test qui échouerait si elle cassait.
- Réécrire `design/gdd/game-concept.md` pour **ce** jeu avant de concevoir une
  mécanique. Propriétaires : `narrative-director` + `game-designer`.
- Sortir les données de run encore codées en dur (`CLASS_PATH`, `ENEMY_PATHS`,
  `WEAPON_PATHS`, constantes de boss) vers des ressources. Propriétaire :
  `lead-programmer`.

### W1 — Variété de comportement des ennemis *(P0)*

Propriétaire : `game-designer`, puis `ai-programmer` ; silhouettes par
`art-director`.

Cinq comportements minimum, six ennemis au total :

| Comportement | Se lit comme | Demande au joueur |
|---|---|---|
| Marcheur | squelette/orc/loup existants | sais-tu kiter ? |
| Chargeur | bas, cornu, annonce une ligne avant de foncer | sais-tu lire et esquiver ? |
| À distance | fin, bâton, garde ses distances et tire | sais-tu fermer la distance ? |
| Exploseur | rond, luisant, accélère et détonne | sais-tu le tuer à temps ? |
| Invocateur | grand, encapuchonné, fait apparaître des marcheurs | sais-tu prioriser ? |

Règles :
- Chaque comportement a une **annonce** que la bible d'art peut décrire, et une
  silhouette impossible à confondre avec une existante.
- Les comportements vivent dans des données + un petit script chacun ;
  `enemy.gd` ne doit pas grossir d'un `match` sur six chaînes.
- Chaque nouvel ennemi : entrée dans la bible d'art, capture dans
  `production/qa/evidence/`, et une vérification headless de son comportement.

**Critère d'acceptation :** un run complet contient au moins quatre
comportements distincts, et un joueur peut nommer ce que chaque ennemi s'apprête
à faire avant qu'il le fasse.

### W2 — Arsenal aux mécaniques distinctes *(P0)*

Propriétaires : `systems-designer` + `gameplay-programmer`.

Passer de 4 à **10 armes**, chacune avec une mécanique que les autres n'ont pas
(entaille large, tir perforant, arc en chaîne, orbe orbitale, détonation
retardée, vol de vie). Une arme qui ne change qu'un chiffre n'est pas du
contenu — refusez-la.

**Critère d'acceptation :** trois runs d'affilée proposent des builds
différents, et aucune arme n'est strictement meilleure qu'une autre au même prix.

### W3 — Sélection de classe *(P0)*

Propriétaires : `game-designer` + `ui-programmer` ; art par `art-director`.

Trois classes aux départs distincts, un écran pour les choisir. Le chevalier
reste ; ajoutez-en deux qui se jouent autrement dès la vague 1 (une à distance,
une mêlée lourde). Une classe = un `ClassData` + une arme de départ + des stats
+ une règle signature.

**Critère d'acceptation :** l'écran de classe existe, se pilote au clavier,
laisse une capture, et chaque classe survit à son premier boss avec une
stratégie différente.

### W4 — Décisions entre les vagues et économie *(P1)*

Propriétaires : `economy-designer` + `systems-designer` + `ui-programmer`.

Quelque chose à dépenser entre les vagues. Concevez la monnaie **avant** l'UI.
Note : la bible d'art réserve l'or à l'XP ; si l'économie a besoin de sa propre
monnaie, c'est une modification de la bible d'art et l'`art-director` doit
l'approuver.

**Critère d'acceptation :** un joueur termine un run avec au moins trois achats
qu'il peut expliquer ; la boutique laisse une capture ; les prix viennent des
données.

### W5 — Un audio qui porte le jeu *(P1)*

Propriétaires : `audio-director` + `sound-designer`.

Une musique par état (calme / vague / boss / victoire), un bus mixé, et les
effets existants rééquilibrés par rapport à elle. Aucun fichier de musique livré
sans cible de mixage écrite.

**Critère d'acceptation :** le jeu se joue vingt minutes avec le son sans
transition qui casse l'oreille ni saturation.

### W6 — Réglages, pause, accessibilité *(P1)*

Propriétaires : `ux-designer` + `ui-programmer` ; accessibilité par
`accessibility-specialist`.

Menu pause, volume, remappage, vérification daltonisme de la palette, taille de
texte, déplacement à la manette. `design/accessibility-requirements.md` n'existe
pas encore — créez-le à partir des contraintes réelles de ce jeu, pas d'un
gabarit.

**Critère d'acceptation :** chaque écran atteignable au clavier seul ; les
réglages tiennent pour la session ; captures des deux.

### W7 — Méta-progression *(P2)*

Propriétaires : `economy-designer` + `lead-programmer`.

Quelque chose survit à un run : déblocages, bonus de départ, un record. Petit et
honnête bat un faux arbre.

**Critère d'acceptation :** deux runs consécutifs diffèrent à cause du premier.

### W8 — Localisation *(P2)*

Propriétaire : `localization-lead`.

Toute chaîne destinée au joueur hors du code, dans le système de locale. Le
français est la langue source ; l'anglais est la première traduction.

---

## 5. Non-négociables

- **Art :** `design/art/art-bible.md` fait loi tant que l'`art-director` ne l'a
  pas changée, et un changement est une modification de document avec preuve,
  pas une exception discrète. Silhouette d'abord, trois tons + un accent, encre
  2 px, lumière en haut à gauche.
- **Piloté par les données :** les valeurs de gameplay vivent dans des
  ressources `.tres` sous `data/`. Aucun nombre magique dans les scripts.
- **Protocole de collaboration :** question → options → décision → brouillon →
  approbation. Demandez avant d'écrire un fichier. Une question sautée n'est pas
  un oui.
- **Aucun commit** sans instruction explicite de l'utilisateur. Aucun push.
- **Rien en amont :** ne jamais ouvrir, créer ni commenter une issue ou une PR
  dans un dépôt de moteur, de plugin ou de fournisseur.
- **Preuve :** tout ce qui est observable par le joueur laisse une capture
  retenue dans `production/qa/evidence/`. Un contrôle de syntaxe n'est pas un
  run.
- **Fichiers de scène :** ne jamais éditer à la main `format=`, `id`, `uid=` ;
  lancer `godot --headless --path . --import` après toute édition manuelle.
- **Godot 4.7.2 est postérieur à vos données d'entraînement.** Consultez
  `docs/engine-reference/godot/` avant d'utiliser une API dont vous n'êtes pas
  certain.

---

## 6. Comment travailler

```bash
GODOT="C:/Users/balthazar/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe"

# lancer le jeu
"$GODOT/Godot_v4.7.2-stable_win64.exe" --path .

# réimporter après une édition manuelle de scène ou de ressource
"$GODOT/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --import

# vérifier (la suite actuelle ; W0 la remplace)
"$GODOT/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tools/verify_slice04.gd
```

- **Déléguez verticalement.** Producteur → lead de département → spécialiste.
  Parallélisez seulement quand les entrées de deux agents sont indépendantes.
- **Un chantier, un propriétaire.** Les propriétaires rendent compte en langage
  clair ; un chantier bloqué est remonté, jamais sauté en silence.
- **Prouvez-le.** Chaque « c'est fait » porte soit un test rouge puis vert, soit
  une capture qu'on a réellement regardée.
- **Séquence :** W0 d'abord (le document de concept bloque le design), puis
  W1 + W2 + W3 en parallèle, puis W4, puis W5 + W6 + W7 + W8.

---

## 7. Hors périmètre

- Multijoueur, réseau, classements.
- Mobile, tactile, certification console.
- Nouveau moteur ou réécriture de la couche de dessin.
- Pages de boutique, marketing, bandes-annonces.
- Tout ce qui obligerait l'utilisateur à acheter un pack d'assets sans demander.

---

## 8. Première action

`producer` : lisez ce brief contre le dépôt, puis produisez un découpage —
epics par chantier, stories par epic, propriétaires nommés, et l'ordre des
dépendances entre eux. Présentez-le à l'utilisateur pour approbation **avant**
qu'un agent n'écrive du code. Rien dans ce brief n'autorise un commit.
