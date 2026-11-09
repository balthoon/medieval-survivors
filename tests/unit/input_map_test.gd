## W0-E3: the run's input bindings live in project.godot, not in code, so the
## remapping screen (W6-E3) can rewrite them without a code change. These tests
## pin the bindings the game shipped with, so a silent rebinding is caught.
##
## The letter keys are asserted as *physical* keycodes: that is what makes WASD
## mean ZQSD on an AZERTY keyboard, and a switch to logical keycodes would pass
## every gameplay test while breaking the user's own layout.
extends GdUnitTestSuite

const ACTIONS := [
	"move_left", "move_right", "move_up", "move_down",
	"restart", "reroll", "choice_1", "choice_2", "choice_3", "mute",
]

const MOVE_KEYS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
}

const MOVE_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func test_every_run_action_is_bound() -> void:
	for action: String in ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(
			"action '%s' is defined in project.godot" % action
		).is_true()


func test_movement_letters_are_physical_keys() -> void:
	for action: String in MOVE_KEYS:
		# Arrange — every physical keycode bound to this action.
		var physical_codes: Array[int] = []
		for event: InputEvent in InputMap.action_get_events(action):
			var key := event as InputEventKey
			if key != null:
				physical_codes.append(key.physical_keycode)

		# Assert — the letter is bound by position, never by label.
		assert_bool(physical_codes.has(MOVE_KEYS[action])).override_failure_message(
			"'%s' keeps its physical key (position %d), so AZERTY and QWERTY both move"
			% [action, MOVE_KEYS[action]]
		).is_true()


func test_movement_actions_carry_their_joypad_axis() -> void:
	for action: String in MOVE_AXES:
		# Act — does any event on this action drive the expected axis and sign?
		var bound := false
		for event: InputEvent in InputMap.action_get_events(action):
			var motion := event as InputEventJoypadMotion
			if motion == null:
				continue
			if motion.axis == MOVE_AXES[action][0] \
					and is_equal_approx(motion.axis_value, MOVE_AXES[action][1]):
				bound = true

		# Assert
		assert_bool(bound).override_failure_message(
			"'%s' is driven by joypad axis %d at %+d"
			% [action, MOVE_AXES[action][0], int(MOVE_AXES[action][1])]
		).is_true()


func test_movement_deadzone_matches_run_config() -> void:
	# Arrange
	var config := RunConfig.new()

	# Act / Assert — main._read_move_dir() passes this value to Input.get_vector(),
	# and the InputMap carries it too; the two must not drift apart.
	assert_float(InputMap.action_get_deadzone("move_left")).override_failure_message(
		"the InputMap deadzone equals RunConfig.joy_axis_deadzone"
	).is_equal_approx(config.joy_axis_deadzone, 0.0001)


func test_a_physical_key_event_matches_its_action() -> void:
	# Arrange — the event an AZERTY keyboard sends when the player presses the key
	# at the "A" position: it is labelled Q, but its physical keycode is A.
	var azerty_q_event := InputEventKey.new()
	azerty_q_event.keycode = KEY_Q
	azerty_q_event.physical_keycode = KEY_A
	azerty_q_event.pressed = true

	var two_event := InputEventKey.new()
	two_event.physical_keycode = KEY_2
	two_event.pressed = true

	# Act / Assert
	assert_bool(azerty_q_event.is_action_pressed("move_left")).override_failure_message(
		"the key at the A position moves left on any layout"
	).is_true()
	assert_bool(two_event.is_action_pressed("choice_2")).override_failure_message(
		"physical 2 picks the second level-up choice"
	).is_true()


func test_a_logical_key_event_does_not_match_a_physical_binding() -> void:
	# Arrange — an event that only reports the label, not the position.
	var label_only_event := InputEventKey.new()
	label_only_event.keycode = KEY_Q
	label_only_event.pressed = true

	# Act / Assert — this is the defect the physical bindings exist to prevent:
	# the label Q must not move the knight left.
	assert_bool(label_only_event.is_action_pressed("move_left")).override_failure_message(
		"a logical Q never drives move_left"
	).is_false()
