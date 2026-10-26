extends Node

signal locale_changed(locale: String)

const CATALOG_PATHS := {
	"de": "res://localization/de.json",
	"en": "res://localization/en.json",
	"zh-CN": "res://localization/zh-CN.json",
}

var _catalogs: Dictionary = {}
var _locale := "en"


func _ready() -> void:
	for locale: String in CATALOG_PATHS:
		_catalogs[locale] = _load_catalog(str(CATALOG_PATHS[locale]))
	# An explicit player choice wins; otherwise follow the OS language on first launch.
	_locale = resolve_locale(SaveStore.get_locale(), OS.get_locale())
	if not _catalogs.has(_locale):
		_locale = "en"


## Map any OS/browser BCP-47-like tag to the closest bundled catalog.
## Examples: de-DE/de_AT -> de, zh-Hans/zh-TW -> zh-CN, everything else -> en.
static func detect_locale(os_locale: String) -> String:
	var normalized := os_locale.strip_edges().replace("_", "-").to_lower()
	var language := normalized.split("-", false)[0] if not normalized.is_empty() else ""
	if language == "zh" or language == "cmn" or language == "yue":
		return "zh-CN"
	if language == "de":
		return "de"
	# English is the worldwide fallback for all other system languages.
	return "en"


## `saved` is the persisted player choice, or "" when the player never picked a language.
static func resolve_locale(saved: String, os_locale: String) -> String:
	if saved in ["de", "en", "zh-CN"]:
		return saved
	return detect_locale(os_locale)


func system_locale() -> String:
	return detect_locale(OS.get_locale())


func _load_catalog(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("I18n: missing catalog " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("I18n: invalid catalog " + path)
		return {}
	return parsed


func text(key: String, replacements: Dictionary = {}) -> String:
	var active: Dictionary = _catalogs.get(_locale, {})
	var fallback: Dictionary = _catalogs.get("en", {})
	var result := str(active.get(key, fallback.get(key, key)))
	for token: Variant in replacements:
		result = result.replace("{%s}" % str(token), str(replacements[token]))
	return result


func t(key: String, replacements: Dictionary = {}) -> String:
	return text(key, replacements)


func get_locale() -> String:
	return _locale


func set_locale(locale: String) -> void:
	if not _catalogs.has(locale):
		return
	# An explicit choice is persisted even when it matches the auto-detected language.
	if SaveStore.get_locale() != locale:
		SaveStore.set_locale(locale)
	if locale == _locale:
		return
	_locale = locale
	locale_changed.emit(locale)


func toggle_locale() -> void:
	var locales := ["de", "en", "zh-CN"]
	var index := locales.find(_locale)
	set_locale(locales[(index + 1) % locales.size()])


func catalog_keys(locale: String) -> Array:
	var catalog: Dictionary = _catalogs.get(locale, {})
	return catalog.keys()
