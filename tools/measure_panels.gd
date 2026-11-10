## Measures the run's level-up budget from the tuning data alone.
##
## No scene, no input and no combat: the wave clock, spawn cadence, enemy mix,
## XP curve and offer weights are arithmetic over WaveData, EnemyData,
## WeaponData and RunConfig. Two bounds are reported: a floor using the starting
## weapon's single-target DPS with no upgrade taken, and a ceiling where every
## spawn is killed and both bosses die. The truth lies between; the model is
## meant to be checked against a few played runs.
##
## The offer table answers one question: with the measured number of panels,
## how many weapon rows can a run expect, and can a player who always takes one
## max all three base weapons? That takes 11 weapon rows, not 9: the run starts
## with one weapon at level 1, so the loadout needs 2 acquisitions (levels 1)
## plus 3 level-ups on each of the 3 weapons to reach level 4. The table assumes
## one weapon row per panel at most (A2) and one weapon candidate per carried
## weapon below max level plus one per free slot, which is the lot 1 shape.
##
##   godot --headless -s res://tools/measure_panels.gd
extends SceneTree

const CATALOGUE_PATH := "res://data/catalogue.tres"
const RUN_CONFIG_PATH := "res://data/run_config.tres"

## Weights compared in the offer table.
const WEIGHTS: Array[float] = [0.8, 1.0, 1.2, 1.4, 1.6, 2.0, 2.5, 3.0]

## Weapon rows a run needs to reach level 4 on all three base weapons: two
## acquisitions at level 1 plus three level-ups on each of the three.
const ALL_THREE_MAXED_PICKS := 2 + 3 * 3


func _initialize() -> void:
	var catalogue := load(CATALOGUE_PATH) as Catalogue
	var config := load(RUN_CONFIG_PATH) as RunConfig
	if catalogue == null or config == null or catalogue.wave == null:
		push_error("measure: cannot load catalogue or run config")
		quit(1)
		return

	var wave: WaveData = catalogue.wave
	var weapon: WeaponData = catalogue.starting_class.weapon if catalogue.starting_class else null
	var dps := _weapon_dps(weapon)
	print("Arme de départ : %s — %.2f dégâts/s (cible unique, sans upgrade)" % [
		weapon.id if weapon != null else "aucune", dps
	])
	print("")

	var cumulative := 0.0
	var ceiling := 0.0
	var boss_xp := 0
	var bosses := 0
	print("vague | intervalle | spawns | PV moy | capacité | tués | XP vague | XP cum | niveau | panels")
	print("------+------------+--------+--------+----------+-------+----------+--------+--------+-------")
	for index in wave.total_waves:
		var interval := wave.base_spawn_interval * pow(wave.interval_decay_per_wave, float(index))
		var is_boss := wave.boss_every_waves > 0 and (index + 1) % wave.boss_every_waves == 0
		if is_boss:
			interval *= wave.boss_spawn_interval_scale
			bosses += 1
			if catalogue.boss != null:
				boss_xp += catalogue.boss.xp_value
		interval = maxf(interval, wave.min_spawn_interval)

		var spawns := int(floor(wave.duration / interval))
		var expected := _expected_enemy(catalogue, index)
		var capacity := dps * wave.duration / maxf(expected.x, 0.001)
		var kills := minf(float(spawns), capacity)
		var wave_xp := kills * expected.y
		cumulative += wave_xp
		# The ceiling: every spawn dies, whatever the player's damage.
		ceiling += float(spawns) * expected.y

		print("%5d | %10.2f | %6d | %6.2f | %8.2f | %5.1f | %8.2f | %6.1f | %6d | %6d" % [
			index + 1, interval, spawns, expected.x, capacity, kills, wave_xp,
			cumulative, _level_for(cumulative, config), _level_for(cumulative, config) - 1,
		])

	print("")
	print("Plancher (DPS de départ, aucun upgrade, boss non tués) : %.1f XP → niveau %d → %d panels" % [
		cumulative, _level_for(cumulative, config), _level_for(cumulative, config) - 1,
	])
	ceiling += float(boss_xp)
	print("Plafond  (tous les spawns tués, %d boss tués)        : %.1f XP → niveau %d → %d panels" % [
		bosses, ceiling, _level_for(ceiling, config), _level_for(ceiling, config) - 1,
	])
	print("Butin : %d panneaux de boss en plus, poids d'offre séparés (arme 3.0, équipement 2.5)." % bosses)
	print("")

	_print_offer_table(catalogue, config, _level_for(cumulative, config) - 1,
		_level_for(ceiling, config) - 1, bosses)
	quit(0)


