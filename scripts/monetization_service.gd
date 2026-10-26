extends Node
## MindFox-Monetarisierung mit dem Poing-Studios-AdMob-Plugin und Google Play Billing.
## Auf Nicht-Android-Plattformen bleiben die Werbeaufrufe sicher wirkungslos.

signal topic_unlocked(category: String)
signal purchase_unavailable(category: String)
signal restore_status(message: String)

const BILLING_CLIENT_SCRIPT := preload("res://addons/GodotGooglePlayBilling/BillingClient.gd")
const TOPICS_PATH := "res://data/topics.json"
const ENTITLEMENTS_PATH := "user://mindfox_entitlements.cfg"
const ADS_APP_ID := "ca-app-pub-8473729768789284~5376138618"
const ADS_LOBBY_UNIT_ID := "ca-app-pub-8473729768789284/9651532768"
const ADS_INTERSTITIAL_UNIT_ID := "ca-app-pub-8473729768789284/1544892163"
const BILLING_OK := 0
const BILLING_USER_CANCELED := 1
const BILLING_ITEM_ALREADY_OWNED := 7

var topics: Array = []
var unlocked_products: Dictionary = {}
var billing_client: Node
var ads_plugin: Object
var billing_available := false
var billing_product_details: Dictionary = {}
var pending_purchase_category := ""
var pending_purchase_product_id := ""
var pending_acknowledgements: Dictionary = {}
var restore_query_pending := false
var ads_available := false
var lobby_ad_view: Variant = null
var interstitial_ad: Variant = null
var interstitial_loader: Variant = null
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
	var listener_script := _load_admob_script("listeners/OnInitializationCompleteListener.gd")
	var mobile_ads_script := _load_admob_script("MobileAds.gd")
	var loader_script := _load_admob_script("InterstitialAdLoader.gd")
	if listener_script == null or mobile_ads_script == null or loader_script == null:
		push_warning("AdMob-GDScript-API konnte nicht geladen werden.")
		return
	interstitial_loader = loader_script.new()
	var listener: Variant = listener_script.new()
	listener.on_initialization_complete = func(_status: Variant) -> void:
		ads_initialized = true
		_load_interstitial()
		if pending_ad_request:
			pending_ad_request = false
			_show_banner_ad()
	mobile_ads_script.initialize(listener)


func _load_admob_script(relative_path: String) -> Script:
	return load("res://addons/admob/gdscript/src/api/" + relative_path) as Script

func _load_interstitial() -> void:
	if not ads_available or not ads_initialized:
		return
	var callback_script := _load_admob_script("listeners/InterstitialAdLoadCallback.gd")
	var fullscreen_script := _load_admob_script("listeners/FullScreenContentCallback.gd")
	var request_script := _load_admob_script("core/AdRequest.gd")
	if interstitial_loader == null or callback_script == null or fullscreen_script == null or request_script == null:
		return
	var callback: Variant = callback_script.new()
	callback.on_ad_loaded = func(ad: Variant) -> void:
		interstitial_ad = ad
		var fullscreen: Variant = fullscreen_script.new()
		fullscreen.on_ad_dismissed_full_screen_content = func() -> void:
			if interstitial_ad != null:
				interstitial_ad.destroy()
			interstitial_ad = null
			_load_interstitial()
		fullscreen.on_ad_failed_to_show_full_screen_content = func(_error: Variant) -> void:
			if interstitial_ad != null:
				interstitial_ad.destroy()
				interstitial_ad = null
			_load_interstitial()
		ad.full_screen_content_callback = fullscreen
	callback.on_ad_failed_to_load = func(_error: Variant) -> void:
		interstitial_ad = null
	interstitial_loader.load(ADS_INTERSTITIAL_UNIT_ID, request_script.new(), callback)

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
	if OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling"):
		billing_client = BILLING_CLIENT_SCRIPT.new()
		if billing_client != null:
			add_child(billing_client)
			billing_available = true
			billing_client.connect("connected", Callable(self, "_on_billing_connected"))
			billing_client.connect("connect_error", Callable(self, "_on_billing_connect_error"))
			billing_client.connect("query_product_details_response", Callable(self, "_on_query_product_details_response"))
			billing_client.connect("query_purchases_response", Callable(self, "_on_query_purchases_response"))
			billing_client.connect("on_purchase_updated", Callable(self, "_on_purchase_updated"))
			billing_client.connect("acknowledge_purchase_response", Callable(self, "_on_acknowledge_purchase_response"))
			billing_client.call("start_connection")
	if Engine.has_singleton("PoingGodotAdMob"):
		ads_plugin = Engine.get_singleton("PoingGodotAdMob")
		ads_available = ads_plugin != null

