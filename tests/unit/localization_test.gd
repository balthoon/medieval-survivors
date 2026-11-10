## W8-E1: the localization base. The French source strings live in
## data/localization/strings.csv, Godot imports one .translation per locale, and
## project.godot loads both and falls back to French.
##
## These tests pin the contract W8-E2 (string extraction) relies on: the CSV
## columns, the registered translation resources, the fr/en switch, and the
## French fallback for a key or a whole locale with no translation.
extends GdUnitTestSuite

const CSV_PATH := "res://data/localization/strings.csv"
const FR_TRANSLATION_PATH := "res://data/localization/strings.fr.translation"
const EN_TRANSLATION_PATH := "res://data/localization/strings.en.translation"

## Locale active before a test runs, restored afterwards so no other suite
## inherits a leftover "fr" or "en".
var _original_locale: String = ""


func before_test() -> void:
	# Arrange
	_original_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_original_locale)


func test_fallback_locale_is_french() -> void:
	# Arrange / Act
	var fallback := String(
		ProjectSettings.get_setting("internationalization/locale/fallback")
	)

	# Assert
	assert_str(fallback).override_failure_message(
		"the project falls back to the French source locale"
	).is_equal("fr")


func test_csv_declares_french_and_english_columns() -> void:
	# Arrange
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_object(file).override_failure_message(
		"strings.csv is readable"
	).is_not_null()
	if file == null:
		return

	# Act
	var header := file.get_csv_line()
	file.close()

	# Assert
	assert_str(header[0]).override_failure_message(
		"the first CSV column holds the localization keys"
	).is_equal("keys")
	assert_bool(header.has("fr")).override_failure_message(
		"the CSV declares a French column"
	).is_true()
	assert_bool(header.has("en")).override_failure_message(
		"the CSV declares an English column"
	).is_true()


func test_translation_resources_are_registered() -> void:
	# Arrange
	var translations := ProjectSettings.get_setting(
		"internationalization/locale/translations"
	) as PackedStringArray

	# Assert
	assert_bool(translations.has(FR_TRANSLATION_PATH)).override_failure_message(
		"project.godot loads the imported French translation"
	).is_true()
	assert_bool(translations.has(EN_TRANSLATION_PATH)).override_failure_message(
		"project.godot loads the imported English translation"
	).is_true()
	assert_bool(FileAccess.file_exists(FR_TRANSLATION_PATH)).override_failure_message(
		"the CSV import produced strings.fr.translation"
	).is_true()
	assert_bool(FileAccess.file_exists(EN_TRANSLATION_PATH)).override_failure_message(
		"the CSV import produced strings.en.translation"
	).is_true()


func test_key_translates_to_french_in_french_locale() -> void:
	# Arrange
	TranslationServer.set_locale("fr")

	# Act / Assert
	assert_str(TranslationServer.translate("hud.hp")).override_failure_message(
		"'hud.hp' is 'VIE' in French"
	).is_equal("VIE")
	assert_str(TranslationServer.translate("hud.wave")).override_failure_message(
		"'hud.wave' is 'Vague' in French"
	).is_equal("Vague")
	assert_str(TranslationServer.translate("end.victory.title")).override_failure_message(
		"the victory title is French"
	).is_equal("Victoire !")


func test_key_translates_to_english_in_english_locale() -> void:
	# Arrange
	TranslationServer.set_locale("en")

	# Act / Assert
	assert_str(TranslationServer.translate("hud.hp")).override_failure_message(
		"'hud.hp' is 'HP' in English"
	).is_equal("HP")
	assert_str(TranslationServer.translate("hud.wave")).override_failure_message(
		"'hud.wave' is 'Wave' in English"
	).is_equal("Wave")
	assert_str(TranslationServer.translate("end.victory.title")).override_failure_message(
		"the victory title is English"
	).is_equal("Victory!")


func test_key_missing_from_english_falls_back_to_french() -> void:
	# Arrange — game.tagline has no English cell in the CSV.
	TranslationServer.set_locale("en")

	# Act
	var translated := TranslationServer.translate("game.tagline")

	# Assert
	assert_str(translated).override_failure_message(
		"a key with no English translation falls back to the French source"
	).is_equal("Un conte de survie médiévale")


func test_locale_with_no_translation_falls_back_to_french() -> void:
	# Arrange — nothing in the project translates to German yet.
	TranslationServer.set_locale("de")

	# Act / Assert
	assert_str(TranslationServer.translate("hud.hp")).override_failure_message(
		"an unsupported locale falls back to the French source"
	).is_equal("VIE")