## Effective single-target DPS of [param weapon], crit included.
func _weapon_dps(weapon: WeaponData) -> float:
	if weapon == null:
		return 0.0
	var crit_factor := 1.0 + weapon.crit_chance * (weapon.crit_multiplier - 1.0)
	return weapon.damage * weapon.attacks_per_second * crit_factor


## Weighted (hit points, xp) of one spawn on [param wave_index]. Elites are
## excluded: the normal spawner never picks them.
func _expected_enemy(catalogue: Catalogue, wave_index: int) -> Vector2:
	var total := 0.0
	var hp := 0.0
	var xp := 0.0
	for enemy in catalogue.enemies:
		if enemy == null or enemy.is_elite or wave_index < enemy.unlock_wave:
			continue
		var weight := maxf(enemy.spawn_weight, 0.0)
		total += weight
		hp += weight * float(enemy.max_hp)
		xp += weight * float(enemy.xp_value)
	if total <= 0.0:
		return Vector2(1.0, 0.0)
	return Vector2(hp / total, xp / total)


## Highest level reachable with [param xp], starting at level 1.
func _level_for(xp: float, config: RunConfig) -> int:
	var level := 1
	while xp >= _xp_to_reach(level + 1, config):
		level += 1
	return level


## Total XP needed to stand at [param level], starting from level 1.
func _xp_to_reach(level: int, config: RunConfig) -> float:
	var total := 0.0
	for step in range(1, level):
		total += float(config.xp_base + (step - 1) * config.xp_per_level)
	return total


## Prints, for each candidate weapon-upgrade weight, the share of offer weight on
## weapons and the probability a panel shows at least one weapon row. The pool is
## evaluated at 1, 2 and 3 carried weapons: new-weapon rows keep
## [member RunConfig.weapon_offer_weight], upgrade rows use the candidate weight.
## "Rows" is the expected number of weapon rows drawn by a player who takes every
## one, at the measured panel ceiling plus boss loot. The last two columns give
## the chance of drawing enough weapon rows (11) to max all three weapons, at the
## floor and ceiling panel counts, under the optimistic constant probability.
func _print_offer_table(
	catalogue: Catalogue, config: RunConfig, panels_floor: int, panels_ceiling: int, bosses: int
) -> void:
	var stat_weight := 0.0
	var non_weapon: Array[float] = []
	for upgrade in catalogue.upgrades:
		if upgrade != null:
			stat_weight += maxf(upgrade.weight, 0.0)
			non_weapon.append(maxf(upgrade.weight, 0.0))
	var equipment_weight := 0.0
	for item in catalogue.equipment:
		if item != null:
			equipment_weight += config.equipment_offer_weight * EquipmentData.offer_weight_for_rarity(item.rarity)
			non_weapon.append(
				config.equipment_offer_weight * EquipmentData.offer_weight_for_rarity(item.rarity)
			)

	print("Panels mesurés : %d (plancher) à %d (plafond), + %d panneaux de butin." % [
		panels_floor, panels_ceiling, bosses,
	])
	print("Stats %.1f ; équipement %.2f ; lignes par panel : %d ; nouvelles armes : %.1f" % [
		stat_weight, equipment_weight, config.upgrade_offer_count, config.weapon_offer_weight,
	])
	print("Il faut %d lignes d'arme pour amener les trois armes de niveau 1 à 4." % ALL_THREE_MAXED_PICKS)
	print("")
	print("poids | part arme 1/2/3 portées | P(panel) min-max | lignes attendues | P(11 lignes) plancher-plafond")
	print("------+--------------------------+------------------+------------------+-----------------------------")
	var loot_chance := _loot_panel_chance(catalogue, config)
	for weight in WEIGHTS:
		var shares: Array[float] = []
		var chances: Array[float] = []
		for carried in range(1, Inventory.MAX_WEAPONS + 1):
			var free := Inventory.MAX_WEAPONS - carried
			var weapon_weight := (
				float(free) * config.weapon_offer_weight + float(carried) * weight
			)
			var total := stat_weight + equipment_weight + weapon_weight
			shares.append(weapon_weight / total)
			chances.append(1.0 - _no_weapon_chance(non_weapon, total, config.upgrade_offer_count))
		var p_max := maxf(maxf(chances[0], chances[1]), chances[2])
		var p_min := minf(minf(chances[0], chances[1]), chances[2])
		var rows := p_max * float(panels_ceiling) + loot_chance * float(bosses)
		var floor_tail := _binomial_tail(panels_floor + bosses, ALL_THREE_MAXED_PICKS, p_max)
		var ceiling_tail := _binomial_tail(panels_ceiling + bosses, ALL_THREE_MAXED_PICKS, p_max)
		print("%5.1f | %5.1f / %5.1f / %5.1f %% | %6.1f - %6.1f %% | %16.1f | %6.1f%% - %6.1f%%" % [
			weight, shares[0] * 100.0, shares[1] * 100.0, shares[2] * 100.0,
			p_min * 100.0, p_max * 100.0, rows, floor_tail * 100.0, ceiling_tail * 100.0,
		])

	print("")
	print("Part arme affichée au premier panel / pool moyen / pool plein (3 armes portées).")
	print("Lignes attendues : %d panels × P(panel avec arme) + butin → borne haute moyenne." % panels_ceiling)
	print("P(11 lignes) : chance d'avoir assez de panels à arme pour tout maxer, si P reste au maximum.")
	print("Butin : 2 panneaux, poids arme %.1f ; %.1f%% de chance d'y voir une arme." % [
		config.boss_loot_weapon_weight, loot_chance * 100.0,
	])


