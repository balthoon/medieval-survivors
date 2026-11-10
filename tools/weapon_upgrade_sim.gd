## Empirical harness for `RunConfig.weapon_upgrade_weight` (lot 1).
##
## Instantiates the real main scene, silences its waves, then plays the offer
## loop only: a run is 15 level-up panels, each built by the shipped
## `_build_offers()` and answered by a policy. Two policies bracket the real
## player: `random` takes whatever the panel shows, `greedy` fills the three
## weapon slots, then levels the carried weapons, then takes gear, then stats.
##
## The point is not to balance the game but to choose the one number lot 1 adds.
## The report per weight gives acquisitions, level-ups, weapon rows and the
## final loadout. `measure_panels.gd` models the same loop analytically; this
## script checks the model against the real code path.
##
##   godot --headless -s res://tools/weapon_upgrade_sim.gd
extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

## Panels played per run. The measured run sits between 9 and 14 level ups plus
## two boss loot panels; 15 is the upper bound of experience.
const PANELS := 15
## Runs per policy and per candidate weight.
const RUNS := 200
## Candidate weights for the upgrade row.
const WEIGHTS: Array[float] = [0.8, 1.0, 1.2, 1.4, 1.6, 2.0]
## Policies, in report order.
const POLICIES: Array[String] = ["random", "greedy"]

var _main: Node = null
var _class_data: ClassData = null
var _policy_rng := RandomNumberGenerator.new()

## One entry per (weight, policy) pair, filled by _run_once().
var _results: Array[Dictionary] = []
var _weight_index := 0
var _policy_index := 0
var _run_index := 0
## Frames to let the scene finish its _ready() before the first run.
var _boot_frames := 0


func _initialize() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("sim: cannot load %s" % MAIN_SCENE_PATH)
		quit(1)
		return
	_main = packed.instantiate()
	root.add_child(_main)
	_policy_rng.seed = 20261110


## Plays one run per frame. Returns true once every weight and policy is done.
func _process(_delta: float) -> bool:
	if _boot_frames < 3:
		_boot_frames += 1
		if _boot_frames == 3:
			_boot()
		return false
	if _weight_index >= WEIGHTS.size():
		_print_report()
		return true

	var result := _results[_weight_index * POLICIES.size() + _policy_index]
	_main._config.weapon_upgrade_weight = float(result["weight"])
	_run_once(result, String(result["policy"]))
	_run_index += 1
	if _run_index >= RUNS:
		_run_index = 0
		_policy_index += 1
		if _policy_index >= POLICIES.size():
			_policy_index = 0
			_weight_index += 1
	return false


## Reads the catalogue once the scene is ready and builds every result row.
func _boot() -> void:
	if _main.catalogue == null or _main.catalogue.starting_class == null:
		push_error("sim: catalogue or starting class missing")
		quit(1)
		return
	_class_data = _main.catalogue.starting_class
	_main._enemy_pool.clear()
	_main.is_paused = true
	for weight in WEIGHTS:
		for policy in POLICIES:
			_results.append({
				"weight": weight,
				"policy": policy,
				"runs": 0,
				"acquisitions": 0,
				"upgrades": 0,
				"weapon_rows": 0,
				"dead_panels": 0,
				"weapons": 0,
				"levels": 0.0,
				"all_max": 0,
			})