func _paid_product_ids() -> PackedStringArray:
	var product_ids := PackedStringArray()
	for topic in topics:
		if bool(topic.get("free", false)):
			continue
		var product_id := str(topic.get("productId", ""))
		if not product_id.is_empty() and not product_ids.has(product_id):
			product_ids.append(product_id)
	return product_ids

func _on_billing_connected() -> void:
	var product_ids := _paid_product_ids()
	if not product_ids.is_empty():
		billing_client.call("query_product_details", product_ids, BILLING_CLIENT_SCRIPT.ProductType.INAPP)
	billing_client.call("query_purchases", BILLING_CLIENT_SCRIPT.ProductType.INAPP)

func _on_billing_connect_error(response_code: int, debug_message: String) -> void:
	push_warning("Google Play Billing-Verbindung fehlgeschlagen (%d): %s" % [response_code, debug_message])
	if not pending_purchase_product_id.is_empty():
		_fail_pending_purchase()

func _on_query_product_details_response(result: Dictionary) -> void:
	if int(result.get("response_code", -1)) != BILLING_OK:
		push_warning("Google Play-Produktabfrage fehlgeschlagen: %s" % str(result.get("debug_message", "")))
		if not pending_purchase_product_id.is_empty():
			_fail_pending_purchase()
		return
	for product in result.get("product_details", []):
		if not product is Dictionary:
			continue
		var product_id := str(product.get("product_id", ""))
		if not product_id.is_empty():
			billing_product_details[product_id] = product
	if not pending_purchase_product_id.is_empty():
		if billing_product_details.has(pending_purchase_product_id):
			_launch_pending_purchase()
		else:
			_fail_pending_purchase()

func topic_price_label(category: String) -> String:
	var topic := topic_for_category(category)
	if topic.is_empty() or bool(topic.get("free", false)):
		return ""
	var product_id := str(topic.get("productId", ""))
	var product: Dictionary = billing_product_details.get(product_id, {})
	var offers: Variant = product.get("one_time_purchase_offer_details_list", [])
	if offers is Array and not offers.is_empty() and offers[0] is Dictionary:
		return str(offers[0].get("formatted_price", ""))
	return ""

func topic_for_category(category: String) -> Dictionary:
	for topic in topics:
		if str(topic.get("category", "")) == category:
			return topic
	return {}

func is_topic_unlocked(category: String) -> bool:
	var topic := topic_for_category(category)
	if topic.is_empty():
		return false
	if bool(topic.get("free", false)):
		return true
	var product_id := str(topic.get("productId", ""))
	return not product_id.is_empty() and unlocked_products.has(product_id)

func available_topic_categories() -> PackedStringArray:
	var categories := PackedStringArray()
	for topic in topics:
		var category := str(topic.get("category", ""))
		if not category.is_empty() and is_topic_unlocked(category):
			categories.append(category)
	return categories

func purchase_topic(category: String) -> bool:
	var topic := topic_for_category(category)
	if topic.is_empty() or bool(topic.get("free", false)):
		return true
	var product_id := str(topic.get("productId", ""))
	if product_id.is_empty() or not billing_available or billing_client == null:
		purchase_unavailable.emit(category)
		return false
	pending_purchase_category = category
	pending_purchase_product_id = product_id
	if not bool(billing_client.call("is_ready")):
		if int(billing_client.call("get_connection_state")) == BILLING_CLIENT_SCRIPT.ConnectionState.DISCONNECTED:
			billing_client.call("start_connection")
		return true
	if not billing_product_details.has(product_id):
		billing_client.call("query_product_details", PackedStringArray([product_id]), BILLING_CLIENT_SCRIPT.ProductType.INAPP)
		return true
	return _launch_pending_purchase()

func _launch_pending_purchase() -> bool:
	if pending_purchase_product_id.is_empty() or billing_client == null:
		return false
	var product: Dictionary = billing_product_details.get(pending_purchase_product_id, {})
	var offers: Variant = product.get("one_time_purchase_offer_details_list", [])
	if not offers is Array or offers.is_empty() or not offers[0] is Dictionary:
		_fail_pending_purchase()
		return false
	var offer: Dictionary = offers[0]
	var purchase_option_id := str(offer.get("purchase_option_id", ""))
	var raw_offer_id: Variant = offer.get("offer_id", "")
	var offer_id := "" if raw_offer_id == null else str(raw_offer_id)
	var result: Dictionary = billing_client.call("purchase", pending_purchase_product_id, purchase_option_id, offer_id)
	var response_code := int(result.get("response_code", -1))
	if response_code == BILLING_OK:
		return true
	if response_code == BILLING_ITEM_ALREADY_OWNED:
		_clear_pending_purchase()
		billing_client.call("query_purchases", BILLING_CLIENT_SCRIPT.ProductType.INAPP)
		return true
	if response_code != BILLING_USER_CANCELED:
		_fail_pending_purchase()
	else:
		_clear_pending_purchase()
	return false

