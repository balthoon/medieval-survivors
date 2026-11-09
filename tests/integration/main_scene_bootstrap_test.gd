## Integration smoke test for the real main scene (W0-E1).
##
## Proves MainSceneFixture can instantiate res://scenes/main.tscn under the
## gdUnit4 runner and that the scene still exposes the two nodes the later
## ported suites (W0-E2) depend on.
extends GdUnitTestSuite

const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")


func test_main_scene_provides_player_and_enemy_manager() -> void:
	# Arrange
	var main := MainSceneFixture.instantiate(self)
	assert_object(main).is_not_null()
	if main == null:
		return
	await MainSceneFixture.await_ready(self)

	# Act
	var player := main.get_node_or_null("Player")
	var manager := main.get_node_or_null("EnemyManager")

	# Assert
	assert_object(player).is_not_null()
	assert_object(manager).is_not_null()