## Resets the run state, plays [constant PANELS] panels, and folds the outcome
## into [param result].
func _run_once(result: Dictionary, policy: String) -> void:
	_reset_run(_run_index * 7919 + hash(policy))
	var acquisitions := 0
	var upgrades := 0
	var weapon_rows := 0
	var dead_panels := 0
	var inventory: Inventory = _main._inventory

	for _panel in PANELS:
		var choices: Array[Offer] = _main._build_offers(3)
		if choices.is_empty():
			break
		var has_row := false
		for offer in choices:
			if offer.kind == "weapon" or offer.kind == "weapon_upgrade":
				has_row = true
				weapon_rows += 1
				break
		if not has_row and _has_upgradable(inventory):
			dead_panels += 1
		var chosen := _choose(choices, policy)
		if chosen.kind == "weapon":
			acquisitions += 1
		elif chosen.kind == "weapon_upgrade":
			upgrades += 1
		_main._apply_offer(chosen)

	var levels := 0
	var all_max := not inventory.weapons.is_empty()
	for weapon in inventory.weapons:
		if weapon == null:
			continue
		var level := inventory.level_of(weapon)
		levels += level
		if level < maxi(weapon.max_level, 1):
			all_max = false

	result["runs"] = int(result["runs"]) + 1
	result["acquisitions"] = int(result["acquisitions"]) + acquisitions
	result["upgrades"] = int(result["upgrades"]) + upgrades
	result["weapon_rows"] = int(result["weapon_rows"]) + weapon_rows
	result["dead_panels"] = int(result["dead_panels"]) + dead_panels
	result["weapons"] = int(result["weapons"]) + inventory.weapons.size()
	result["levels"] = float(result["levels"]) + float(levels)
	if all_max:
		result["all_max"] = int(result["all_max"]) + 1


## Puts the scene back at the first frame of a run: class stats, starting
## weapon, level 1, and a seeded offer roll source.
func _reset_run(seed_value: int) -> void:
	_main._player.setup(_class_data)
	_main._inventory.setup_starting(_class_data.weapon)
	_main._base_stats = _main._player.stats
	_main._recompute_stats()
	_main._weapon_system.refresh()
	_main._level = 1
	_main._xp = 0.0
	_main._xp_needed = _main.xp_to_next(1)
	_main._pending_choices.clear()
	_main._boss_loot_open = false
	_main._dead = false
	_main.is_paused = true
	_main._rng.seed = seed_value


## True while at least one carried weapon is below its max level, so a panel
## with no weapon row is a panel that could not show a wanted upgrade.
func _has_upgradable(inventory: Inventory) -> bool:
	for weapon in inventory.weapons:
		if weapon != null and inventory.can_upgrade_weapon(weapon):
			return true
	return false


## Picks one offer under [param policy]. Random is uniform; greedy prefers a new
## weapon, then a level, then a piece of gear, then a stat.
func _choose(choices: Array[Offer], policy: String) -> Offer:
	if policy == "greedy":
		var best := choices[0]
		var best_score := _score(best)
		for offer in choices:
			var score := _score(offer)
			if score > best_score:
				best = offer
				best_score = score
		return best
	return choices[_policy_rng.randi_range(0, choices.size() - 1)]


## Greedy preference of one offer kind.
func _score(offer: Offer) -> int:
	match offer.kind:
		"weapon":
			return 4
		"weapon_upgrade":
			return 3
		"equipment":
			return 2
	return 1


## Prints one row per weight and policy, averaged per run.
func _print_report() -> void:
	print("")
	print("Medieval Survivors — simulation de weapon_upgrade_weight (lot 1)")
	print("%d runs × %d panneaux par poids et par politique." % [RUNS, PANELS])
	print("")
	print("poids | politique | armes acquises | niveaux gagnés | lignes d'arme | panels sans arme | armes fin | niv. moyen | tout au max")
	print("------+-----------+----------------+----------------+---------------+------------------+-----------+------------+-------------")
	for result in _results:
		var runs := maxf(float(result["runs"]), 1.0)
		print("%5.1f | %-9s | %14.2f | %14.2f | %13.2f | %16.2f | %9.2f | %10.2f | %10.1f %%" % [
			float(result["weight"]),
			String(result["policy"]),
			float(result["acquisitions"]) / runs,
			float(result["upgrades"]) / runs,
			float(result["weapon_rows"]) / runs,
			float(result["dead_panels"]) / runs,
			float(result["weapons"]) / runs,
			float(result["levels"]) / maxf(float(result["weapons"]), 1.0),
			100.0 * float(result["all_max"]) / runs,
		])
	print("")
	print("Lecture : « lignes d'arme » compte les panneaux avec une arme ;")
	print("« panels sans arme » ceux où une arme portée était encore améliorable.")
	print("« tout au max » est la part de runs terminés avec les armes au niveau maximum.")
