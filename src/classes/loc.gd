## Localized UI text with a French source fallback.
##
## Keys live in `data/localization/strings.csv` and are compiled into the
## `.translation` resources listed in `project.godot`. While a key is missing —
## or the translation system hands the key back unchanged — the caller's French
## source text is shown instead, so a missing translation can never put a raw
## key such as `offer.weapon_upgrade` on screen.
class_name Loc
extends RefCounted


## Translated text of [param key], or [param fallback] when the key is unknown.
static func text(key: String, fallback: String) -> String:
	var translated := String(TranslationServer.translate(key))
	if translated.is_empty() or translated == key:
		return fallback
	return translated


## Translated text of [param key] with [param args] substituted, or
## [param fallback] with the same arguments when the key is unknown.
static func format(key: String, fallback: String, args: Array) -> String:
	return text(key, fallback) % args