## Probability of at least [param k] successes out of [param n] draws, each with
## probability [param p]. Exact sum over the upper tail.
func _binomial_tail(n: int, k: int, p: float) -> float:
	if k <= 0:
		return 1.0
	if k > n:
		return 0.0
	var total := 0.0
	for successes in range(k, n + 1):
		total += _combinations(n, successes) * pow(p, float(successes)) \
			* pow(1.0 - p, float(n - successes))
	return total


## Binomial coefficient "n choose k".
func _combinations(n: int, k: int) -> float:
	var result := 1.0
	for step in range(k):
		result = result * float(n - step) / float(step + 1)
	return result


## Probability that a boss-loot panel shows at least one weapon row.
func _loot_panel_chance(catalogue: Catalogue, config: RunConfig) -> float:
	var non_weapon: Array[float] = []
	var total := 0.0
	for upgrade in catalogue.upgrades:
		if upgrade != null:
			non_weapon.append(maxf(upgrade.weight, 0.0))
			total += maxf(upgrade.weight, 0.0)
	for item in catalogue.equipment:
		if item == null:
			continue
		var weight := config.boss_loot_equipment_weight * EquipmentData.offer_weight_for_rarity(item.rarity)
		non_weapon.append(weight)
		total += weight
	var weapon_weight := float(Inventory.MAX_WEAPONS) * config.boss_loot_weapon_weight
	total += weapon_weight
	return 1.0 - _no_weapon_chance(non_weapon, total, config.upgrade_offer_count)


## Probability that [param rows] consecutive picks avoid every item in
## [param non_weapon]. Weighted sampling without replacement, exact by recursion.
func _no_weapon_chance(non_weapon: Array[float], total: float, rows: int) -> float:
	if rows <= 0:
		return 1.0
	var chance := 0.0
	for index in non_weapon.size():
		var weight := non_weapon[index]
		if weight <= 0.0:
			continue
		var rest := non_weapon.duplicate()
		rest.remove_at(index)
		chance += (weight / total) * _no_weapon_chance(rest, total - weight, rows - 1)
	return chance
