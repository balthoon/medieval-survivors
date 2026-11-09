## Entry-gate check for the test harness itself (W0-E1).
##
## It proves three things at once: the vendored gdUnit4 runner discovers suites
## under res://tests, executes GDScript assertions, and reports the result to the
## process exit code. It stays in the suite so CI never passes on zero tests.
extends GdUnitTestSuite


func test_assertion_int_equality_is_enforced() -> void:
	# Arrange
	var two := 1 + 1

	# Act / Assert
	assert_int(two).is_equal(2)
