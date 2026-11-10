## Lot 3: equipment identity.
##
## A piece can now carry a passive (a rule) and belong to a set (a bonus granted
## once when enough pieces are worn). The two are separate: a piece may have
## either, both, or neither. Set bonuses use the same additive rule as the piece
## itself, so a set never compounds with the stat it grants.
##
## Every test builds its own resources and Stats: no file, no scene tree, no
## shared state, so the suite passes in any execution order.
extends GdUnitTestSuite

const BASE_DAMAGE := 10.0


## A weapon resource tuned for these tests, away from any content file.
func _weapon() -> WeaponData:
	var weapon := WeaponData.new()
	weapon.id = "test_blade"
	weapon.display_name = "Lame de test"
	weapon.damage = BASE_DAMAGE
	weapon.attacks_per_second = 2.0
	weapon.range_px = 100.0
	weapon.crit_chance = 0.0
	return weapon


## An equipment piece built by the test, so no content file can shift a value.
func _piece(
	id: String,
	slot: String,
	stat: String,
	amount: float,
	set_id: String = "",
	passive_id: StringName = &"",
	passive_value: float = 0.0
) -> EquipmentData:
	var item := EquipmentData.new()
	item.id = id
	item.display_name = id
	item.slot = slot
	item.stat = stat
	item.amount = amount
	item.set_id = set_id
	item.passive_id = passive_id
	item.passive_value = passive_value
	return item


## A set resource built by the test. Not named `_set`: that is an Object
## virtual, and overriding it with another signature fails the parse.
func _set_resource(id: String, stat: String, amount: float, required: int = 2) -> EquipmentSetData:
	var set_data := EquipmentSetData.new()
	set_data.id = id
	set_data.display_name = id
	set_data.stat = stat
	set_data.amount = amount
	set_data.required_pieces = required
	return set_data


func test_rage_multiplier_is_inactive_at_or_above_the_threshold() -> void:
	# Arrange
	var stats := Stats.new()
	stats.rage_bonus = 0.15
	stats.rage_hp_threshold = 0.5

	# Act / Assert
	stats.hp_ratio = 0.5
	assert_float(stats.rage_multiplier()).is_equal_approx(1.0, 0.0001)
	stats.hp_ratio = 0.49
	assert_float(stats.rage_multiplier()).is_equal_approx(1.15, 0.0001)
	stats.hp_ratio = 0.0
	assert_float(stats.rage_multiplier()).is_equal_approx(1.15, 0.0001)


func test_rage_multiplier_is_one_without_the_passive() -> void:
	# Arrange
	var stats := Stats.new()
	stats.hp_ratio = 0.1

	# Act / Assert
	assert_float(stats.rage_multiplier()).is_equal_approx(1.0, 0.0001)


func test_rage_scales_weapon_damage_below_the_threshold() -> void:
	# Arrange
	var stats := Stats.new()
	stats.rage_bonus = 0.15
	stats.rage_hp_threshold = 0.5
	var weapon := _weapon()

	# Act
	stats.hp_ratio = 1.0
	var healthy := stats.weapon_damage(weapon)
	stats.hp_ratio = 0.2
	var enraged := stats.weapon_damage(weapon)

	# Assert
	assert_float(healthy).is_equal_approx(BASE_DAMAGE, 0.0001)
	assert_float(enraged).is_equal_approx(BASE_DAMAGE * 1.15, 0.0001)


func test_rage_composes_with_the_global_damage_multiplier() -> void:
	# Arrange
	var stats := Stats.new()
	stats.damage_mult = 1.2
	stats.rage_bonus = 0.15
	stats.rage_hp_threshold = 0.5
	stats.hp_ratio = 0.3

	# Act
	var damage := stats.weapon_damage(_weapon())

	# Assert — global x rage, not one replacing the other.
	assert_float(damage).is_equal_approx(BASE_DAMAGE * 1.2 * 1.15, 0.0001)


