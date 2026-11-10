# Comportements ennemis — règles, roster, télégraphies

> **Status**: In Design
> **Author**: game-designer (W1-E0), avec `art-director` (W1-E3) et `narrative-director` (libellés)
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Pilier 2 — Chaque ennemi pose une question différente (principal) ; Piliers 1 et 3 (secondaires)

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Socle data-driven (W1-E1)`, `Cerveaux (W1-E2)`, `Rencontres (W1-E4)`, `Armes (W2-E2)`, `Silhouettes (W1-E3)`

## Summary

Ce GDD fixe les **cinq comportements** de horde de Medieval Survivors — marcheur, chargeur, tireur, exploseur, invocateur — sur **six archétypes** (squelette, orc, loup maudit, plume, tache, copiste), leurs boucles d'état, leurs valeurs de tuning, leurs **annonces lisibles en silhouette**, et leur **calendrier d'apparition sur les dix vagues**. Il fournit le contrat que W1-E1 (socle), W1-E2 (cerveaux), W1-E4 (rencontres) et W1-E3 (art) implémentent. Règle directrice : **un comportement = une question = une silhouette = une annonce**.

---

## Overview

Une vague de Medieval Survivors doit se lire comme une page : chaque créature annonce ce qu'elle va faire avant de le faire, et la réponse demandée change d'une créature à l'autre. Le build actuel ne contient que des **marcheurs** — trois silhouettes qui avancent et infligent des dégâts de contact — et un boss qui télégraphie son slam. Ce GDD remplace cette uniformité par cinq comportements distincts, répartis sur six archétypes non-élites, sans changer l'arène, les dix vagues de 20 s, ni la visée automatique. Il définit pour chacun la boucle exacte (états, durées, portées, cadences, dégâts), l'annonce que le joueur doit pouvoir lire, et le moment où il entre dans la run. Les deux boss (`seigneur_squelette`, vagues 5 et 10) restent hors roster : ils sont élites, `spawn_weight = 0`, et ne comptent pas dans les cinq comportements.

---

## Player Fantasy

**Le joueur doit se sentir lecteur, pas réacteur.** La page dessine une intention avant de la frapper : le loup s'aplatit et trace sa ligne, la plume écrit un fil vers vous, la tache s'allume et son cercle se referme, le copiste ouvre des cercles d'encre. Comprendre l'image, c'est déjà gagner du temps ; agir au bon moment, c'est transformer la lecture en esquive, en priorité, en survie.

**Esthétiques MDA visées**

- **Challenge** (principale) : cinq questions tactiques distinctes — kiter, lire et esquiver, fermer la distance, tuer à temps, prioriser. La difficulté vient de la lecture et du placement, pas de barres de vie.
- **Discovery** (secondaire) : la première rencontre avec chaque comportement est un apprentissage ; la deuxième est un test.
- **Fantasy** (support) : le conte à l'encre — chaque ennemi est une figure dessinée, pas un archétype générique.

**Besoins SDT servis**

- **Compétence** : chaque annonce précède son effet d'au moins `telegraph` secondes, avec un retour lisible (ligne, fil, cercle). Le joueur sait *pourquoi* il a été touché ou pourquoi il a esquivé.
- **Autonomie** : les comportements créent des priorités concurrentes (le copiste qui invoque pendant qu'un loup charge). Le joueur choisit quoi tuer, où reculer, quand traverser une ligne. La visée reste automatique : le choix porte sur le placement et la priorité, conformément au Pilier 3.
- **Relatedness** : la page est un monde cohérent — les six figures se répondent (marcheurs de base, tireur qui écrit, copiste qui recopie, tache qui rature). Ce lien est visuel et fictionnel, pas narratif.

**Alignement piliers**

- **Pilier 2 — Chaque ennemi pose une question différente** : chaque comportement a une réponse propre ; aucun ajout n'est « un marcheur plus rapide ».
- **Pilier 1 — Chaque run est différent** : les déblocages échelonnés et les poids font que la composition d'une vague change au fil de la run.
- **Pilier 3 — Le joueur a toujours un choix qui compte** : chaque annonce laisse une fenêtre de réponse ; les états engagés (charge, visée, invocation) sont des engagements que le joueur peut exploiter.

**Tension signalée entre piliers (décision à confirmer en W1-E4).** Le Pilier 2 demande plusieurs questions simultanées ; à 60 ennemis, deux engagements inévitables au même instant peuvent produire une situation sans réponse, ce qui contredit le Pilier 3. Mitigation définie ici : plafonds de télégraphies simultanées, déblocages espacés, suppression de l'invocation pendant un duel de boss. W1-E4 doit valider qu'aucune vague ne combine deux engagements **inesquivables** ; si c'est le cas, c'est le calendrier qui change, pas l'annonce.

---

## Detailed Rules

### 1. Modèle de comportement et contrat

**Identifiants de comportement.** Cinq valeurs stables, en anglais `snake_case`, jamais renommées :

| `behavior` id | Archétypes | Question |
|---|---|---|
| `walker` | squelette, orc | Sais-tu kiter ? |
| `charger` | loup_maudit | Sais-tu lire et esquiver ? |
| `ranged` | plume | Sais-tu fermer la distance ? |
| `exploder` | tache | Sais-tu le tuer à temps ? |
| `summoner` | copiste | Sais-tu prioriser ? |

**Portage des données.** Chaque archétype porte `EnemyData.behavior` (ajouté par W1-E1) et les paramètres de son comportement. W1-E1 choisit la forme exacte (champs à plat sur `EnemyData` ou sous-ressource `BehaviorData`) ; ce GDD ne tranche pas l'implémentation, il fixe les **noms, valeurs par défaut et plages** que l'implémentation doit exposer. Aucun de ces nombres ne vit dans un script : ils vivent dans `data/enemies/*.tres` (brief §5, non-négociable data-driven).

**États et engagement.** Chaque cerveau expose au minimum :

- `approach` (ou `reposition`) : mouvement libre vers/autour de la cible ;
- un ou plusieurs états **engagés** (`committed`) : `charge_windup`, `charging`, `aim`, `fuse`, `summon_windup` ;
- `recovery` : fin d'action, vulnérable ;
- retour à `approach` après cooldown.

Pendant un état engagé, sauf `fuse`, le cerveau est **enraciné** : le manager saute son déplacement, comme il le fait déjà pour le slam du boss (`Enemy.is_telegraphing()`). **Pendant tout état engagé, le recul est ignoré** (`knockback_resistance` effectif = 1) : une annonce est un engagement, pas une décoration que le joueur annule en frappant. Hors engagement, le recul existant s'applique normalement.

**Contexte fourni par W1-E1.** `BehaviorContext` doit exposer au minimum : position du joueur, `wave_index`, `is_boss_wave`, `boss_alive`, nombre d'ennemis vivants, `max_alive`, `delta`, et la source aléatoire seedée. Les cerveaux ne lisent ni le nœud `main.gd` ni des singletons.

**Collisions.** Aucune collision corps-à-corps entre ennemis n'existe aujourd'hui : les ennemis se traversent, y compris le boss. Ce GDD conserve ce choix (coût et lisibilité à 60 ennemis). Seule la **bordure de l'arène** (`Player.PLAY_RECT`) arrête un déplacement scripté — cas traité pour le chargeur.

**Dégâts de contact.** Le cooldown de contact reste celui de `RunConfig.contact_cooldown` (1,0 s par défaut) pour tous les archétypes. Une attaque spéciale (charge, détonation) a son propre chemin de dégâts et son propre cooldown, décrits plus bas.

**Contrat de télégraphie.** Le cerveau ne dessine rien : il demande une forme à `BehaviorTelegraph` (W1-E1) avec une durée, une origine et une géométrie. Les quatre formes sont définies au §8. Une annonce commence toujours **avant** la résolution de l'action, jamais sur la même image.

### 2. Roster cible

Six archétypes non-élites, cinq comportements. Valeurs de combat existantes conservées pour les trois archétypes du build ; les trois nouveaux sont spécifiés ici.

| id stable | Libellé de travail (source fr, proposition narrative) | Comportement | PV | Vitesse | Rayon | Contact | XP | `spawn_weight` | `unlock_wave` (index) | Vague |
|---|---|---|---|---|---|---|---|---|---|---|
| `squelette` | Squelette | `walker` | 20 | 70 | 13 | 8 | 1 | 1,0 | 0 | 1 |
| `loup_maudit` | Loup maudit | `charger` | 8 | 130 | 11 | 6 | 1 | 0,8 | 2 | 3 |
| `orc` | Orc | `walker` | 56 | 55 | 20 | 14 | 2 | 0,5 | 4 | 5 |
| `plume` | la Plume | `ranged` | 14 | 85 | 12 | 4 | 1 | 0,7 | 3 | 4 |
| `tache` | la Tache | `exploder` | 20 | 100 | 14 | 5 | 3 | 0,6 | 5 | 6 |
| `copiste` | le Copiste | `summoner` | 90 | 55 | 22 | 10 | 5 | 0,25 | 7 | 8 |

**Hors roster.** `seigneur_squelette` (`is_elite = true`, `spawn_weight = 0`) reste le boss des vagues 5 et 10, paliers 0 et 1. Il n'est jamais pioché par le spawner normal et ne compte pas dans les cinq comportements. Son slam (`0,85 s`, rayon 96, 22 dégâts) est l'annonce de référence du jeu : les nouvelles annonces doivent se lire au moins aussi clairement, pas le imiter.

**Silhouettes — ce que le joueur doit lire (à dessiner en W1-E3)**

- **Squelette** : étroit, vertical, crâne rond, côtes. Aucun accent coloré ; les yeux sont deux creux d'encre.
- **Orc** : large et bas, épaules en deux cercles hors du torse, défenses en triangles d'os. La seule masse verte.
- **Loup** : seul quadrupède, seul gris froid ; corps bas, museau long, queue latérale. **Aucune corne.**
- **Plume** : fin, plus petit que le squelette, capuche **pointue** (pas de crâne rond), un long bâton tenu en diagonale qui casse le contour vertical. Le seul ennemi dont la silhouette contient une longue ligne diagonale.
- **Tache** : ronde et asymétrique — une goutte d'encre avec des lobes, pas un cercle propre ; un cœur lumineux. Aucun membre. Le seul ennemi sans membre visible.
- **Copiste** : grand, large d'épaules, encapuchonné, un lutrin ou un grand cahier ouvert tenu devant lui ; masse horizontale basse. Distinct du boss (pas de couronne, pas de cape, pas de personnel) et de la Plume (large vs fin).

**Ce que le joueur doit faire, par archétype**

| Archétype | Ce qu'il doit lire | Ce qu'il doit faire |
|---|---|---|
| Squelette | La masse qui avance | Bouger, ne pas se laisser encercler |
| Loup | Le corps s'aplatit, une ligne se trace | Sortir de la ligne avant le départ |
| Orc | La masse lente et large | Gagner du terrain, l'user à distance |
| Plume | Un fil d'encre se tend vers soi | Continuer à bouger ; fermer la distance pendant la visée |
| Tache | Une lueur, un cercle qui se referme | La tuer avant la fin de la mèche, ou fuir perpendiculairement |
| Copiste | Des cercles d'encre s'ouvrent au sol | Le tuer en priorité, ou accepter des marcheurs sans XP |

### 3. Le marcheur — squelette et orc

**Boucle.** `approach` en permanence : avance vers la position du joueur à `move_speed` (70 squelette, 55 orc). Aucun état engagé, aucun cooldown, aucune action spéciale. Dégâts de contact : `contact_damage` (8 / 14), une fois par `contact_cooldown` (1,0 s).

**Annonce.** **Aucune forme dessinée.** L'annonce du marcheur est **continue** : sa silhouette et la direction de son déplacement disent tout. C'est la décision que le game-concept laissait ouverte à W1-E0 — elle libère les quatre formes graphiques pour les quatre comportements actifs. Un marcheur ne ment jamais : il n'a pas de coup spécial à cacher.

**Ce que le joueur doit lire.** Le nombre, la direction, la pince. Un marcheur seul est inoffensif ; trente marcheurs sont un mur. Le danger du marcheur est la **densité**, pas la surprise.

**Pourquoi ce n'est pas un ennemi raté.** Sa question est réelle (kiter, ne pas se laisser coincer) et il reste le ciment des vagues : les cinq autres comportements ont besoin d'une base nombreuse et bon marché pour exister. Il ne doit jamais recevoir d'annonce graphique — un marcheur qui télégraphie brouillerait la lecture des quatre vrais engagements.

### 4. Le chargeur — loup maudit

**Fantasy.** Une bête basse qui se ramasse, trace une ligne, puis traverse l'écran. La malédiction se lit dans le gris froid, pas dans une corne.

**Boucle d'état**

1. **`approach`** : avance vers le joueur à `move_speed` 130. Si la distance au joueur est dans la fenêtre `[charge_acquire_min, charge_acquire_max]` = `[70, 260]` px et que `charge_cooldown` est écoulé, entre en `charge_windup`.
2. **`charge_windup`** (0,60 s, enraciné, recul ignoré) :
   - le loup s'aplatit (posture) ;
   - **la direction est verrouillée à l'instant de départ** vers la position du joueur ;
   - une **bande au sol** (`band`, §8) est tracée de son centre le long de cette direction, longueur `charge_distance` 320 px, largeur `2 × (radius + Player.RADIUS)` = 50 px ;
   - à la fin de l'annonce, la bande disparaît et l'état passe à `charging`.
3. **`charging`** : avance à `charge_speed` 560 px/s sur la direction verrouillée, pendant `charge_distance / charge_speed` = 0,571 s, ou jusqu'à :
   - **toucher le joueur** : si la distance centre-à-centre ≤ `radius + Player.RADIUS` = 25 px pendant la charge, inflige `charge_damage` 14 **une seule fois par charge**, puis passe en `recovery` ;
   - **toucher la bordure** de `Player.PLAY_RECT` : s'arrête à la bordure, passe en `recovery` avec `wall_stun_bonus` 0,30 s ajouté.
4. **`recovery`** (0,60 s, enraciné, recul ignoré) : vulnérable.
5. Retour à `approach` ; `charge_cooldown` 2,40 s (±15 % de gigue par instance) démarre à la **fin** du `recovery`.

**Cycle complet.** 0,60 + 0,57 + 0,60 + 2,40 ≈ 4,17 s entre deux départs de charge (hors temps d'approche). Cible : 3,5–5,0 s. La gigue ±15 % désynchronise les loups d'une même vague ; sans elle, une meute charge en cadence et produit un mur de lignes.

**Règles dures**

- Le loup **ne charge pas** si le joueur est à moins de 70 px : il mord (contact) et continue d'approcher. Une charge à bout portant serait illisible.
- La direction verrouillée ne se réactualise **jamais** pendant la charge : le joueur qui quitte la ligne est en sécurité. C'est la récompense de lecture.
- Si le joueur est derrière le loup au début de l'annonce, le loup pivote instantanément (pas de temps de rotation) puis s'aplatit. L'annonce reste lisible parce qu'elle dure 0,60 s.
- **Plafond de télégraphies** : au plus `charger_max_concurrent_windups` = 2 loups peuvent être en `charge_windup` ou `charging` en même temps. Les autres restent en `approach` et retentent ; ce plafond ne supprime jamais une bande déjà tracée.
- **Bordure** : la charge s'arrête à la bordure, jamais au-delà. Le `wall_stun_bonus` est la fenêtre de punition du placement : coller le joueur à la bordure pour provoquer une charge ratée est un choix qui compte.
- **Boss et autres ennemis** : le loup les traverse (aucune collision). Si le joueur se cache derrière le boss, la charge le touche quand même. C'est assumé et documenté.

**Ce que le joueur doit lire.** La posture basse **et** la ligne. La ligne seule suffit si elle est visible ; la posture est le second signal pour la vision périphérique et le daltonisme (géométrie + mouvement, jamais la couleur seule).

### 5. Le tireur — la Plume

**Fantasy.** Une figure fine, encapuchonnée, qui écrit un fil vers vous et le ponctue d'une goutte d'encre. Elle ne vous attaque pas : elle vous **souligne**.

**Boucle d'état**

1. **`reposition`** : garde une bande de distance `[ranged_band_min, ranged_band_max]` = `[180, 320]` px.
   - distance < 180 : recule à `retreat_speed` 110 px/s ;
   - distance > 320 : avance à `move_speed` 85 px/s ;
   - distance dans la bande : s'arrête (ou micro-ajuste) et attend `shot_interval` 2,60 s.
2. **`aim`** (0,65 s, enraciné, recul ignoré) : cesse de bouger ; un **fil vivant** (`thread`, §8) part de son bâton et **suit la position du joueur** pendant toute la visée.
3. **Tir** : à la fin de `aim`, un projectile ennemi part vers la position du joueur **à cet instant**, à `bolt_speed` 260 px/s, dégâts `bolt_damage` 8, rayon 5, durée de vie 1,6 s (portée effective 416 px, au-delà de la bande haute).
4. **`recovery`** 0,20 s, puis retour à `reposition`. `shot_interval` redémarre au tir.

**Règles dures**

- **Le fil suit, le projectile ne vise pas le futur.** Le tir part vers la position actuelle du joueur ; il ne mène pas la cible. Un joueur qui bouge en continu esquive ; un joueur immobile est touché. C'est la question « sais-tu fermer la distance **en bougeant** ? ».
- **La visée immobilise la Plume** : c'est la fenêtre où le joueur gagne du terrain (110 px/s de fermeture pendant 0,65 s = 71 px).
- **Coinçage** : si la Plume recule contre la bordure, elle s'arrête à la bordure et continue de tirer à bout portant. Le joueur qui la coince est récompensé ; elle ne traverse pas le décor.
- **Fil non dessiné au-delà de 6 tireurs** : si plus de `ranged_max_drawn_threads` = 6 Plumes visent simultanément, seules les 6 plus proches du joueur dessinent leur fil. Les autres tirent quand même : le projectile reste visible et lent, donc la règle ne crée pas d'attaque invisible. Les bandes du chargeur, elles, ne sont jamais supprimées.
- **Contact** : 4 dégâts, faible. La Plume déteste la mêlée ; c'est voulu.

**Ce que le joueur doit lire.** Le fil et l'immobilité. Une Plume qui ne bouge pas est une Plume qui vise. Le projectile est une goutte d'encre, pas un trait de lumière.

### 6. L'exploseur — la Tache

**Fantasy.** Une goutte d'encre qui s'épaissit, s'allume et rature la page autour d'elle. Rond, luisant, sans membre — la seule figure du roster qui n'a pas de corps articulé.

**Boucle d'état**

1. **`approach`** : avance vers le joueur à `move_speed` 100 px/s.
2. **`fuse`** — déclenché quand la distance centre-à-centre ≤ `fuse_trigger_radius` 120 px :
   - le corps pulse en rouge danger ;
   - un **anneau qui se referme** (`ring_closing`, §8) de rayon `blast_radius` 65 px est dessiné sur le sol, ancré à la Tache ;
   - la Tache accélère à `fuse_speed` 245 px/s et **suit** le joueur ;
   - elle s'arrête à `radius + Player.RADIUS` = 28 px du joueur (elle ne le traverse pas) ;
   - durée `fuse_time` 1,00 s, **non enracinée** (elle bouge) et recul ignoré.
3. **Détonation** à la fin de la mèche : si la distance centre-à-centre ≤ `blast_radius + Player.RADIUS` = 79 px, inflige `blast_damage` 18. La Tache meurt ; **elle ne laisse pas de gemme d'XP** (auto-détonation = 0 XP).
4. **Morte avant la détonation** : si des dégâts létaux sont appliqués **avant** la résolution de la mèche dans l'image, la détonation est **annulée**, aucune zone n'est créée, et elle meurt normalement en laissant ses 3 XP.

**Règles dures**

- **Fuite directe = survie de justesse.** Le joueur à 220 px/s, la Tache à 245 : fermeture 25 px/s sur 1,0 s = 25 px. Départ à 120 px → 95 px à la détonation, au-delà de 79 px. Il faut donc **bouger**, pas seulement être rapide. Un joueur immobile ou acculé est touché (distance finale 28 px).
- **Fuir perpendiculairement** ou casser sa ligne est meilleur que fuir tout droit ; c'est la réponse propre.
- **Pas de dégâts aux autres ennemis en v1** (`explosion_friendly_fire = 0,0`). La détonation ne crée pas de réaction en chaîne, ne vide pas une vague et ne devient pas une stratégie de ferme. La valeur est exposée en knob (0,0–0,5) pour une décision ultérieure, jamais activée par défaut.
- **Dégâts létaux en même temps que la mèche** : l'ordre est **dégâts d'abord, mèche ensuite**. Un exploseur tué à 1 px de la fin ne détone pas.
- **Plusieurs Taches** : chacune a sa mèche et sa détonation ; les dégâts se cumulent. Aucun plafond global — les anneaux sont la contre-mesure, et un joueur qui se tient hors des 79 px ne craint rien.
- **Contact pendant la mèche** : 5 dégâts, cooldown standard. Une Tache collée peut infliger contact + détonation ; c'est la punition de l'immobilité.

**Ce que le joueur doit lire.** La lueur (corps) et l'anneau qui se referme (géométrie + temps). L'anneau **se referme**, contrairement au disque du boss qui **grandit** : deux directions de mouvement opposées, aucune confusion possible.

### 7. L'invocateur — le Copiste

**Fantasy.** Une grande figure qui recopie la page : elle ouvre des cercles d'encre et en fait sortir les figures les plus simples — des squelettes. Elle ne crée rien de nouveau ; elle **répète**.

**Boucle d'état**

1. **`approach`** : avance lentement vers le joueur à `move_speed` 55 px/s. Il ne fuit pas et ne kite pas : sa menace est la durée, pas la mobilité.
2. **`summon_windup`** — déclenché après `initial_summon_delay` 2,00 s puis toutes les `summon_interval` 6,00 s, **si** la place le permet (voir règles dures) :
   - enraciné, recul ignoré ;
   - deux **anneaux qui s'ouvrent** (`ring_opening`, §8) de rayon 24 px apparaissent à `summon_radius` 100 px de lui, à ±60° de sa direction de regard ;
   - durée `summon_telegraph` 0,90 s.
3. **Résolution** : si le Copiste est encore vivant, `summon_count` 2 squelettes apparaissent dans les cercles. Ce sont des **marcheurs** (`walker`), PV 20, vitesse 70, contact 8, **XP 0**, et ils **comptent dans `max_alive`**.
4. **`recovery`** 0,30 s, puis retour à `approach`. Le prochain `summon_interval` démarre à la résolution.

**Règles dures**

- **Morte pendant l'invocation = invocation annulée.** Si le Copiste meurt pendant `summon_windup`, les cercles disparaissent, aucun squelette n'apparaît. C'est la récompense de la priorisation.
- **XP 0 pour les invoqués.** Sinon, ignorer le Copiste et farmer ses squelettes serait la meilleure stratégie de la run. Un invoqué ne nourrit jamais la montée de niveau.
- **Les invoqués comptent dans `max_alive`.** Ils **remplacent** des spawns normaux au lieu de s'y ajouter : un Copiste ne fait pas grossir la population, il en **retire les porteurs d'XP**. C'est ce qui rend « prioriser » économiquement réel et empêche l'emballement.
- **Refus si le plafond est atteint.** Au début de `summon_windup`, si `alive_count + summon_count > max_alive`, le Copiste **n'ouvre pas** de cercle et retente après `summon_retry_delay` 1,50 s. On ne dessine jamais une annonce qui ne peut pas se résoudre.
- **Points de spawn invalides.** Un cercle hors de `Player.PLAY_RECT` est ramené à l'intérieur (marge = rayon du squelette). Un cercle à moins de `Player.RADIUS + squelette.radius + 4` px du joueur est déplacé de l'autre côté. Si un seul point reste valide, **un seul** squelette apparaît ; si aucun, l'invocation est refusée et retentée. Jamais de spawn dans le joueur.
- **Vague de boss.** Tant que le boss est vivant, le Copiste **n'invoque pas** (l'intervalle est suspendu, pas consommé). Si le boss meurt avant la fin de la vague, l'invocation reprend. Le duel reste un duel ; les squelettes invoqués ne doivent pas enterrer l'annonce du slam.
- **Plusieurs Copistes** : chacun a son cycle et son compteur ; le plafond `max_alive` est global et arbitre. Aucun plafond par instance n'est nécessaire puisque les invoqués comptent dans le plafond global.
- **Le Copiste invoque toujours des squelettes.** Jamais de loup, de Plume, de Tache ou d'autre Copiste : pas de récursion, pas de composition imprévisible.

**Ce que le joueur doit lire.** La taille, la capuche, le lutrin, et les deux cercles d'encre au sol. Sa lenteur est l'invitation à venir le tuer ; sa vie élevée (90 PV) est le prix de la réponse.

### 8. Les quatre annonces — langage de silhouette

Quatre formes graphiques seulement, toutes dessinées avec l'encre de **danger** `Color(0.75, 0.20, 0.14)` de la bible d'art, opacité 0,22–0,55 comme le disque du boss. La **géométrie et le mouvement** portent le sens ; la couleur ne fait que confirmer (règle daltonisme de la bible). Le marcheur n'a **aucune** forme dessinée (§3).

| Forme | Comportement | Géométrie | Mouvement | Durée | Ce que ça dit |
|---|---|---|---|---|---|
| `band` — la bande | Chargeur | Rectangle au sol, largeur 50 px, longueur 320 px, ancré au loup et orienté vers la position verrouillée | **Statique** une fois tracée | 0,60 s | « Je partirai exactement ici ; sors de la bande » |
| `thread` — le fil | Tireur | Ligne de 2 px du bâton à la position du joueur | **Suit** le joueur pendant la visée | 0,65 s | « Je vise là où tu es ; bouge » |
| `ring_closing` — l'anneau qui se referme | Exploseur | Anneau au sol de rayon 65 px, centré sur la Tache | Le trait se **referme** vers le centre (le rayon diminue visuellement, l'aire de danger reste 65 px) | 1,00 s | « Le temps s'écoule ; sors des 79 px » |
| `ring_opening` — l'anneau qui s'ouvre | Invocateur | Deux anneaux de rayon 24 px à 100 px du Copiste, ±60° | Le remplissage **s'ouvre** vers l'extérieur (ou le trait se complète) | 0,90 s | « Quelque chose va sortir d'ici ; tue-moi ou recule » |

**Règles d'art transmissibles à W1-E3**

- Quatre formes, quatre mouvements distincts : statique, suiveur, refermant, ouvrant. Aucune ne partage son mouvement avec le disque **grandissant** du boss.
- Toutes se dessinent **sous** les acteurs (`show_behind_parent`), sur l'herbe, avec l'ombre au sol existante.
- La bande du chargeur et le fil du tireur sont les deux seules formes **linéaires** ; elles diffèrent par l'épaisseur (50 px vs 2 px) et par le mouvement (statique vs suiveur). C'est la distinction que W1-E3 doit rendre évidente à 100 %.
- L'annonce du Copiste est la seule forme **multiple** (deux cercles) : le nombre fait partie du sens.
- Aucune forme ne clignote au point de devenir illisible ; la pulsation du corps de la Tache est un signal **corporel**, pas la forme au sol.
- Revue d'art obligatoire avant implémentation (W1-E3) : les quatre formes plus les trois silhouettes nouvelles, à 100 % sur l'herbe, avec revue daltonisme (W1-E5).

### 9. Calendrier d'apparition sur les dix vagues

Dix vagues de 20 s, boss aux vagues **5** et **10** (indices 4 et 9, `boss_every_waves = 5`). `unlock_wave` est un **index 0-based** comparé par `Spawner.pick_enemy()` : `wave_index < unlock_wave` ⇒ non piochable. Le tableau donne la vague **1-based** et l'index.

| Vague | Index | Intervalle de spawn (s) | `max_alive` | Roster débloqué (cumulatif) | Thème de la vague |
|---|---|---|---|---|---|
| 1 | 0 | 1,400 | 18 | squelette | Installation : la masse |
| 2 | 1 | 1,232 | 24 | squelette | Installation : la densité |
| 3 | 2 | 1,084 | 30 | + loup_maudit | Première ligne : lire le chargeur |
| 4 | 3 | 0,954 | 36 | + plume | Premier fil : bouger pour survivre |
| **5 — SEIGNEUR** | 4 | **1,343** (×1,6) | 42 | + orc | Duel du milieu + orcs lents |
| 6 | 5 | 0,739 | 48 | + tache | Première mèche : tuer à temps |
| 7 | 6 | 0,650 | 54 | — | Approfondissement : mélange |
| 8 | 7 | 0,572 | 60 | + copiste | Première invocation : prioriser |
| 9 | 8 | 0,503 | 66 | — | Ascension : densité maximale |
| **10 — SEIGNEUR** | 9 | **0,709** (×1,6) | 72 | roster complet | Dernière page, palier 1 |

**Lecture.** L'intervalle suit `WaveData` : `1,4 × 0,88^index`, plancher 0,22 s, ×1,6 sur une vague de boss. Aucune valeur de ce GDD ne remplace `WaveData` ; le calendrier le cite pour que l'équipe puisse vérifier que les déblocages tombent aux bons moments. `max_alive = 18 + 6 × index`.

**Poids et parts attendues.** Poids de base dans `data/enemies/*.tres` (colonne `spawn_weight` du §2). Part d'un archétype à une vague : `poids / somme des poids débloqués`. Le poids n'est pas modifié par la vague ; W1-E4 peut ajouter des multiplicateurs par vague dans les données de rencontres, mais le **poids de base** reste celui-ci.

| Vague | Archétypes débloqués | Somme des poids | Parts attendues |
|---|---|---|---|
| 1–2 | squelette | 1,00 | squelette 100 % |
| 3 | squelette, loup | 1,80 | 55,6 % / 44,4 % |
| 4 | + plume | 2,50 | 40,0 % / 32,0 % / 28,0 % |
| 5–6 | + orc, + tache (W6) | 3,60 | 27,8 % / 22,2 % / 19,4 % / 13,9 % / 16,7 % |
| 7 | idem | 3,60 | idem |
| 8–10 | + copiste | 3,85 | 26,0 % / 20,8 % / 18,2 % / 13,0 % / 15,6 % / 6,5 % |

**Ordre des déblocages — pourquoi.**

- **Vague 3, le loup** : première question active, la plus simple à lire (une ligne, une posture). Il enseigne le vocabulaire des annonces.
- **Vague 4, la Plume** : deuxième question active, sans dégât de zone ; elle apprend à bouger pendant qu'on attaque.
- **Vague 5, l'orc** : existant, inchangé. Il débloque sur la vague du premier boss (index 4) parce que `unlock_wave = 4` dans `orc.tres`. C'est une **tension existante** signalée au rapport : les orcs apparaissent pendant le duel du Seigneur. Le GDD ne la corrige pas (le calendrier doit rester cohérent avec les données existantes) ; si W1-E4 veut un duel pur, il déplace l'orc à l'index 3 (vague 4) avec l'accord du game-designer.
- **Vague 6, la Tache** : après le premier boss, quand le joueur a un build et peut choisir de tuer ou de fuir.
- **Vague 8, le Copiste** : dernière question, la plus abstraite (priorité, économie d'XP). Il n'entre qu'une fois les quatre autres lues.

### 10. Garanties de mélange

Le tirage pondéré seul ne garantit rien : une run pourrait traverser une vague sans montrer son nouvel ennemi. Deux règles, implémentées par W1-E4, rendent le critère d'acceptation testable :

1. **Garantie de déblocage.** Sur la vague de déblocage d'un archétype, les **deux premiers spawns admis** de la vague sont forcés sur cet archétype ; sur une vague de boss, **le premier seulement** (le duel reste lisible). « Admis » = effectivement instancié, pas un tick refusé par `max_alive`. Une garantie non remplie est reportée aux vagues suivantes jusqu'à satisfaction, **jamais avant sa vague de déblocage**.
2. **Aucune suppression avant déblocage.** Un archétype ne peut jamais être pioché avant son `unlock_wave`, garantie comprise. C'est la règle dure du spawner existant.

**Conséquence sur le critère « ≥ 4 comportements distincts par run ».** Une run complète (jusqu'à la vague 10) voit obligatoirement : `walker` (vague 1), `charger` (vague 3), `ranged` (vague 4), `exploder` (vague 6), `summoner` (vague 8) — soit **cinq** comportements. La garantie ne dépend pas du hasard. Un run qui s'arrête avant la vague 6 ne prouve rien et ne doit pas servir de test.

### 11. Né localisé

Chaque nom et chaque description est une **clé**, jamais une chaîne affichable en dur. Convention (standard W8-E1, en cours d'écriture) :

- `enemy.<id>.name` — nom affiché ;
- `enemy.<id>.desc` — description (bestiaire, écran futur, info-bulle) ;
- `<id>` est l'`EnemyData.id` stable, jamais `display_name`.

| id | Clé nom | Clé description | Libellé de travail (source fr, **proposition narrative**, jamais dans le code) |
|---|---|---|---|
| `squelette` | `enemy.squelette.name` | `enemy.squelette.desc` | Squelette |
| `loup_maudit` | `enemy.loup_maudit.name` | `enemy.loup_maudit.desc` | Loup maudit |
| `orc` | `enemy.orc.name` | `enemy.orc.desc` | Orc |
| `plume` | `enemy.plume.name` | `enemy.plume.desc` | la Plume |
| `tache` | `enemy.tache.name` | `enemy.tache.desc` | la Tache |
| `copiste` | `enemy.copiste.name` | `enemy.copiste.desc` | le Copiste |
| `seigneur_squelette` | `enemy.seigneur_squelette.name` | `enemy.seigneur_squelette.desc` | Seigneur squelette |

**Règles.**

- `EnemyData.display_name` ne doit **jamais** être rendu tel quel : W1-E1 ajoute `name_key` et `desc_key` (ou remplace `display_name` par la clé — la forme appartient à W8-E1/W1-E1, la règle est : aucune chaîne affichable dans la ressource).
- Repli : français (langue source du brief W8), anglais en première traduction. Une clé absente affiche le français.
- Les libellés `la Plume`, `la Tache`, `le Copiste` sont des **propositions** du game-concept reprises ici comme noms de travail ; `narrative-director` peut les changer sans casser les données, car seules les clés et les `id` sont stables.
- Aucun texte de télégraphie n'est affiché : les annonces sont graphiques. Aucune clé `enemy.<id>.telegraph` n'est requise.

### 12. Interactions avec les autres systèmes

| Système | Ce que ce GDD fournit | Ce qu'il exige |
|---|---|---|
| **W1-E1 — socle data-driven** | Les 5 `behavior` ids, les 4 formes d'annonce, les paramètres et leurs plages, le contrat « état engagé = enraciné + recul ignoré » | `EnemyData.behavior`, `BehaviorTelegraph` (4 formes), `BehaviorContext` (`player_position`, `wave_index`, `is_boss_wave`, `boss_alive`, `alive_count`, `max_alive`, `rng`, `delta`), un chemin de dégâts de zone pour la détonation |
| **W1-E2 — cerveaux** | Les boucles exactes des 5 comportements, les états, les durées et les annulations | `WalkerBehavior`, `ChargerBehavior`, `RangedBehavior`, `ExploderBehavior`, `SummonerBehavior`, `EnemyBolt` + gestionnaire de projectiles ennemis |
| **W1-E4 — rencontres** | Le calendrier, les poids, les garanties de mélange | Les garanties, la composition par vague, le respect de `unlock_wave`, la suppression de l'invocation pendant un boss vivant |
| **W2-E2 — armes** | Les fenêtres de vulnérabilité (recovery) et l'annulation de la détonation par dégâts létaux | Que les armes endommagent via le chemin `take_damage` existant, sans effet qui contourne l'ordre « dégâts avant mèche » |
| **W1-E3 — art** | Le langage des 4 annonces et les 3 silhouettes nouvelles + le loup sans cornes | Bible d'art amendée avant implémentation ; captures dans `production/qa/evidence/` |
| **W2-E1/E2 — données armes** | Aucun | Rien |
| **W5-E1/E2 — audio** | Les événements à sonoriser : départ de bande, fil tendu, mèche, cercles d'invocation | Un signal par début d'annonce et un par résolution, pas un son par image |
| **W4-E1/E2 — économie** | XP : 1 / 1 / 2 / 1 / 3 / 5, invoqués 0 ; aucun or | Aucune monnaie dorée dans les gouttes ; les invoqués ne produisent pas de gemme |
| **W8-E1/E2 — localisation** | Les clés `enemy.<id>.name` / `.desc` | Le standard de clés et le repli fr ; extraction après gel des chaînes |

---

## Formulas

Toutes les variables sont des valeurs de ressource ou des dérivées. Plages = valeurs sûres pour le tuning ; défaut = valeur livrée.

### F1 — Intervalle de spawn (existante, `WaveData`)

```
I(w) = max(base_spawn_interval × interval_decay_per_wave^w, min_spawn_interval)
I_boss(w) = I(w) × boss_spawn_interval_scale
```

- `w` : index de vague (0–9) ; `base_spawn_interval = 1,4` ; `interval_decay_per_wave = 0,88` ; `min_spawn_interval = 0,22` ; `boss_spawn_interval_scale = 1,6`.
- Sortie : secondes entre deux ticks de spawn. Plage utile : 0,22–1,40 s (hors boss 1,34–1,53 s aux vagues concernées).
- Exemple : `I(5) = 1,4 × 0,88^5 = 0,739 s` ; `I_boss(4) = 1,4 × 0,88^4 × 1,6 = 1,343 s`.
- Courbe : décroissance exponentielle monotone, pas de point d'inflexion. Le plancher 0,22 s n'est jamais atteint sur 10 vagues — il est un garde-fou pour une run endless.

### F2 — Plafond d'ennemis vivants (existante, `WaveData`)

```
A(w) = base_max_alive + alive_growth_per_wave × w
```

- Défauts : 18 + 6 × w → 18 (vague 1) à 72 (vague 10).
- Les invoqués comptent dans `alive_count` (règle §7) : `A(w)` est un plafond dur pour tout le monde.

### F3 — Probabilité de tirage pondérée (existante, `Spawner`)

```
P(i | w) = weight_i / Σ_{j débloqués à w} weight_j
```

- `weight_i = max(EnemyData.spawn_weight, 0)` ; les élites sont exclues ; `weight_i = 0` n'est jamais pioché.
- Exemple à la vague 8 : somme 3,85 ; `P(plume) = 0,7 / 3,85 = 18,2 %`.
- Contrainte de garantie : les `unlock_guarantee_count` premiers spawns **admis** de la vague de déblocage ignorent `P` (voir §10).

### F4 — Cinématique de la charge

```
T_charge = charge_distance / charge_speed
d_escape_perp = Player.RADIUS + enemy.radius + marge
t_perp = d_escape_perp / player_speed
```

- Défauts : `charge_distance = 320`, `charge_speed = 560` → `T_charge = 0,571 s`.
- `d_escape_perp` = 25 px + marge de sécurité (viser 30 px) ; `player_speed = 220` → `t_perp = 0,136 s`.
- Fenêtre de réaction : `charge_telegraph = 0,60 s`. Marge : `0,60 / 0,136 ≈ 4,4×` le temps nécessaire pour sortir de la bande. Le joueur peut donc esquiver **s'il lit** ; il ne peut pas esquiver s'il ne regarde pas.
- Exemple de portée : un joueur à 260 px au départ ; la charge couvre 320 px, donc elle le dépasse de 60 px s'il ne bouge pas.

### F5 — Mèche de l'exploseur et distance de détonation

```
k = fuse_speed − player_speed            (fermeture en fuite directe)
d_detonation = max(stop_distance, fuse_trigger_radius − k × fuse_time)
hit ⇔ d_detonation ≤ blast_radius + Player.RADIUS
```

- Défauts : `fuse_speed = 245`, `player_speed = 220` → `k = 25 px/s` ; `fuse_trigger_radius = 120` ; `fuse_time = 1,0` ; `stop_distance = 28` ; `blast_radius = 65` ; `Player.RADIUS = 14`.
- Fuite directe : `d_detonation = max(28, 120 − 25) = 95` ; seuil = `65 + 14 = 79` → **pas touché** (16 px de marge).
- Immobile : `d_detonation = 28` → **touché** (28 ≤ 79).
- Acculé : `d_detonation = 28` → **touché**.
- La marge de 16 px est volontairement mince : une fuite en diagonale ou un changement de direction augmente la marge ; rester sur place la supprime.

### F6 — Dégâts de détonation

```
damage = blast_damage  si distance(centre_tache, centre_joueur) ≤ blast_radius + Player.RADIUS
       0              sinon
```

- Pas de dégradé : le cercle est la vérité. `blast_damage = 18` (12–24).
- Plusieurs détonations dans la même image : somme des dégâts, chacune testée séparément.

### F7 — Cadence et temps de vol du tireur

```
tirs_par_seconde = 1 / shot_interval
bolts_en_vol = tireurs_actifs × bolt_lifetime / shot_interval
t_vol(d) = d / bolt_speed,  d ∈ [ranged_band_min, ranged_band_max]
```

- Défauts : `shot_interval = 2,60` → 0,385 tir/s par Plume ; `bolt_lifetime = 1,60` ; `bolt_speed = 260`.
- 5 Plumes actives → `5 × 1,60 / 2,60 = 3,08` projectiles en vol en moyenne.
- `t_vol(180) = 0,69 s` ; `t_vol(320) = 1,23 s`. Le joueur parcourt 152–271 px pendant le vol : bouger suffit à esquiver un tir non mené.

### F8 — Débit de l'invocateur

```
S = summon_count / summon_interval          (squelettes par seconde et par Copiste)
N_wave ≈ summon_count × floor((duration − initial_summon_delay) / summon_interval + 1)
```

- Défauts : `summon_count = 2`, `summon_interval = 6,0`, `initial_summon_delay = 2,0`, `duration = 20` → `S = 0,333 /s` ; `N_wave = 2 × floor(18/6 + 1) = 2 × 4 = 8` si le Copiste survit toute la vague.
- Ces 8 squelettes **remplacent** des spawns normaux dans `max_alive` ; ils n'ajoutent pas 8 corps au plafond. Ils retirent 8 porteurs d'XP potentiels.
- Contrainte : `alive_count + summon_count ≤ max_alive` au départ de l'annonce, sinon refus et retry 1,5 s.

### F9 — Temps pour tuer (référence, arme de départ)

Dégâts attendus par coup : `damage × (1 + crit_chance × (crit_multiplier − 1))`. Pour l'épée longue : `12 × (1 + 0,05 × 1) = 12,6` ; DPS `12,6 × 1,8 = 22,68`.

```
TTK = max_hp / DPS_attendu
```

| Cible | PV | TTK épée longue | Lecture |
|---|---|---|---|
| Tache | 20 | 0,88 s | Sous la mèche de 1,00 s **si** le joueur attaque déjà ; sinon fuir |
| Plume | 14 | 0,62 s | Deux coups ; la fermeture de distance est la vraie réponse |
| Loup | 8 | 0,35 s | Un coup ; le tuer avant le départ de la charge est possible |
| Copiste | 90 | 3,97 s | Engagement réel : on ne le tue pas « en passant » |
| Orc | 56 | 2,47 s | Référence existante |
| Squelette | 20 | 0,88 s | Référence existante |

- Cible de design : la Tache doit être tuable **dans la mèche** avec l'arme de départ si le joueur est déjà en train de l'attaquer (0,88 s < 1,00 s), mais pas si elle déclenche hors de portée. C'est exactement la tension « tuer à temps ».
- Si W2-E2 change les DPS, ces TTK se recalculent ; le ratio à préserver est `TTK_tache < fuse_time × 1,15`.

---

## Edge Cases

Chaque cas dit **ce qui se passe**, pas « gérer proprement ».

1. **L'invocateur meurt pendant l'invocation.** Les cercles disparaissent à l'image suivante ; aucun squelette n'apparaît ; aucune XP n'est perdue (elle n'existait pas). La mort létale est résolue avant la fin de `summon_windup`.
2. **L'exploseur est tué à 1 px de la détonation.** Ordre de résolution dans l'image : dégâts → mort → mèche. Si les dégâts sont létaux, la mèche est annulée, aucune zone, XP de mort normale (3). La mèche ne détone jamais un cadavre.
3. **L'exploseur détone sans joueur dans le rayon.** Aucun dégât ; il meurt quand même ; 0 XP (auto-détonation). Il ne laisse pas de gemme.
4. **Le chargeur percute la bordure de l'arène.** Il s'arrête à `Player.PLAY_RECT`, entre en `recovery` + `wall_stun_bonus` 0,30 s, puis cooldown normal. Aucun dégât supplémentaire.
5. **Le chargeur percute le boss ou un autre ennemi.** Rien : aucune collision ennemie n'existe. Il les traverse et continue sa charge. Si le joueur est derrière le boss, il est touché. Documenté, assumé.
6. **Plusieurs chargeurs chargent en même temps.** Au plus 2 en `charge_windup`/`charging` ; les autres restent en `approach` et retentent à leur prochain tick de cooldown. Les loups déjà en charge ne sont jamais interrompus par le plafond.
7. **Un ennemi est invoqué pendant une vague de boss.** Interdit tant que le boss est vivant : le Copiste ne commence pas d'invocation, l'intervalle est suspendu (pas consommé). Après la mort du boss, il reprend. Les squelettes déjà invoqués avant la vague survivent et combattent normalement.
8. **Le Copiste est bloqué par `max_alive` au début de son annonce.** Il n'ouvre pas de cercle ; retry après 1,5 s. Aucune annonce orpheline.
9. **Un des deux points d'invocation est hors arène ou sur le joueur.** Le point est ramené dans l'arène, puis déplacé de l'autre côté s'il chevauche le joueur ; si un seul point reste valide, un seul squelette apparaît ; si aucun, l'invocation est refusée et retentée.
10. **Le tireur est acculé contre la bordure.** Il s'arrête à la bordure, ne recule plus, continue de viser et de tirer. Le joueur peut le coincer et le tuer au corps à corps.
11. **Le joueur quitte la ligne du chargeur pendant l'annonce.** La ligne ne bouge pas ; la charge part quand même sur la direction verrouillée et manque. C'est la récompense de lecture.
12. **Le joueur est à moins de 70 px du loup quand le cooldown est prêt.** Pas de charge : le loup continue d'approcher et mord. Il ne déclenche `charge_windup` qu'à la sortie de la fenêtre basse.
13. **Le joueur frappe un ennemi en état engagé.** Le recul est ignoré pendant tout état engagé (`charge_windup`, `charging`, `aim`, `fuse`, `summon_windup`). Hors engagement, le recul existant s'applique. Les dégâts, eux, s'appliquent toujours.
14. **Deux Taches détonent dans la même image.** Les deux zones sont testées séparément ; les dégâts se cumulent (18 + 18 = 36 si le joueur est dans les deux). Aucune réaction en chaîne sur les autres ennemis (`explosion_friendly_fire = 0`).
15. **Une vague se termine pendant une charge ou une mèche.** L'ennemi persiste, l'état continue, la résolution se produit dans la vague suivante. Aucun timer n'est remis à zéro au changement de vague.
16. **Le joueur est dans un cercle d'invocation au moment de la résolution.** Le point a été déplacé au début de l'annonce ; si le joueur entre dans le cercle après coup, le squelette apparaît quand même et peut infliger du contact immédiatement (cooldown de contact normal).
17. **Un exploseur déclenche sa mèche alors que le joueur est invulnérable ?** Il n'existe pas d'invulnérabilité dans le build. Aucun cas à traiter ; si une source future en ajoute une, elle s'applique dans `take_damage`, pas dans le comportement.
18. **Valeurs de tuning absurdes.** Toute durée ≤ 0 est ramenée à 0,05 s ; toute portée/rayon < 0 à 0 ; `summon_count` borné à 1–3 ; `charge_distance` < 1 empêche la charge (le loup reste marcheur) ; `blast_radius = 0` désactive la détonation et la Tache meurt sans zone. Aucune division par zéro : `charge_speed` et `bolt_speed` sont des planchers à 1,0.
19. **Un archétype a `behavior` vide ou inconnu.** Il retombe sur `walker` (comme `ActorArt` retombe sur le squelette). Une faute de frappe produit un marcheur visible, jamais une exception.
20. **Le Copiste invoque alors que `max_alive` est déjà atteint par des invoqués.** Refus au départ de l'annonce, pas au moment du spawn : le compteur est vérifié avant de dessiner les cercles.
21. **Le loup est tué pendant `charge_windup`.** La bande disparaît avec lui ; aucune charge. La mort est résolue avant le départ de la charge.
22. **Le loup est tué pendant `charging`.** Il meurt, la charge s'arrête, aucune collision supplémentaire. Les dégâts de charge déjà appliqués ne sont pas retirés.

---

## Dependencies

### Dépendances amont (ce système exige)

| Système | Doc / epic | Contrat |
|---|---|---|
| Socle data-driven | W1-E1, `design/gdd/…` (ADR à venir) | `EnemyData.behavior`, `name_key`/`desc_key`, `BehaviorContext`, `BehaviorTelegraph` (4 formes), chemin de dégâts de zone |
| Cerveaux | W1-E2 | Implémente les 5 comportements décrits ici, y compris les annulations |
| Rencontres | W1-E4 | Applique le calendrier, les poids et les garanties de mélange |
| Silhouettes et annonces | W1-E3, `design/art/art-bible.md` | Dessine les 3 nouveaux archétypes, le loup sans cornes, les 4 formes |
| Armes | W2-E2 | Respecte l'ordre « dégâts avant mèche » et les fenêtres de recovery |
| Localisation | W8-E1, `docs/localization-standard.md` (à écrire) | Fournit le standard de clés et le repli fr |
| Audio | W5-E1/E2 | Sonorise les débuts d'annonce et les résolutions, pas les images |

### Dépendances aval (ce système fournit)

| Système | Ce qu'il reçoit |
|---|---|
| W1-E1 | La liste des `behavior` ids, les 4 formes, les noms de paramètres et leurs plages |
| W1-E2 | Les boucles d'état complètes, les durées, les cas d'annulation |
| W1-E4 | Le calendrier et les garanties ; la règle de suppression de l'invocation pendant un boss vivant |
| W1-E5 | Les comportements à capturer et le canary 60 ennemis / 2 ms |
| W2-E2 | Les fenêtres de vulnérabilité et l'annulation de détonation par dégâts létaux |
| W4-E1/E2 | Les valeurs d'XP et la règle « invoqué = 0 XP, jamais d'or » |
| W8-E2 | Les clés `enemy.<id>.name` / `.desc` |
| `design/gdd/systems-index.md` | Une ligne « Comportements ennemis », statut In Design |

### Contrat bidirectionnel vérifié

- `art-bible.md` mentionne le loup sans cornes et les annonces ; ce GDD les précise. **W1-E3 doit amender la bible avant l'implémentation** — la bible fait loi.
- `game-concept.md` §Bestiaire fournit le cadre et les noms de travail ; ce GDD les fige en `id` et en valeurs. Toute divergence de nom reste sans effet sur les données.
- `spawner.gd` / `EnemyData` fournissent `unlock_wave` et `spawn_weight` ; ce GDD ne les remplace pas, il les met en calendrier.
- `WaveData` fournit l'intervalle et `max_alive` ; ce GDD les cite et ne les duplique pas.

---

## Tuning Knobs

Tous les nombres vivent dans `data/enemies/*.tres` (ou la sous-ressource de comportement choisie par W1-E1), jamais dans un script. Catégories : **feel** (ressenti, réglé au playtest), **curve** (progression, réglé au calcul), **gate** (pacing, réglé par la durée de session).

### Marcheurs (squelette, orc) — existants

| Knob | Catégorie | Défaut | Plage sûre | Rationale |
|---|---|---|---|---|
| `max_hp` | curve | 20 / 56 | 15–30 / 40–70 | Référence de TTK ; 56 PV = 2,47 s à l'épée |
| `move_speed` | feel | 70 / 55 | 55–85 / 45–65 | Le squelette doit être plus rapide que l'orc mais plus lent que le joueur |
| `contact_damage` | curve | 8 / 14 | 5–12 / 10–18 | 8 % / 14 % des 100 PV |
| `spawn_weight` | curve | 1,0 / 0,5 | 0,5–1,5 / 0,2–0,8 | Le ciment de la vague ; ne jamais descendre sous 0,5 cumulé |

### Chargeur (loup)

| Knob | Catégorie | Défaut | Plage sûre | Rationale |
|---|---|---|---|---|
| `charge_acquire_min` | gate | 70 | 50–100 | En dessous, la charge serait illisible ; le loup mord |
| `charge_acquire_max` | gate | 260 | 200–320 | Doit rester < `charge_distance` |
| `charge_telegraph` | feel | 0,60 | 0,45–0,80 | < 0,40 illisible ; > 0,80 gratuit |
| `charge_speed` | feel | 560 | 480–640 | 2,5× le joueur ; la vitesse fait la peur |
| `charge_distance` | feel | 320 | 240–400 | Doit couvrir `charge_acquire_max` + 40 |
| `charge_damage` | curve | 14 | 10–18 | Une charge réussie doit coûter cher |
| `charge_recovery` | feel | 0,60 | 0,40–0,90 | Fenêtre de punition |
| `charge_cooldown` | gate | 2,40 | 1,60–3,50 | Cycle cible 3,5–5,0 s |
| `charge_cooldown_jitter` | gate | ±15 % | 0–25 % | Désynchronise la meute |
| `wall_stun_bonus` | feel | 0,30 | 0–0,60 | Récompense le placement |
| `charger_max_concurrent_windups` | gate | 2 | 1–4 | Lisibilité à 60 ennemis ; ne supprime jamais une bande active |

### Tireur (Plume)

| Knob | Catégorie | Défaut | Plage sûre | Rationale |
|---|---|---|---|---|
| `ranged_band_min` | gate | 180 | 140–220 | En dessous, elle recule ; jamais 0 |
| `ranged_band_max` | gate | 320 | 260–380 | Doit rester < portée du projectile |
| `retreat_speed` | feel | 110 | 90–130 | Moitié du joueur : il la rattrape |
| `aim_telegraph` | feel | 0,65 | 0,45–0,90 | Fenêtre de fermeture |
| `shot_interval` | gate | 2,60 | 1,80–3,50 | 0,385 tir/s |
| `bolt_speed` | feel | 260 | 200–340 | Lent = esquivable ; rapide = injuste |
| `bolt_damage` | curve | 8 | 6–12 | 8 % des PV |
| `bolt_lifetime` | gate | 1,60 | 1,20–2,20 | Portée ≥ bande haute |
| `ranged_max_drawn_threads` | gate | 6 | 4–8 | Lisibilité ; ne supprime jamais un projectile |

### Exploseur (Tache)

| Knob | Catégorie | Défaut | Plage sûre | Rationale |
|---|---|---|---|---|
| `max_hp` | curve | 20 | 16–26 | Doit rester tuable en < 1,0 s à l'épée |
| `move_speed` | feel | 100 | 85–120 | Approche lente, la menace est la mèche |
| `fuse_trigger_radius` | gate | 120 | 90–150 | Assez loin pour que la fuite soit possible |
| `fuse_time` | feel | 1,00 | 0,80–1,40 | < 0,8 injuste ; > 1,4 gratuit |
| `fuse_speed` | feel | 245 | 220–280 | 25 px/s de fermeture : fuit de justesse |
| `blast_radius` | curve | 65 | 50–80 | 79 px effectifs avec le joueur |
| `blast_damage` | curve | 18 | 12–24 | 18 % ; deux = 36 % |
| `explosion_friendly_fire` | curve | 0,0 | 0,0–0,5 | 0 par défaut : pas de ferme ni de chaîne |
| `self_detonation_xp` | curve | 0 | 0–3 | Doit rester 0 pour que la tuer rapporte |

### Invocateur (Copiste)

| Knob | Catégorie | Défaut | Plage sûre | Rationale |
|---|---|---|---|---|
| `max_hp` | curve | 90 | 70–120 | ~4 s à l'épée : un vrai engagement |
| `move_speed` | feel | 55 | 45–70 | Lent ; il ne fuit pas |
| `initial_summon_delay` | gate | 2,00 | 1,00–3,00 | Évite une invocation instantanée au bord |
| `summon_interval` | gate | 6,00 | 4,50–8,00 | 0,333 squelette/s |
| `summon_telegraph` | feel | 0,90 | 0,60–1,20 | Assez pour tuer ou reculer |
| `summon_count` | curve | 2 | 1–3 | 2 est le maximum lisible (deux cercles) |
| `summon_radius` | feel | 100 | 70–140 | Les cercles restent visibles |
| `summon_retry_delay` | gate | 1,50 | 0,50–3,00 | Retry quand le plafond bloque |
| `summoned_xp` | curve | 0 | 0 (fixe) | **0 obligatoire** : anti-ferme |
| `boss_wave_summoning` | gate | désactivé | on/off | Protège le duel |

### Globaux

| Knob | Catégorie | Défaut | Plage sûre | Rationale |
|---|---|---|---|---|
| `contact_cooldown` | gate | 1,00 s | 0,8–1,2 | Existant (`RunConfig`) |
| `contact_damage` des invoqués | curve | 8 | 6–10 | Identique au squelette |
| `unlock_guarantee_count` | gate | 2 (1 sur boss) | 1–3 | Rend le critère testable |
| `enemy.radius` (nouveaux) | feel | 12 / 14 / 22 | ±20 % | La silhouette et le hit test partagent le rayon |

---

## Acceptance Criteria

### Fonctionnel (testable automatiquement)

1. **Roster complet.** Le catalogue non-élite contient exactement six archétypes : `squelette`, `loup_maudit`, `orc`, `plume`, `tache`, `copiste`. Le boss est absent de `catalogue.enemies` et présent dans `catalogue.boss`.
2. **Comportement déclaré.** Chaque archétype non-élite a un `EnemyData.behavior` ∈ {`walker`, `charger`, `ranged`, `exploder`, `summoner`}. Un `behavior` vide ou inconnu retombe sur `walker` sans erreur.
3. **Déblocages.** Les `unlock_wave` valent exactement `[0, 2, 4, 3, 5, 7]` pour `[squelette, loup_maudit, orc, plume, tache, copiste]`. Un test seedé vérifie qu'aucun archétype n'apparaît avant son `unlock_wave`.
4. **Calendrier.** Une simulation seedée de 10 vagues produit au moins un spawn de chaque archétype à sa vague de déblocage (garantie) et aucune apparition avant.
5. **≥ 4 comportements distincts par run complet.** Un run simulé jusqu'à la vague 10 observe au moins 4 `behavior` ids distincts ; avec les garanties, il doit en observer 5 (`walker`, `charger`, `ranged`, `exploder`, `summoner`). Le test échoue si la garantie est retirée.
6. **Chargeur.** Le test vérifie : direction verrouillée au début de `charge_windup` ; `T_charge = 0,571 s` ; une seule application de `charge_damage` par charge ; arrêt à la bordure ; `wall_stun_bonus` appliqué ; recul ignoré en `charge_windup`/`charging` ; plafond de 2 têtes de charge.
7. **Tireur.** Le test vérifie : `aim_telegraph` 0,65 s ; immobilisation pendant la visée ; le projectile part vers la position du joueur à l'instant du tir (pas de leading) ; le fil ne dessine que les 6 plus proches ; la Plume ne recule pas au-delà de la bordure.
8. **Exploseur.** Le test vérifie : déclenchement à ≤ 120 px ; `fuse_time` 1,00 s ; vitesse 245 ; arrêt à 28 px du joueur ; détonation à `blast_radius + Player.RADIUS` ; dégâts létaux avant la mèche annulent la zone ; auto-détonation = 0 XP ; détonation sans joueur = 0 dégât.
9. **Invocateur.** Le test vérifie : 2 squelettes après 0,90 s ; XP 0 pour les invoqués ; invoqués comptés dans `max_alive` ; annulation si mort pendant l'annonce ; refus si `alive_count + summon_count > max_alive` ; pas d'invocation tant que le boss est vivant ; minimum 1 squelette si un point est invalide.
10. **Formes d'annonce.** Les 4 formes sont demandées par les bons comportements, avec les bonnes durées : `band` 0,60 / `thread` 0,65 / `ring_closing` 1,00 / `ring_opening` 0,90. Aucune n'est dessinée pendant la résolution (l'annonce précède toujours l'effet).
11. **Data-driven.** Modifier `spawn_weight`, `unlock_wave`, `max_hp` ou une durée dans un `.tres` change le run sans toucher au code ; aucun de ces nombres n'apparaît dans un script.
12. **Localisation.** Chaque archétype a `enemy.<id>.name` et `enemy.<id>.desc` dans le CSV fr ; aucune chaîne affichable n'est lue depuis `display_name` ; une clé manquante retombe sur le français sans planter.
13. **Performance.** 60 ennemis avec les cinq comportements à 60 fps ; le pas de comportement reste sous le budget 2 ms mesuré par W1-E5.
14. **Non-régression.** Les tests existants du spawner, de `WaveDirector`, du boss et des armes restent verts.

### Expérientiel (playtest)

1. **Nommer avant l'acte.** Après une run, on montre à 5 testeurs chaque ennemi (capture ou jeu figé) et on demande : « que va-t-il faire ? ». **≥ 4/5** réponses correctes pour chacun des 5 comportements, et **≥ 80 %** des observations « nommé avant que l'action se produise ».
2. **Lisibilité à 100 %.** Les 4 annonces et les 3 nouvelles silhouettes sont reconnaissables à 100 % sur l'herbe, en un coup d'œil, selon `art-director`. Revue daltonisme W1-E5 : chaque annonce reste identifiable sans la couleur (géométrie + mouvement).
3. **La fuite de la Tache se sent juste.** Les testeurs qui fuient perpendiculairement survivent ; ceux qui restent immobiles sont touchés. Le retour verbal ne doit pas contenir « je n'ai pas vu le cercle ».
4. **Le Copiste crée une décision, pas une corvée.** Les testeurs disent spontanément qu'ils vont le tuer en priorité, ou expliquent pourquoi ils ne peuvent pas. Aucun testeur ne dit « je farme ses squelettes » (0 XP rend la ferme absurde).
5. **Aucune vague inesquivables.** W1-E4 valide qu'aucune vague ne combine deux engagements **inesquivables** simultanés (ex. deux bandes qui se croisent sans issue). Si c'est le cas, le calendrier change.
6. **Le loup ne lit pas comme un bélier.** Revue d'art : la silhouette reste horizontale, sans corne ; la charge se lit par la posture + la ligne. Si un testeur dit « taureau » ou « bélier », l'art est à revoir, pas le comportement.
7. **Le marcheur reste le ciment.** Les testeurs ne réclament pas d'annonce pour le squelette ou l'orc ; ils lisent la masse. Si un testeur dit « je ne vois pas ce qu'il va faire », c'est la densité ou la couleur qui est en cause, pas l'absence de télégraphie.

---

*Fin du GDD. Les valeurs de ce document sont la référence de W1-E0 ; toute modification passe par `/propagate-design-change` vers W1-E1, W1-E2, W1-E3, W1-E4, W2-E2 et W8-E1.*