func _clear_pending_purchase() -> void:
	pending_purchase_category = ""
	pending_purchase_product_id = ""

func _fail_pending_purchase() -> void:
	var category := pending_purchase_category
	_clear_pending_purchase()
	purchase_unavailable.emit(category)

func _on_purchase_updated(result: Dictionary) -> void:
	if int(result.get("response_code", -1)) != BILLING_OK:
		if int(result.get("response_code", -1)) != BILLING_USER_CANCELED and not pending_purchase_product_id.is_empty():
			_fail_pending_purchase()
		else:
			_clear_pending_purchase()
		return
	_process_purchases(result.get("purchases", []))
	_clear_pending_purchase()

func _on_query_purchases_response(result: Dictionary) -> void:
	if int(result.get("response_code", -1)) == BILLING_OK:
		_process_purchases(result.get("purchases", []))
		if restore_query_pending:
			restore_status.emit("Play-Store-Käufe wurden geprüft und synchronisiert.")
	else:
		push_warning("Google Play-Käufe konnten nicht abgefragt werden: %s" % str(result.get("debug_message", "")))
		if restore_query_pending:
			restore_status.emit("Käufe konnten gerade nicht wiederhergestellt werden. Bitte versuche es später erneut.")
	restore_query_pending = false

func _process_purchases(purchases: Variant) -> void:
	if not purchases is Array:
		return
	for purchase in purchases:
		if not purchase is Dictionary:
			continue
		if int(purchase.get("purchase_state", -1)) != BILLING_CLIENT_SCRIPT.PurchaseState.PURCHASED:
			continue
		var raw_ids: Variant = purchase.get("product_ids", [])
		var owned_product_ids := PackedStringArray()
		for product_id in raw_ids:
			var id := str(product_id)
			if _is_configured_product(id) and not owned_product_ids.has(id):
				owned_product_ids.append(id)
		if owned_product_ids.is_empty():
			continue
		if bool(purchase.get("is_acknowledged", false)):
			_grant_product_ids(owned_product_ids)
		else:
			var token := str(purchase.get("purchase_token", ""))
			if not token.is_empty():
				pending_acknowledgements[token] = owned_product_ids
				billing_client.call("acknowledge_purchase", token)

func _on_acknowledge_purchase_response(result: Dictionary) -> void:
	var token := str(result.get("token", ""))
	var product_ids: Variant = pending_acknowledgements.get(token, PackedStringArray())
	pending_acknowledgements.erase(token)
	if int(result.get("response_code", -1)) == BILLING_OK:
		_grant_product_ids(product_ids)
	else:
		push_warning("Google Play-Kauf konnte nicht bestätigt werden: %s" % str(result.get("debug_message", "")))

func _is_configured_product(product_id: String) -> bool:
	for topic in topics:
		if not bool(topic.get("free", false)) and str(topic.get("productId", "")) == product_id:
			return true
	return false

func _grant_product_ids(product_ids: Variant) -> void:
	var granted_any := false
	for product_id in product_ids:
		var id := str(product_id)
		if not _is_configured_product(id):
			continue
		var newly_unlocked := not unlocked_products.has(id)
		unlocked_products[id] = true
		granted_any = true
		if newly_unlocked:
			for topic in topics:
				if str(topic.get("productId", "")) == id:
					topic_unlocked.emit(str(topic.get("category", "")))
	if granted_any:
		_save_entitlements()

func restore_purchases() -> void:
	if billing_client == null or not bool(billing_client.call("is_ready")):
		restore_status.emit("Google Play Billing ist derzeit nicht verbunden. Bitte versuche es später erneut.")
		return
	restore_query_pending = true
	billing_client.call("query_purchases", BILLING_CLIENT_SCRIPT.ProductType.INAPP)

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
		var ad_view_script := _load_admob_script("AdView.gd")
		var size_script := _load_admob_script("core/AdSize.gd")
		var position_script := _load_admob_script("core/AdPosition.gd")
		var request_script := _load_admob_script("core/AdRequest.gd")
		if ad_view_script == null or size_script == null or position_script == null or request_script == null:
			return
		lobby_ad_view = ad_view_script.new(
			ADS_LOBBY_UNIT_ID,
			size_script.get_current_orientation_anchored_adaptive_banner_ad_size(size_script.FULL_WIDTH),
			position_script.BOTTOM
		)
		lobby_ad_view.load_ad(request_script.new())
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