func test_set_bonus_is_additive_with_the_pieces() -> void:
	# Arrange
	var stats := Stats.new()
	var set_data := _set_resource("test_set", "damage", 0.1)

	# Act — one piece at +10 %, then the set at +10 %.
	stats.apply_equipment(_piece("piece", "anneau", "damage", 0.1))
	stats.apply_set_bonus(set_data)

	# Assert
	assert_float(stats.damage_mult).is_equal_approx(1.2, 0.0001)


func test_set_bonus_crit_is_clamped_to_the_cap() -> void:
	# Arrange
	var stats := Stats.new()
	stats.crit_chance_bonus = 0.7

	# Act
	stats.apply_set_bonus(_set_resource("test_set", "crit_chance", 0.12))

	# Assert
	assert_float(stats.crit_chance_bonus).is_equal_approx(Stats.CRIT_CAP, 0.0001)


func test_inventory_counts_only_worn_pieces_of_the_set() -> void:
	# Arrange
	var inventory := Inventory.new()
	var first := _piece("first", "casque", "crit_chance", 0.06, "duelliste")
	var second := _piece("second", "gants", "crit_chance", 0.1, "duelliste")
	var stray := _piece("stray", "bottes", "move_speed", 0.08)
	inventory.equip(first)
	inventory.equip(second)

	# Act / Assert
	assert_int(inventory.count_set_pieces("duelliste")).is_equal(2)
	assert_int(inventory.count_set_pieces("")).is_equal(0)
	inventory.equip(stray)
	assert_int(inventory.count_set_pieces("duelliste")).is_equal(2)
	inventory.equip(_piece("replacement", "gants", "damage", 0.1))
	assert_int(inventory.count_set_pieces("duelliste")).is_equal(1)


func test_inventory_set_completion_respects_required_pieces() -> void:
	# Arrange
	var inventory := Inventory.new()
	var set_data := _set_resource("duelliste", "crit_chance", 0.12, 2)
	inventory.equip(_piece("first", "casque", "crit_chance", 0.06, "duelliste"))

	# Act / Assert
	assert_bool(inventory.is_set_complete(set_data)).is_false()
	inventory.equip(_piece("second", "gants", "crit_chance", 0.1, "duelliste"))
	assert_bool(inventory.is_set_complete(set_data)).is_true()
	assert_bool(inventory.is_set_complete(null)).is_false()


func test_inventory_passive_total_sums_worn_pieces() -> void:
	# Arrange
	var inventory := Inventory.new()
	inventory.equip(_piece("ring", "anneau", "damage", 0.22, "", &"rage", 0.15))
	inventory.equip(_piece("amulet", "amulette", "max_hp", 60.0, "", &"level_up_heal", 8.0))
	inventory.equip(_piece("gloves", "gants", "damage", 0.1, "", &"rage", 0.05))

	# Act / Assert
	assert_float(inventory.passive_total(&"rage")).is_equal_approx(0.2, 0.0001)
	assert_float(inventory.passive_total(&"level_up_heal")).is_equal_approx(8.0, 0.0001)
	assert_float(inventory.passive_total(&"unknown")).is_equal_approx(0.0, 0.0001)
	assert_float(inventory.passive_total(&"")).is_equal_approx(0.0, 0.0001)


func test_piece_without_a_passive_prints_no_passive_line() -> void:
	# Arrange
	var plain := _piece("plain", "anneau", "damage", 0.1)
	var raging := _piece("raging", "anneau", "damage", 0.1, "", &"rage", 0.15)

	# Act / Assert — no assertion on the exact French wording, which is locale
	# dependent; the passive id and the value must show up.
	assert_str(plain.passive_text()).is_empty()
	assert_str(raging.passive_text(0.5)).contains("15")
	assert_str(raging.passive_text(0.5)).contains("50")


func test_set_bonus_text_formats_the_stat() -> void:
	# Arrange
	var set_data := _set_resource("duelliste", "crit_chance", 0.12)

	# Act
	var text := set_data.bonus_text()

	# Assert
	assert_str(text).contains("12")
	assert_str(text).contains("critique")
