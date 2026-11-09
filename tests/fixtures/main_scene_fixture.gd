## Reusable fixture for tests that need the real main scene.
##
## gdUnit4 collects every script under res://tests that extends GdUnitTestSuite.
## This helper is a plain RefCounted, so it is never collected as a suite; suites
## reference it with preload() instead of a global class_name, which keeps the
## suite runnable on a fresh clone without a regenerated script class cache.
##
## Typical use, from a suite:
## [codeblock]
## const MainSceneFixture := preload("res://tests/fixtures/main_scene_fixture.gd")
##
## func test_main_scene_has_player() -> void:
##     var main := MainSceneFixture.instantiate(self)
##     await MainSceneFixture.await_ready(self)
##     assert_object(main.get_node_or_null("Player")).is_not_null()
## [/codeblock]
extends RefCounted

const MAIN_SCENE_PATH := "res://scenes/main.tscn"


## Instantiates res://scenes/main.tscn as a child of [param suite] and registers
## it with the suite's auto_free. gdUnit4 frees it at the end of the test, so the
## run reports no orphan node (orphans are exit code 101, not 0).
## Returns null when the scene fails to load; the test should assert that.
static func instantiate(suite: Node) -> Node:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("MainSceneFixture: cannot load %s" % MAIN_SCENE_PATH)
		return null
	var main := packed.instantiate()
	suite.add_child(main)
	suite.auto_free(main)
	return main


## Lets [param frames] idle frames pass so the scene's _ready() and first
## _process() calls have run before the assertions.
static func await_ready(suite: Node, frames: int = 3) -> void:
	for _i in frames:
		await suite.get_tree().process_frame


## Stops the wave director: with an empty enemy pool its spawn tick returns
## immediately, so a test only ever sees the enemies it spawns itself.
## Safe to call on a scene that does not expose the pool yet.
static func silence_waves(main: Node) -> void:
	if main != null and "_enemy_pool" in main:
		main._enemy_pool.clear()
