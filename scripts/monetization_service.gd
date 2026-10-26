extends Node
## MindFox-Monetarisierung mit dem Poing-Studios-AdMob-Plugin und Google Play Billing.
## Auf Nicht-Android-Plattformen bleiben die Werbeaufrufe sicher wirkungslos.

signal topic_unlocked(category: String)
signal purchase_unavailable(category: String)

const TOPICS_PATH := "res://data/topics.json"
const ENTITLEMENTS_PATH := "user://mindfox_entitlements.cfg"
const ADS_APP_ID := "ca-app-pub-8473729768789284~5376138618"
const ADS_LOBBY_UNIT_ID := "ca-app-pub-8473729768789284/9651532768"
const ADS_INTERSTITIAL_UNIT_ID := "ca-app-pub-8473729768789284/1544892163"

var topics: Array = []
var unlocked_products: Dictionary = {}
var billing_plugin: Object
var ads_plugin: Object
var billing_available := false
var ads_available := false
var lobby_ad_view: AdView
var interstitial_ad: InterstitialAd
var interstitial_loader := InterstitialAdLoader.new()
var ads_initialized := false
var pending_ad_request := false

func _ready() -> void:
	_load_topics()
	_load_entitlements()
	_bind_native_plugins()
	call_deferred("_initialize_ads")

func _initialize_ads() -> void:
	if OS.get_name() != "Android":
		return
	if not ads_available and Engine.has_singleton("PoingGodotAdMob"):
		ads_plugin = Engine.get_singleton("PoingGodotAdMob")
		ads_available = ads_plugin != null
	if not ads_available:
		return
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		ads_initialized = true
		_load_interstitial()
		if pending_ad_request:
			pending_ad_request = false
			_show_banner_ad()
	MobileAds.initialize(listener)

func _load_interstitial() -> void:
	if not ads_available or not ads_initialized:
		return
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial_ad = ad
		var fullscreen := FullScreenContentCallback.new()
		fullscreen.on_ad_dismissed_full_screen_content = func() -> void:
			if interstitial_ad != null:
				interstitial_ad.destroy()
			interstitial_ad = null
			_load_interstitial()
		fullscreen.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
			if interstitial_ad != null:
				interstitial_ad.destroy()
				interstitial_ad = null
			_load_interstitial()
		ad.full_screen_content_callback = fullscreen
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		interstitial_ad = null
	interstitial_loader.load(ADS_INTERSTITIAL_UNIT_ID, AdRequest.new(), callback)

func _load_topics() -> void:
	var file := FileAccess.open(TOPICS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.get("topics", []) is Array:
		topics = parsed.get("topics", [])

func _load_entitlements() -> void:
	var config := ConfigFile.new()
	if config.load(ENTITLEMENTS_PATH) != OK:
		return
	var saved: Variant = config.get_value("billing", "products", [])
	if saved is Array:
		for product_id in saved:
			unlocked_products[str(product_id)] = true

func _save_entitlements() -> void:
	var config := ConfigFile.new()
	config.set_value("billing", "products", unlocked_products.keys())
	config.save(ENTITLEMENTS_PATH)

func _bind_native_plugins() -> void:
	# Billing bleibt optional; AdMob wird über das Poing-Plugin eingebunden.
	if Engine.has_singleton("GodotGooglePlayBilling"):
		billing_plugin = Engine.get_singleton("GodotGooglePlayBilling")
		billing_available = billing_plugin != null
		if billing_plugin != null and billing_plugin.has_signal("purchase_completed"):
			billing_plugin.purchase_completed.connect(_on_purchase_completed)
		if billing_plugin != null and billing_plugin.has_method("query_purchases"):
			billing_plugin.query_purchases()
	if Engine.has_singleton("PoingGodotAdMob"):
		ads_plugin = Engine.get_singleton("PoingGodotAdMob")
		ads_available = ads_plugin != null

func topic_for_category(category: String) -> Dictionary:
	for topic in topics:
		if str(topic.get("category", "")) == category:
			return topic
	return {}

func is_topic_unlocked(category: String) -> bool:
	var topic := topic_for_category(category)
	if topic.is_empty() or bool(topic.get("free", false)):
		return true
	return unlocked_products.has(str(topic.get("productId", "")))

func purchase_topic(category: String) -> bool:
	var topic := topic_for_category(category)
	if topic.is_empty() or bool(topic.get("free", false)):
		return true
	var product_id := str(topic.get("productId", ""))
	if product_id.is_empty() or billing_plugin == null or not billing_plugin.has_method("purchase"):
		purchase_unavailable.emit(category)
		return false
	billing_plugin.purchase(product_id)
	return true

func _on_purchase_completed(purchase: Variant) -> void:
	var product_ids: Array = []
	if purchase is Dictionary:
		var raw_ids: Variant = purchase.get("product_ids", purchase.get("products", []))
		if raw_ids is Array:
			product_ids = raw_ids
		elif not str(raw_ids).is_empty():
			product_ids = [str(raw_ids)]
	for product_id in product_ids:
		var id := str(product_id)
		if id.is_empty():
			continue
		unlocked_products[id] = true
		_save_entitlements()
		for topic in topics:
			if str(topic.get("productId", "")) == id:
				topic_unlocked.emit(str(topic.get("category", "")))

func restore_purchases() -> void:
	if billing_plugin != null and billing_plugin.has_method("query_purchases"):
		billing_plugin.query_purchases()

func show_waiting_ad() -> void:
	if OS.get_name() != "Android" or not ads_available or not ads_initialized:
		return
	if interstitial_ad != null:
		interstitial_ad.show()

func show_placement_ad() -> void:
	show_waiting_ad()

func show_lobby_ad() -> void:
	show_home_ad()

func show_home_ad() -> void:
	if OS.get_name() != "Android" or not ads_available:
		return
	if not ads_initialized:
		pending_ad_request = true
		return
	_show_banner_ad()

func _show_banner_ad() -> void:
	if OS.get_name() != "Android" or not ads_available:
		return
	if lobby_ad_view == null:
		lobby_ad_view = AdView.new(
			ADS_LOBBY_UNIT_ID,
			AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH),
			AdPosition.BOTTOM
		)
		lobby_ad_view.load_ad(AdRequest.new())
	else:
		lobby_ad_view.show()

func hide_ads() -> void:
	if interstitial_ad != null:
		# Entfernt ein noch sichtbares Warte-Popup beim Übergang in die nächste Phase.
		interstitial_ad.destroy()
		interstitial_ad = null
		_load_interstitial()
	if lobby_ad_view == null:
		return
	lobby_ad_view.hide()

func _exit_tree() -> void:
	if lobby_ad_view:
		lobby_ad_view.destroy()
		lobby_ad_view = null
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null
