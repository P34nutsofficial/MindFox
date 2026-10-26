extends Control
## MindFox – Die Lügenrunde
## Eine lokale, creditsparende Host-Beta mit klarer State Machine.

const FONT_REGULAR := preload("res://assets/template/fonts/ui_regular.tres")
const FONT_BOLD := preload("res://assets/template/fonts/ui_bold.tres")
const STAGE_BACKDROP := preload("res://assets/mindfox_party/runtime/stage_backdrop.jpg")
const MINDFOX_MASCOT := preload("res://brand/final/mindfox_quizmaster_tail_x.png")
const MINDFOX_APP_ICON := preload("res://brand/final/mindfox_app_icon_tail_x_quizmaster.png")
const MINDFOCK_HOST_BANNER := preload("res://brand/final/mindfock_host_banner.png")
const MINDFOX_TOP_LOGO := preload("res://brand/final/mindfox_top_logo.png")
const QUESTION_BADGE := preload("res://assets/mindfox_party/runtime/question_badge.png")
const COLOR_BG := Color("0b1020")
const COLOR_SURFACE := Color("141b31")
const COLOR_SURFACE_2 := Color("1b2642")
const COLOR_INK := Color("f6f7fb")
const COLOR_MUTED := Color("9ba8c7")
const COLOR_ACCENT := Color("ffcc66")
const COLOR_CYAN := Color("63e6e2")
const COLOR_GREEN := Color("7fe2a8")
const COLOR_RED := Color("ff7b8e")
const COLOR_PURPLE := Color("b99cff")
const REACTION_EMOJIS := ["🔥", "🤡", "🚀", "💩"]
const MAX_PLAYERS := 8
const MIN_ROUNDS := 3
const ROUND_COUNT_MAX := 15
const CHALLENGE_REWARD_SHARE := 0.20
const RECONNECT_GRACE_MS := 45000
const LANDSCAPE_CONTENT_SCALE := Vector2i(1280, 720)
const PORTRAIT_CONTENT_SCALE := Vector2i(720, 1280)
const SHOWRUNNER_PATH := "res://data/showrunner.json"
const CHALLENGE_TASKS_PATH := "res://data/challenge_tasks.json"
const QUESTION_HISTORY_PATH := "user://question_history.json"
const EMBEDDED_LAN_SERVER := preload("res://scripts/embedded_lan_server.gd")
const NATIVE_PLAYER_CLIENT := preload("res://scripts/native_player_client.gd")
const AAA_STAGE_FX := preload("res://scripts/aaa_stage_fx.gd")
const PLAYER_ROCKET_EFFECT := preload("res://scripts/player_rocket_effect.gd")
const AAA_AUDIO := preload("res://scripts/aaa_audio.gd")
const AVATAR_CATALOG := preload("res://scripts/avatar_catalog.gd")
const GAME_RULES := preload("res://scripts/game_rules.gd")
const GLASS_SHADER := preload("res://shaders/glass_panel.gdshader")
const NEON_SHADER := preload("res://shaders/neon_pulse.gdshader")
const FOIL_SHADER := preload("res://shaders/foil_holographic.gdshader")
const DISCOVERY_CATEGORIES := ["Bizarres Halbwissen & Kuriose Gesetze", "Verrückte Tierwelt & Natur", "Absurde Geschichte & Erfindungen"]
const ALL_AVAILABLE_CATEGORY := "Geben Alles"
const AVATAR_NAMES := AVATAR_CATALOG.NAMES
const AVATAR_ICONS := AVATAR_CATALOG.LABELS
const AVATAR_IMAGES: Array[Texture2D] = AVATAR_CATALOG.IMAGES
const AVATAR_TINTS := ["CYAN", "GOLD", "VIOLETT", "LIMETTE", "KORALLE"]
const AVATAR_EXPRESSIONS := ["POKERFACE", "GRINSEN", "SCHOCK", "ZWINKERN"]

enum Phase { LOBBY, INPUT, VOTING, REVEAL, SCOREBOARD, PODIUM }
enum ReadyState { WAITING_FOR_PLAYERS, PLAYER_NOT_READY, SELF_READY, ALL_READY, HOST_STARTING, BLOCKED }

var phase: Phase = Phase.LOBBY
var round_index := 0
var max_rounds := 8
var countdown := 45.0
var room_code := ""
var local_ip := "192.168.43.1"
var local_ip_addresses: Array[String] = []
var network_has_link := false
var network_interface_name := ""
var questions: Array = []
var played_question_ids: Dictionary = {}
var challenge_tasks: Array = []
var challenge_pool_order: Array = []
var challenge_pool_cursor := 0
var challenge_session_active := false
var challenge_rewards_settled := false
var secret_missions_enabled := true
var confidence_system_enabled := true
var players: Array = []
var active_question: Dictionary = {}
var current_options: Array = []
var host_selected_option := ""
var votes: Dictionary = {}
var target_counts: Dictionary = {}
var rng := RandomNumberGenerator.new()
var podium_quips: Dictionary = {}
var chain_bluff := false
var previous_best_lie := ""
var confidence_slider: HSlider
var confidence_value_label: Label
var confidence_preview_label: Label
var host_vote_selection_label: Label
var role_brief: Dictionary = {}
var showrunner_config: Dictionary = {}
var showrunner_mode := "showrunner_mix"
var showrunner_mode_index := 1
var current_directive: Dictionary = {}
var embedded_lan: Node
var portrait_layout := false

var body: VBoxContainer
var phase_label: Label
var top_header: HBoxContainer
var brand_title_label: Label
var brand_subtitle_label: Label
var brand_logo_image: TextureRect
var room_label: Label
var footer_label: Label
var challenge_dock: PanelContainer
var challenge_header_label: Label
var challenge_text_label: Label
var challenge_caught_button: CheckButton
var challenge_detail_row: VBoxContainer
var challenge_toggle_button: Button
var challenge_details_open := false
var native_challenge_text := ""
var native_challenge_caught := false
var native_challenge_bonus := 0
var native_challenge_resolved := false
var body_scroll: ScrollContainer
var score_hud: PanelContainer
var score_own_label: Label
var score_leader_label: Label
var touch_scroll_active := false
var touch_scroll_dragged := false
var touch_scroll_origin_y := 0.0
var action_bar: VBoxContainer
var timer_label: Label
var timer_bar: ProgressBar
var feedback_label: Label
var admin_drawer: VBoxContainer
var answer_input: LineEdit
var answer_submit_button: Button
var native_answer_submit_button: Button
var host_vote_continue_button: Button
var native_vote_continue_button: Button
var _timer_refresh := -1
var host_gate_ready := false
var submitted_lies: Dictionary = {}
var submitted_votes: Dictionary = {}
var app_mode := "HOME"
var native_client: Node
var join_name_input: LineEdit
var host_name_input: LineEdit
var round_count_selector: OptionButton
var join_host_input: LineEdit
var join_room_input: LineEdit
var join_feedback_label: Label
var native_status_label: Label
var native_question_id := ""
var native_submitted := false
var native_selected_option := ""
var native_vote_pending := false
var native_vote_ack_timeout := 0.0
var native_score_status: Dictionary = {"ownScore": 0, "leaderScore": 0, "leaderName": "Noch offen"}
var native_room_players: Array = []
var native_lobby_rounds := 8
var native_lobby_category := "Geben Alles"
var native_gate_ready := false
var native_question_label: Label
var native_round_label: Label
var native_feedback_label: Label
var host_connection_details_box: VBoxContainer
var network_join_details_box: VBoxContainer
var network_join_toggle_button: Button
var network_join_expanded := false
var native_reveal_payload: Dictionary = {}
var native_gate_payload: Dictionary = {}
var gate_transition_seconds := -1.0
var gate_transition_kind := ""
var gate_transition_last_second := -1
var gate_countdown_label: Label
var stage_fx: Control
var rocket_effect_overlay: Control
var aaa_audio: Node
var _last_emoji_ms := 0
var _emoji_cooldown_ms := 335
var _last_emoji := ""
var question_order: Array = []
var estimation_question_order: Array = []
var estimation_questions_available := false
var tiebreak_active := false
var tiebreak_players: Array[String] = []
var selected_category := "Bizarres Halbwissen & Kuriose Gesetze"
var selected_avatar := 0
var selected_avatar_tint := 0
var selected_avatar_expression := 0
var discovery_box: VBoxContainer
var discovery_empty_label: Label
var discovered_rooms: Dictionary = {}
var discovery_room_buttons: Dictionary = {}
var discovery_elapsed := 0.0
var discovery_timeout_shown := false
var reduced_motion_user := false
var manual_join_card: PanelContainer
var avatar_preview_label: Label
var round_progress_label: Label
var _performance_profile := ""
var last_error_message := ""
var diagnostics_button: Button
var start_show_button: Button
var _brand_click_count := 0
var _brand_last_click_ms := 0
var network_reveal_snapshot: Dictionary = {}
var network_score_snapshot: Dictionary = {}
var network_podium_snapshot: Dictionary = {}
var reveal_details_panel: VBoxContainer
var reveal_details_toggle: Button
var reveal_details_open := false

func _derive_ready_state(self_ready: bool, ready_count: int, total: int) -> ReadyState:
	if total < 2:
		return ReadyState.BLOCKED
	if ready_count >= total:
		return ReadyState.ALL_READY
	if self_ready:
		return ReadyState.SELF_READY
	return ReadyState.PLAYER_NOT_READY

func _ready_state_copy(state: ReadyState, waiting_count: int = 0) -> String:
	match state:
		ReadyState.WAITING_FOR_PLAYERS:
			return "Warte auf Spieler …"
		ReadyState.PLAYER_NOT_READY:
			return "Du bist noch nicht bereit"
		ReadyState.SELF_READY:
			return "Du bist bereit · warte auf %d" % waiting_count
		ReadyState.ALL_READY:
			return "Alle bereit · Start möglich"
		ReadyState.HOST_STARTING:
			return "Runde startet …"
		ReadyState.BLOCKED:
			return "Mindestens zwei Spieler erforderlich"
	return "Bereit wird synchronisiert …"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_accessibility_settings()
	rng.randomize()
	_refresh_network_info()
	aaa_audio = AAA_AUDIO.new()
	add_child(aaa_audio)
	native_client = NATIVE_PLAYER_CLIENT.new()
	add_child(native_client)
	native_client.connected.connect(_on_native_connected)
	native_client.disconnected.connect(_on_native_disconnected)
	native_client.connection_state_changed.connect(_on_native_connection_state)
	native_client.message_received.connect(_on_native_message)
	native_client.discovery_room_found.connect(_on_discovery_room_found)
	native_client.discovery_room_expired.connect(_on_discovery_room_expired)
	I18n.locale_changed.connect(_on_locale_changed)
	_load_questions()
	_load_challenge_tasks()
	_load_showrunner()
	Monetization.topic_unlocked.connect(_on_topic_unlocked)
	Monetization.purchase_unavailable.connect(_on_topic_purchase_unavailable)
	Monetization.restore_status.connect(_on_restore_status)
	_reset_players()
	_build_shell()
	_set_game_orientation(true)
	rocket_effect_overlay = PLAYER_ROCKET_EFFECT.new()
	rocket_effect_overlay.name = "PlayerRocketEffect"
	rocket_effect_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rocket_effect_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rocket_effect_overlay.z_index = 100
	add_child(rocket_effect_overlay)
	_show_welcome()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		call_deferred("_handle_app_resume")

func _handle_app_resume() -> void:
	_refresh_network_info()
	if app_mode == "CLIENT" and native_client != null:
		if native_status_label != null and is_instance_valid(native_status_label):
			native_status_label.text = "● APP AKTIV · VERBINDUNG WIRD GEPRÜFT"
		native_client.send_ping()
	elif app_mode == "HOST" and embedded_lan != null:
		embedded_lan.publish([{"type": "HOST_RESUMED", "payload": {"network": network_interface_name, "hasLink": network_has_link}}])

func _process(delta: float) -> void:
	_expire_paused_players()
	_set_performance_profile()
	if app_mode == "JOIN" and phase == Phase.LOBBY and not discovery_timeout_shown and discovered_rooms.is_empty():
		discovery_elapsed += delta
		if discovery_elapsed >= 6.0 and discovery_empty_label != null and is_instance_valid(discovery_empty_label):
			discovery_timeout_shown = true
			discovery_empty_label.text = "Kein Raum gefunden. Prüfe, ob der Host die Lobby geöffnet hat, oder nutze den manuellen Fallback."
			discovery_empty_label.add_theme_color_override("font_color", COLOR_ACCENT)
	if native_vote_pending:
		if phase != Phase.VOTING or app_mode != "CLIENT":
			native_vote_pending = false
		else:
			native_vote_ack_timeout = maxf(0.0, native_vote_ack_timeout - delta)
		if native_vote_pending and native_vote_ack_timeout <= 0.0:
			native_vote_pending = false
			_show_native_voting_feedback("Keine Bestätigung vom Host erhalten. Dein Tipp ist noch auswählbar – bitte erneut senden.", true)
	if gate_transition_seconds >= 0.0:
		gate_transition_seconds = maxf(0.0, gate_transition_seconds - delta)
		var gate_second := int(ceil(gate_transition_seconds))
		if gate_second != gate_transition_last_second:
			gate_transition_last_second = gate_second
			_show_flying_countdown(gate_second)
			if embedded_lan != null:
				embedded_lan.publish([{"type": "GATE_COUNTDOWN", "payload": {"seconds": gate_second, "gate": gate_transition_kind}}])
			if gate_second > 0:
				aaa_audio.play_cue("tick", 1.12)
				aaa_audio.haptic(22)
		if gate_transition_seconds <= 0.0:
			var completed_kind := gate_transition_kind
			gate_transition_seconds = -1.0
			gate_transition_kind = ""
			gate_transition_last_second = -1
			if embedded_lan != null:
				embedded_lan.publish([{"type": "GATE_COUNTDOWN", "payload": {"seconds": 0, "gate": completed_kind, "done": true}}])
			if gate_countdown_label != null and is_instance_valid(gate_countdown_label):
				gate_countdown_label.queue_free()
			gate_countdown_label = null
			_advance_after_gate(completed_kind)
		return
	if phase != Phase.INPUT and phase != Phase.VOTING and phase != Phase.REVEAL and phase != Phase.SCOREBOARD:
		return
	if phase == Phase.REVEAL and embedded_lan != null and embedded_lan.gate_active:
		return
	countdown = maxf(0.0, countdown - delta)
	var seconds := int(ceil(countdown))
	if seconds != _timer_refresh:
		_timer_refresh = seconds
		if timer_label != null:
			timer_label.text = "%02d s" % seconds
		if timer_bar != null:
			timer_bar.value = countdown
			if seconds > 0 and seconds <= 5:
				aaa_audio.play_cue("tick", 1.0 + float(5 - seconds) * 0.07)
				aaa_audio.haptic(18)
			elif seconds > 5 and seconds <= 10:
				aaa_audio.play_cue("tension", 0.92 + float(10 - seconds) * 0.02)
		if stage_fx != null and seconds > 0 and seconds <= 5:
			stage_fx.pulse_attention()
	if countdown > 0.0:
		return
	match phase:
		Phase.INPUT:
			if app_mode == "CLIENT":
				_submit_native_answer(true)
			else:
				_submit_player_answer(true)
		Phase.VOTING:
			if app_mode == "CLIENT":
				_confirm_native_vote(true)
			else:
				_confirm_host_vote(true)
		Phase.REVEAL:
			if app_mode != "CLIENT":
				if tiebreak_active:
					_show_podium()
				else:
					_show_scoreboard()
		Phase.SCOREBOARD:
			pass
		Phase.PODIUM:
			pass

func _input(event: InputEvent) -> void:
	if body_scroll == null or not is_instance_valid(body_scroll):
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			touch_scroll_active = body_scroll.get_global_rect().has_point(touch.position)
			touch_scroll_dragged = false
			touch_scroll_origin_y = touch.position.y
		else:
			touch_scroll_active = false
			touch_scroll_dragged = false
	elif event is InputEventScreenDrag and touch_scroll_active:
		var drag := event as InputEventScreenDrag
		if not touch_scroll_dragged and absf(drag.position.y - touch_scroll_origin_y) >= 8.0:
			touch_scroll_dragged = true
		if touch_scroll_dragged:
			body_scroll.scroll_vertical -= int(round(drag.relative.y))
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return
	if admin_drawer != null and is_instance_valid(admin_drawer):
		_toggle_admin_drawer()
		get_viewport().set_input_as_handled()
		return
	if manual_join_card != null and is_instance_valid(manual_join_card) and manual_join_card.visible:
		_toggle_manual_join()
		get_viewport().set_input_as_handled()
		return
	if app_mode == "JOIN":
		_show_welcome()
		get_viewport().set_input_as_handled()
		return
	if app_mode == "CLIENT" and phase == Phase.LOBBY:
		_confirm_leave_native_game()
		get_viewport().set_input_as_handled()
		return
	if app_mode == "HOST" and phase == Phase.LOBBY:
		_confirm_stop_host()
		get_viewport().set_input_as_handled()
		return
	# Während einer laufenden Runde niemals versehentlich den Spielzustand verlassen.
	get_viewport().set_input_as_handled()

func _set_performance_profile() -> void:
	var desired := "ACTIVE" if phase == Phase.INPUT or phase == Phase.VOTING or phase == Phase.REVEAL or phase == Phase.SCOREBOARD else "IDLE"
	if desired == _performance_profile:
		return
	_performance_profile = desired
	Engine.max_fps = 60 if desired == "ACTIVE" else 30

func _load_questions() -> void:
	estimation_questions_available = false
	var file := FileAccess.open(_localized_data_path("questions.json"), FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			questions = parsed
	if questions.is_empty():
			questions = [{"id": "q001", "prompt": "Welche kuriose Tatsache stimmt?", "truth": "Das Beispiel ist korrekt", "fallbackDecoys": ["Eine sehr überzeugende Fälschung", "Ein erfundener Rekord"]}]

	for question in questions:
		if question.has("estimate_value"):
			estimation_questions_available = true
	_load_question_history()

func _load_question_history() -> void:
	played_question_ids.clear()
	if not FileAccess.file_exists(QUESTION_HISTORY_PATH):
		return
	var file := FileAccess.open(QUESTION_HISTORY_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var saved_ids: Variant = parsed.get("playedIds", [])
	if not (saved_ids is Array):
		return
	for raw_id in saved_ids:
		var question_id := str(raw_id).strip_edges()
		if not question_id.is_empty():
			played_question_ids[question_id] = true

func _save_question_history() -> void:
	var file := FileAccess.open(QUESTION_HISTORY_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Fragenverlauf konnte nicht gespeichert werden: " + str(FileAccess.get_open_error()))
		return
	var saved_ids: Array = played_question_ids.keys()
	saved_ids.sort()
	file.store_string(JSON.stringify({"version": 1, "playedIds": saved_ids}))

func _mark_question_seen(question: Dictionary) -> void:
	var question_id := str(question.get("id", "")).strip_edges()
	if question_id.is_empty() or played_question_ids.has(question_id):
		return
	played_question_ids[question_id] = true
	_save_question_history()

func _load_challenge_tasks() -> void:
	challenge_tasks.clear()
	var file := FileAccess.open(_localized_data_path("challenge_tasks.json"), FileAccess.READ)
	if file == null:
		push_error("Geheimmissionen fehlen: " + CHALLENGE_TASKS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.get("tasks", []) is Array:
		challenge_tasks = parsed.get("tasks", [])
	if challenge_tasks.size() != 300:
		push_error("Erwartet werden genau 300 Geheimmissionen; gefunden: %d" % challenge_tasks.size())

func _load_showrunner() -> void:
	var file := FileAccess.open(_localized_data_path("showrunner.json"), FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			showrunner_config = parsed
	if showrunner_config.is_empty():
		showrunner_config = {"defaultMode": "classic", "modes": []}

func _localized_data_path(base_name: String) -> String:
	var locale := I18n.get_locale() if I18n != null else "en"
	var dot := base_name.rfind(".")
	var candidate := "res://data/%s.%s%s" % [base_name.substr(0, dot), locale, base_name.substr(dot)] if dot >= 0 else "res://data/%s.%s" % [base_name, locale]
	return candidate if FileAccess.file_exists(candidate) else "res://data/%s" % base_name

func _reset_players() -> void:
	var host_name := "Du"
	if host_name_input != null and not host_name_input.text.strip_edges().is_empty():
		host_name = host_name_input.text.strip_edges().left(18)
	players = [
		{"id": "host", "name": host_name, "avatarIndex": selected_avatar, "avatarTint": selected_avatar_tint, "avatarExpression": selected_avatar_expression, "avatar_expression": AVATAR_EXPRESSIONS[selected_avatar_expression], "score": 0, "lie": "", "fooled": 0, "deceived_total": 0, "correct": 0, "delta": 0, "confidence": 50, "confidence_award": "", "role": "", "role_hint": "", "role_task": "", "is_host": true, "is_human": true, "active": true, "connected": true, "reconnectDeadlineMs": 0},
	]

func _new_room_code() -> String:
	var alphabet := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code := ""
	for _i in range(4):
		code += alphabet.substr(rng.randi_range(0, alphabet.length() - 1), 1)
	return code

func _refresh_network_info() -> bool:
	var info := _network_info()
	network_has_link = bool(info.get("has_link", false))
	network_interface_name = str(info.get("interface", ""))
	local_ip_addresses.clear()
	for address in info.get("addresses", []):
		var candidate := str(address)
		if not candidate.is_empty() and not local_ip_addresses.has(candidate):
			local_ip_addresses.append(candidate)
	if network_has_link:
		local_ip = str(info.get("address", local_ip))
	if embedded_lan != null and is_instance_valid(embedded_lan):
		embedded_lan.set_mdns_ip(local_ip)
		embedded_lan.set_host_ip_candidates(local_ip_addresses)
	return network_has_link

func _network_info() -> Dictionary:
	var preferred: Array[String] = []
	var preferred_interface := ""
	var fallback: Array[String] = []
	var fallback_interface := ""
	for interface in IP.get_local_interfaces():
		var interface_name := str(interface.get("name", "")).to_lower()
		var is_virtual := interface_name.begins_with("lo") or interface_name.contains("docker") or interface_name.contains("veth") or interface_name.contains("tailscale") or interface_name.contains("tun") or interface_name.contains("vpn") or interface_name.contains("wireguard") or interface_name.begins_with("wg") or interface_name.contains("rmnet") or interface_name.contains("ccmni") or interface_name.contains("wwan") or interface_name.contains("dummy")
		if is_virtual:
			continue
		var is_wifi_like := interface_name.contains("wlan") or interface_name.contains("wifi") or interface_name.contains("swlan") or interface_name.contains("ap")
		for address in interface.get("addresses", []):
			var candidate := str(address)
			if candidate.count(".") == 3 and not candidate.begins_with("127.") and not candidate.begins_with("169.254."):
				var target: Array[String] = preferred if is_wifi_like else fallback
				if not target.has(candidate):
					target.append(candidate)
				if is_wifi_like:
					preferred_interface = interface_name
				else:
					fallback_interface = interface_name
	var candidates: Array[String] = preferred.duplicate()
	for address in fallback:
		if not candidates.has(address):
			candidates.append(address)
	if not preferred.is_empty():
		return {"has_link": true, "address": preferred[0], "addresses": candidates, "interface": preferred_interface, "wifi": true}
	if not fallback.is_empty():
		return {"has_link": true, "address": fallback[0], "addresses": candidates, "interface": fallback_interface, "wifi": false}
	return {"has_link": false, "address": "", "addresses": [], "interface": "", "wifi": false}

func _local_network_ip() -> String:
	var info := _network_info()
	return str(info.get("address", "192.168.43.1")) if bool(info.get("has_link", false)) else "192.168.43.1"

func _set_game_orientation(portrait: bool) -> void:
	portrait_layout = portrait
	var window := get_window()
	window.content_scale_size = PORTRAIT_CONTENT_SCALE if portrait else LANDSCAPE_CONTENT_SCALE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if portrait else Window.CONTENT_SCALE_ASPECT_KEEP
	if DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT if portrait else DisplayServer.SCREEN_LANDSCAPE)
	# The top row has fixed-size controls; collapse it on narrow portrait phones.
	if top_header != null:
		top_header.add_theme_constant_override("separation", 5 if portrait else 14)
	if room_label != null:
		room_label.visible = not portrait
	if phase_label != null:
		phase_label.custom_minimum_size = Vector2(116, 48) if portrait else Vector2(150, 52)
		phase_label.add_theme_font_size_override("font_size", 12 if portrait else 16)
		if diagnostics_button != null:
			diagnostics_button.custom_minimum_size = Vector2(82, 44) if portrait else Vector2(120, 52)
			diagnostics_button.add_theme_font_size_override("font_size", 9 if portrait else 11)
		if brand_title_label != null:
			brand_title_label.add_theme_font_size_override("font_size", 21 if portrait else 29)
		if brand_logo_image != null:
			brand_logo_image.custom_minimum_size = Vector2(156 if portrait else 210, 42 if portrait else 48)
		if brand_subtitle_label != null:
			brand_subtitle_label.add_theme_font_size_override("font_size", 10 if portrait else 15)

func _ensure_host_server() -> void:
	if embedded_lan != null and is_instance_valid(embedded_lan):
		return
	embedded_lan = EMBEDDED_LAN_SERVER.new()
	add_child(embedded_lan)
	embedded_lan.set_mdns_ip(local_ip)
	embedded_lan.set_host_ip_candidates(local_ip_addresses)
	embedded_lan.set_discovery_metadata("Bluff-Host", selected_category)
	embedded_lan.gate_completed.connect(_on_gate_completed)
	embedded_lan.client_event.connect(_on_client_event)

func _show_welcome() -> void:
	app_mode = "HOME"
	if start_show_button != null and is_instance_valid(start_show_button):
		start_show_button.visible = true
	challenge_dock.visible = false
	if score_hud != null:
		score_hud.visible = false
	host_name_input = null
	if native_client != null:
		native_client.stop_discovery()
	_set_game_orientation(true)
	phase = Phase.LOBBY
	room_code = ""
	_set_phase_text("HOME")
	if room_label != null:
		room_label.text = "LOKALES WLAN"
	_clear_body()
	var hero := _card(Color("121b38"), Color(COLOR_CYAN, 0.42))
	hero.custom_minimum_size.y = 350
	body.add_child(hero)
	var hero_image := TextureRect.new()
	hero_image.texture = MINDFOCK_HOST_BANNER
	hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(hero_image)

	var action_card := _card(Color("10172e"), Color(COLOR_PURPLE, 0.38))
	body.add_child(action_card)
	var action_box := VBoxContainer.new()
	action_card.add_child(action_box)
	action_box.add_theme_constant_override("separation", 10)
	var prompt := _label(_ui_text("mf.home.prompt", "Wie startet ihr die Show?"), 18, COLOR_INK, true)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_box.add_child(prompt)
	var host_button := _button(_ui_text("mf.home.host", "SPIEL HOSTEN\nDu eröffnest die Runde"), Color(COLOR_ACCENT, 0.24), Callable(self, "_start_host_mode"))
	host_button.custom_minimum_size.y = 82
	host_button.add_theme_font_size_override("font_size", 19)
	action_box.add_child(host_button)
	var join_button := _button(_ui_text("mf.home.join", "SPIEL BEITRETEN\nIm WLAN suchen oder Code nutzen"), Color(COLOR_CYAN, 0.17), Callable(self, "_show_join_screen"))
	join_button.custom_minimum_size.y = 82
	join_button.add_theme_font_size_override("font_size", 19)
	action_box.add_child(join_button)

	var note := _label(_ui_text("mf.home.note", "2–8 Spieler · gemeinsames WLAN · ca. 10 Minuten"), 13, COLOR_MUTED, false)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(note)
	# Der frühere lange Einstellungs-/Sprachbalken gehört nicht auf die Startseite.
	# Werbung wird stattdessen als native AdMob-Banner angezeigt.
	Monetization.show_home_ad()
	if not _reduced_motion_enabled():
		var pulse_target := hero
		var tween := create_tween().set_loops(2)
		tween.tween_property(pulse_target, "modulate", Color(1.05, 1.05, 1.08), 1.8).set_trans(Tween.TRANS_SINE)
		tween.tween_property(pulse_target, "modulate", Color.WHITE, 1.8).set_trans(Tween.TRANS_SINE)

func _start_host_mode() -> void:
	app_mode = "HOST"
	_refresh_network_info()
	_ensure_host_server()
	_reset_players()
	_show_lobby()
	if not network_has_link:
		_open_hotspot_settings()

func _refresh_host_network() -> void:
	_refresh_network_info()
	_show_lobby()

func _toggle_host_connection_details() -> void:
	if host_connection_details_box == null or not is_instance_valid(host_connection_details_box):
		return
	host_connection_details_box.visible = not host_connection_details_box.visible

func _toggle_network_join() -> void:
	network_join_expanded = not network_join_expanded
	if network_join_details_box != null and is_instance_valid(network_join_details_box):
		network_join_details_box.visible = network_join_expanded
	if network_join_toggle_button != null and is_instance_valid(network_join_toggle_button):
		network_join_toggle_button.text = "NETZWERK & BEITRITT · AUSBLENDEN" if network_join_expanded else "NETZWERK & BEITRITT · ANZEIGEN"

func _open_hotspot_settings() -> void:
	if OS.get_name() == "Android":
		var opened := OS.shell_open("intent:#Intent;action=android.settings.TETHER_SETTINGS;end")
		if opened != OK:
			OS.shell_open("intent:#Intent;action=android.settings.WIFI_SETTINGS;end")

func _show_join_screen() -> void:
	app_mode = "JOIN"
	if start_show_button != null and is_instance_valid(start_show_button):
		start_show_button.visible = false
	discovery_elapsed = 0.0
	discovery_timeout_shown = false
	native_challenge_text = ""
	native_challenge_caught = false
	native_challenge_bonus = 0
	native_challenge_resolved = false
	challenge_session_active = false
	challenge_dock.visible = false
	discovered_rooms.clear()
	discovery_room_buttons.clear()
	_set_game_orientation(true)
	_set_phase_text("BEITRETEN · WLAN-LINK")
	if room_label != null:
		room_label.text = "APP-TO-APP"
	_clear_body()
	var join_hero := _card(Color("121b38"), Color(COLOR_CYAN, 0.42))
	join_hero.custom_minimum_size.y = 350
	body.add_child(join_hero)
	var join_hero_image := TextureRect.new()
	join_hero_image.texture = MINDFOCK_HOST_BANNER
	join_hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	join_hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	join_hero_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	join_hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	join_hero.add_child(join_hero_image)
	var discovery_card := _card(Color("102a38"), Color(COLOR_CYAN, 0.62))
	body.add_child(discovery_card)
	var discovery_content := VBoxContainer.new()
	discovery_content.add_theme_constant_override("separation", 8)
	discovery_card.add_child(discovery_content)
	discovery_content.add_child(_label(_ui_text("mf.join.discovery", "GEFUNDENE SPIELE IN DER NÄHE"), 13, COLOR_CYAN, true))
	discovery_box = VBoxContainer.new()
	discovery_box.add_theme_constant_override("separation", 7)
	discovery_content.add_child(discovery_box)
	discovery_empty_label = _label(_ui_text("mf.join.searching", "Suche im lokalen WLAN …"), 14, COLOR_MUTED, false)
	discovery_box.add_child(discovery_empty_label)
	discovery_content.add_child(_label(_ui_text("mf.join.help", "Wenn kein Raum erscheint, Host-IP und Code manuell eingeben."), 13, COLOR_MUTED, false))
	var rescan_button := _button(_ui_text("mf.join.rescan", "ERNEUT IM WLAN SUCHEN"), Color(COLOR_CYAN, 0.16), Callable(self, "_restart_discovery"))
	rescan_button.custom_minimum_size.y = 48
	body.add_child(rescan_button)
	var manual_toggle := _button(_ui_text("mf.join.manual", "MANUELL VERBINDEN · FALLBACK"), Color(COLOR_SURFACE_2, 0.8), Callable(self, "_toggle_manual_join"))
	manual_toggle.custom_minimum_size.y = 48
	body.add_child(manual_toggle)
	manual_join_card = _card(Color("121b38"), Color(COLOR_CYAN, 0.45))
	manual_join_card.visible = false
	body.add_child(manual_join_card)
	var card := manual_join_card
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(_label("DEIN PROFIL", 13, COLOR_CYAN, true))
	join_name_input = _line_edit("Dein Name", "z. B. Alex", false)
	box.add_child(join_name_input)
	join_name_input.text = native_client.get_player_name()
	selected_avatar = native_client.get_avatar_index()
	selected_avatar_tint = native_client.get_avatar_tint()
	selected_avatar_expression = native_client.get_avatar_expression()
	box.add_child(_label("HOST-VERBINDUNG", 13, COLOR_ACCENT, true))
	join_host_input = _line_edit("Host-IP", "z. B. 192.168.178.42", false)
	box.add_child(join_host_input)
	join_host_input.text = native_client.get_last_host()
	join_room_input = _line_edit("Raumcode", "z. B. 7KQF", true)
	box.add_child(join_room_input)
	join_room_input.text = native_client.get_last_room_code()
	box.add_child(_label("Beim Beitritt erhältst du zufällig eine noch freie Figur. In der Lobby kannst du deinen Avatar jederzeit wechseln.", 13, COLOR_PURPLE, false))
	join_feedback_label = _label("Noch nicht verbunden. Deine Daten bleiben auf diesem Handy.", 13, COLOR_MUTED, false)
	box.add_child(join_feedback_label)
	var connect_button := _button(_ui_text("mf.join.connect", "VERBINDEN\nZur Lobby des Hosts"), Color(COLOR_CYAN, 0.2), Callable(self, "_connect_as_native_player"))
	connect_button.custom_minimum_size.y = 76
	box.add_child(connect_button)
	var back_button := _button(_ui_text("mf.join.back", "← Zur Startseite"), Color(COLOR_SURFACE_2, 0.78), Callable(self, "_show_welcome"))
	back_button.custom_minimum_size.y = 50
	action_bar.add_child(back_button)
	join_name_input.grab_focus()
	native_client.start_discovery()

func _line_edit(label_text: String, placeholder: String, uppercase: bool) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.name = label_text.replace(" ", "")
	field.tooltip_text = "%s: %s" % [label_text, placeholder]
	field.focus_mode = Control.FOCUS_ALL
	field.custom_minimum_size.y = 58
	field.add_theme_font_override("font", FONT_BOLD)
	field.add_theme_font_size_override("font_size", 19)
	field.add_theme_color_override("font_color", COLOR_INK)
	field.add_theme_color_override("font_placeholder_color", Color(COLOR_MUTED, 0.72))
	field.add_theme_stylebox_override("normal", _style(Color("0b1228"), Color("3a5682"), 12, 1))
	field.add_theme_stylebox_override("focus", _style(Color("0d1731"), COLOR_CYAN, 12, 2))
	field.text_changed.connect(func(value: String) -> void:
		if uppercase:
			field.text = value.to_upper().replace(" ", "")
			field.caret_column = field.text.length()
	)
	return field

func _avatar_description() -> String:
	return "%s %s · %s · %s" % [AVATAR_ICONS[selected_avatar], AVATAR_NAMES[selected_avatar], AVATAR_TINTS[selected_avatar_tint], AVATAR_EXPRESSIONS[selected_avatar_expression]]

func _avatar_button(index: int, selected: bool, unavailable: bool = false) -> Button:
	var button := _button("", Color(COLOR_CYAN, 0.35) if selected else Color(COLOR_PURPLE, 0.18), Callable(self, "_select_avatar"), [index])
	# Die sichtbare Grafik entspricht damit exakt den 80×80 px-Avataren der Mitspieler-Liste.
	button.custom_minimum_size = Vector2(96, 96)
	var avatar_texture := TextureRect.new()
	avatar_texture.texture = AVATAR_IMAGES[index]
	avatar_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	avatar_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(avatar_texture)
	button.toggle_mode = true
	button.button_pressed = selected
	button.disabled = unavailable
	button.modulate = Color(0.45, 0.48, 0.58, 0.82) if unavailable else Color.WHITE
	button.set_meta("avatar_index", index)
	button.add_to_group("avatar_selector_buttons")
	button.tooltip_text = AVATAR_NAMES[index]
	return button

func _select_avatar(index: int) -> void:
	var requested_avatar := clampi(index, 0, AVATAR_NAMES.size() - 1)
	if _avatar_taken_by_other(requested_avatar, "host"):
		return
	var previous_scroll := body_scroll.scroll_vertical if body_scroll != null and is_instance_valid(body_scroll) else 0
	selected_avatar = requested_avatar
	if not players.is_empty() and app_mode == "HOST" and bool(players[0].get("is_host", false)):
		players[0].avatarIndex = selected_avatar
		players[0].avatarTint = selected_avatar_tint
		players[0].avatarExpression = selected_avatar_expression
		players[0].avatar_expression = AVATAR_EXPRESSIONS[selected_avatar_expression]
	for button in get_tree().get_nodes_in_group("avatar_selector_buttons"):
		if button is Button:
			button.button_pressed = int(button.get_meta("avatar_index", -1)) == selected_avatar
	if avatar_preview_label != null:
		avatar_preview_label.text = _avatar_description()
	if app_mode == "HOST" and phase == Phase.LOBBY:
		call_deferred("_refresh_lobby_preserving_scroll", previous_scroll)

func _cycle_avatar_tint() -> void:
	var previous_scroll := body_scroll.scroll_vertical if body_scroll != null and is_instance_valid(body_scroll) else 0
	selected_avatar_tint = (selected_avatar_tint + 1) % AVATAR_TINTS.size()
	if avatar_preview_label != null:
		avatar_preview_label.text = _avatar_description()
	if not players.is_empty() and app_mode == "HOST" and bool(players[0].get("is_host", false)):
		players[0].avatarTint = selected_avatar_tint
	if app_mode == "HOST" and phase == Phase.LOBBY:
		call_deferred("_refresh_lobby_preserving_scroll", previous_scroll)

func _cycle_avatar_expression() -> void:
	var previous_scroll := body_scroll.scroll_vertical if body_scroll != null and is_instance_valid(body_scroll) else 0
	selected_avatar_expression = (selected_avatar_expression + 1) % AVATAR_EXPRESSIONS.size()
	if avatar_preview_label != null:
		avatar_preview_label.text = _avatar_description()
	if not players.is_empty() and app_mode == "HOST" and bool(players[0].get("is_host", false)):
		players[0].avatarExpression = selected_avatar_expression
		players[0].avatar_expression = AVATAR_EXPRESSIONS[selected_avatar_expression]
	if app_mode == "HOST" and phase == Phase.LOBBY:
		call_deferred("_refresh_lobby_preserving_scroll", previous_scroll)

func _refresh_lobby_preserving_scroll(previous_scroll: int) -> void:
	_show_lobby()
	call_deferred("_restore_body_scroll", previous_scroll)

func _restore_body_scroll(previous_scroll: int) -> void:
	if body_scroll == null or not is_instance_valid(body_scroll):
		return
	body_scroll.scroll_vertical = previous_scroll
	body_scroll.set_deferred("scroll_vertical", previous_scroll)

func _toggle_manual_join() -> void:
	if manual_join_card != null:
		manual_join_card.visible = not manual_join_card.visible

func _on_discovery_room_found(payload: Dictionary) -> void:
	if app_mode != "JOIN" or discovery_box == null:
		return
	discovery_elapsed = 0.0
	discovery_timeout_shown = false
	var room_code_found := str(payload.get("roomCode", "----")).to_upper()
	var room_key := "%s|%s" % [str(payload.get("hostName", "Bluff-Host")), room_code_found]
	var previous: Dictionary = discovered_rooms.get(room_key, {})
	var merged_candidates: Array[String] = []
	for candidate in Array(previous.get("hostCandidates", [])) + Array(payload.get("hostCandidates", [])):
		var candidate_text := str(candidate).strip_edges()
		if not candidate_text.is_empty() and not merged_candidates.has(candidate_text):
			merged_candidates.append(candidate_text)
	payload["hostCandidates"] = merged_candidates
	discovered_rooms[room_key] = payload.duplicate(true)
	if discovery_empty_label != null and is_instance_valid(discovery_empty_label):
		discovery_empty_label.queue_free()
		discovery_empty_label = null
	var room_text := "%s  ·  %s/%s Spieler\n%s  ·  Code %s" % [str(payload.get("hostName", "Bluff-Host")), int(payload.get("playerCount", 0)), int(payload.get("maxPlayers", MAX_PLAYERS)), str(payload.get("category", selected_category)), room_code_found]
	var room_button: Button = discovery_room_buttons.get(room_key)
	if room_button == null or not is_instance_valid(room_button):
		room_button = _button(room_text, Color(COLOR_CYAN, 0.2), Callable(self, "_join_discovered_room_key").bind(room_key))
		room_button.custom_minimum_size.y = 72
		room_button.add_theme_font_size_override("font_size", 15)
		discovery_box.add_child(room_button)
		discovery_room_buttons[room_key] = room_button
	else:
		room_button.text = room_text

func _on_discovery_room_expired(expired_key: String) -> void:
	if app_mode != "JOIN":
		return
	var expired_parts := expired_key.split(":", false)
	var expired_host := str(expired_parts[0]) if not expired_parts.is_empty() else ""
	var expired_room := str(expired_parts[1]).to_upper() if expired_parts.size() > 1 else ""
	for room_key in discovered_rooms.keys().duplicate():
		var payload: Dictionary = discovered_rooms[room_key]
		var matches_room := str(payload.get("roomCode", "")).to_upper() == expired_room
		var matches_host := str(payload.get("hostIp", "")) == expired_host or Array(payload.get("hostCandidates", [])).has(expired_host)
		if matches_room and matches_host:
			discovered_rooms.erase(room_key)
			var button: Button = discovery_room_buttons.get(room_key)
			if button != null and is_instance_valid(button):
				button.queue_free()
			discovery_room_buttons.erase(room_key)
		if discovered_rooms.is_empty() and discovery_empty_label == null and discovery_box != null:
			discovery_empty_label = _label("Der Raum ist nicht mehr verfügbar. Suche erneut oder nutze den manuellen Fallback.", 14, COLOR_ACCENT, false)
			discovery_box.add_child(discovery_empty_label)

func _join_discovered_room_key(room_key: String) -> void:
	var payload: Dictionary = discovered_rooms.get(room_key, {})
	if not payload.is_empty():
		_join_discovered_room(payload)

func _restart_discovery() -> void:
	if native_client == null or app_mode != "JOIN":
		return
	discovered_rooms.clear()
	discovery_room_buttons.clear()
	for child in discovery_box.get_children():
		child.queue_free()
	discovery_empty_label = _label("Suche erneut im lokalen WLAN …", 14, COLOR_MUTED, false)
	discovery_box.add_child(discovery_empty_label)
	native_client.stop_discovery()
	native_client.start_discovery()

func _join_discovered_room(payload: Dictionary) -> void:
	if join_name_input == null:
		return
	var host_candidates: Array[String] = []
	for candidate in payload.get("hostCandidates", []):
		var candidate_text := str(candidate).strip_edges()
		if not candidate_text.is_empty() and not host_candidates.has(candidate_text):
			host_candidates.append(candidate_text)
	var selected_host := host_candidates[0] if not host_candidates.is_empty() else str(payload.get("hostIp", ""))
	join_host_input.text = selected_host
	join_room_input.text = str(payload.get("roomCode", "")).to_upper()
	join_host_input.set_meta("host_port", int(payload.get("port", 8081)))
	join_host_input.set_meta("host_candidates", host_candidates)
	manual_join_card.visible = true
	if join_name_input.text.strip_edges().is_empty():
		join_feedback_label.text = "Raum ausgewählt. Wähle zuerst deinen Namen und Avatar, dann tippe auf VERBINDEN."
		join_feedback_label.add_theme_color_override("font_color", COLOR_ACCENT)
		join_name_input.grab_focus()
	else:
		join_feedback_label.text = "Raum ausgewählt: %s · Profil prüfen und VERBINDEN tippen." % str(payload.get("hostName", "Bluff-Host"))
		join_feedback_label.add_theme_color_override("font_color", COLOR_GREEN)

func _connect_as_native_player() -> void:
	if join_name_input == null or join_host_input == null or join_room_input == null:
		return
	var name := join_name_input.text.strip_edges()
	var host := join_host_input.text.strip_edges()
	var code := join_room_input.text.strip_edges().to_upper()
	if name.is_empty():
		if join_feedback_label != null:
			join_feedback_label.text = "Bitte zuerst einen Spielernamen eingeben."
			join_feedback_label.add_theme_color_override("font_color", COLOR_RED)
		return
	if host.is_empty():
		if join_feedback_label != null:
			join_feedback_label.text = "Host-Adresse fehlt. Wähle einen gefundenen Raum oder öffne den manuellen Fallback."
			join_feedback_label.add_theme_color_override("font_color", COLOR_RED)
		return
	if code.length() != 4:
		if join_feedback_label != null:
			join_feedback_label.text = "Der Raumcode muss genau vier Zeichen enthalten."
			join_feedback_label.add_theme_color_override("font_color", COLOR_RED)
		return
	if join_feedback_label != null:
		join_feedback_label.text = "Verbinde mit der Host-Show …"
		join_feedback_label.add_theme_color_override("font_color", COLOR_ACCENT)
	native_room_players.clear()
	var port := int(join_host_input.get_meta("host_port", 8081))
	var fallback_hosts: Array[String] = join_host_input.get_meta("host_candidates", [])
	if not fallback_hosts.is_empty() and fallback_hosts[0] == host:
		fallback_hosts.pop_front()
	native_client.connect_to_host(host, code, name, selected_avatar, selected_avatar_tint, selected_avatar_expression, port, fallback_hosts)

func _on_native_connected(payload: Dictionary) -> void:
	app_mode = "CLIENT"
	room_code = str(payload.get("roomCode", join_room_input.text if join_room_input != null else "----"))
	_set_phase_text("VERBUNDEN · LOBBY")
	if native_status_label != null:
		native_status_label.text = "● MIT HOST VERBUNDEN"
	_show_native_lobby()

func _on_native_disconnected(reason: String) -> void:
	last_error_message = reason
	if app_mode != "CLIENT":
		return
	if native_status_label != null:
		native_status_label.text = "● VERBINDUNG PAUSIERT"
	if join_feedback_label != null:
		join_feedback_label.text = reason
	_show_native_connection_lost(reason)

func _on_native_connection_state(state: String, detail: String) -> void:
	if state == "error":
		last_error_message = detail
	if join_feedback_label != null and app_mode == "JOIN":
		join_feedback_label.text = "Host nicht erreichbar. Prüfe WLAN und Host-Adresse." if state == "error" else detail
		join_feedback_label.add_theme_color_override("font_color", COLOR_RED if state == "error" else COLOR_ACCENT)
	if native_status_label != null and app_mode == "CLIENT":
		native_status_label.text = "● %s" % detail.to_upper()

func _copy_diagnostics() -> void:
	var lines := PackedStringArray()
	lines.append("MINDFOX – DIAGNOSEBERICHT")
	lines.append("Zeit: %s" % Time.get_datetime_string_from_system())
	lines.append("App-Modus: %s | Phase: %s | Runde: %d/%d" % [app_mode, str(phase), round_index + 1, max_rounds])
	lines.append("Raum: %s | Lokale IP: %s | Interface: %s" % [room_code if not room_code.is_empty() else "----", local_ip, network_interface_name])
	lines.append("Netzwerk-Link: %s | WLAN erkannt: %s" % [str(network_has_link), str(_network_info().get("wifi", false))])
	lines.append("Letzter Fehler: %s" % (last_error_message if not last_error_message.is_empty() else "keiner gespeichert"))
	if embedded_lan != null and is_instance_valid(embedded_lan):
		lines.append("Host-Server: gestartet=%s | Discovery=%s | HTTP=8080 | WebSocket=%d" % [str(embedded_lan.started), str(embedded_lan.discovery_ready), int(embedded_lan.websocket_port)])
	if native_client != null:
		lines.append("Client Host: %s:%d | Client Raum: %s | Client Spieler: %s" % [native_client.get_last_host(), native_client.get_last_port(), native_client.get_last_room_code(), native_client.get_player_name()])
	lines.append("Lokale IPv4-Adressen:")
	for interface in IP.get_local_interfaces():
		lines.append("  %s: %s" % [str(interface.get("name", "?")), ", ".join(PackedStringArray(interface.get("addresses", [])))])
		lines.append("Hinweis: Gleiches lokales WLAN nötig. Gastnetz, VLAN, Firewall oder VPN können Verbindungen blockieren.")
	DisplayServer.clipboard_set("\n".join(lines))
	if diagnostics_button != null:
		diagnostics_button.text = "KOPIERT"
		diagnostics_button.modulate = COLOR_GREEN

func _on_native_message(kind: String, payload: Dictionary) -> void:
	if app_mode != "CLIENT":
		return
	if kind == "PLAYER_CHALLENGE":
		native_challenge_text = str(payload.get("text", ""))
		native_challenge_caught = bool(payload.get("caught", false))
		native_challenge_bonus = 0
		native_challenge_resolved = false
		challenge_session_active = true
		_update_challenge_dock(native_challenge_text, native_challenge_caught)
		if native_challenge_caught and native_client != null:
			native_client.send_challenge_caught()
	elif kind == "PLAYER_CHALLENGE_STATUS":
		native_challenge_caught = bool(payload.get("caught", native_challenge_caught))
		_update_challenge_dock(native_challenge_text, native_challenge_caught, native_challenge_resolved, native_challenge_bonus)
	elif kind == "ROOM_STATE":
		room_code = str(payload.get("roomCode", room_code))
		native_lobby_rounds = clampi(int(payload.get("maxRounds", native_lobby_rounds)), MIN_ROUNDS, ROUND_COUNT_MAX)
		native_lobby_category = str(payload.get("category", native_lobby_category))
		if payload.has("secretMissionsEnabled"):
			secret_missions_enabled = bool(payload.get("secretMissionsEnabled", true))
		if payload.has("confidenceEnabled"):
			confidence_system_enabled = bool(payload.get("confidenceEnabled", true))
		if str(payload.get("phase", "LOBBY")) == "LOBBY" and phase == Phase.LOBBY and not challenge_session_active and not native_challenge_resolved:
			_show_native_lobby()
	elif kind == "LOBBY_PLAYERS":
		native_room_players = payload.get("players", [])
		native_lobby_rounds = clampi(int(payload.get("maxRounds", native_lobby_rounds)), MIN_ROUNDS, ROUND_COUNT_MAX)
		native_lobby_category = str(payload.get("category", native_lobby_category))
		if payload.has("secretMissionsEnabled"):
			secret_missions_enabled = bool(payload.get("secretMissionsEnabled", true))
		if payload.has("confidenceEnabled"):
			confidence_system_enabled = bool(payload.get("confidenceEnabled", true))
		for room_player in native_room_players:
			if str(room_player.get("id", "")) == native_client.player_id:
				selected_avatar = clampi(int(room_player.get("avatarIndex", selected_avatar)), 0, AVATAR_IMAGES.size() - 1)
				selected_avatar_tint = clampi(int(room_player.get("avatarTint", selected_avatar_tint)), 0, AVATAR_TINTS.size() - 1)
				selected_avatar_expression = clampi(int(room_player.get("avatarExpression", selected_avatar_expression)), 0, AVATAR_EXPRESSIONS.size() - 1)
		if phase == Phase.LOBBY and not challenge_session_active and not native_challenge_resolved:
			_show_native_lobby()
		else:
			_refresh_rocket_targets()
	elif kind == "PLAYER_ROCKET":
		if str(payload.get("targetId", "")) == native_client.player_id:
			_show_player_rocket(payload)
	elif kind == "JOIN_ERROR":
		if native_client != null:
			native_client.disconnect_from_host()
		app_mode = "JOIN"
		_show_join_screen()
		if join_feedback_label != null:
			var join_reason := str(payload.get("reason", "")).to_upper()
			join_feedback_label.text = "Raum nicht erreichbar. Prüfe Raumcode und Host-Lobby." if join_reason in ["NOT_FOUND", "WRONG_ROOM", "CLOSED"] else "Die Verbindung wurde abgelehnt. Prüfe Raumcode, Sitzung oder Lobbystatus."
			join_feedback_label.add_theme_color_override("font_color", COLOR_RED)
	elif kind == "GATE_UPDATE":
		if str(payload.get("gate", "")) == "ROUND" and not native_reveal_payload.is_empty():
			_show_native_reveal(native_reveal_payload, payload)
		else:
			_show_native_gate(payload)
	elif kind == "GATE_COUNTDOWN":
		_show_native_gate_countdown(payload)
	elif kind == "SCORE_STATUS":
		native_score_status = {"ownScore": int(payload.get("ownScore", 0)), "leaderScore": int(payload.get("leaderScore", 0)), "leaderName": str(payload.get("leaderName", "Noch offen"))}
		_update_score_hud(native_score_status)
	elif kind == "SHOW_DIRECTIVE":
		current_directive = payload.duplicate(true)
	elif kind == "QUESTION_BROADCAST":
		native_question_id = str(payload.get("questionId", ""))
		active_question = payload.duplicate(true)
		if native_question_label != null:
			native_question_label.text = str(payload.get("prompt", "Frage wird geladen …"))
	elif kind == "PHASE_CHANGE":
		if payload.has("maxRounds"):
			max_rounds = clampi(int(payload.get("maxRounds", max_rounds)), MIN_ROUNDS, ROUND_COUNT_MAX)
		if payload.has("confidenceEnabled"):
			confidence_system_enabled = bool(payload.get("confidenceEnabled", true))
		var next_phase := str(payload.get("newPhase", ""))
		if next_phase in ["INPUT", "VOTING", "SCORES", "FINAL_PODIUM"] and score_hud != null:
			score_hud.visible = true
		if next_phase == "INPUT":
			phase = Phase.INPUT
			countdown = maxf(0.0, float(payload.get("timeLimitSec", 45)))
			native_submitted = false
			_show_native_input(payload)
		elif next_phase == "VOTING":
			phase = Phase.VOTING
			countdown = maxf(0.0, float(payload.get("timeLimitSec", 30)))
			native_vote_pending = false
			native_submitted = false
			_show_native_wait("Die Antworten werden gemischt …", "Gleich beginnt die Abstimmung.")
		elif next_phase == "REVEAL":
			phase = Phase.REVEAL
		elif next_phase == "SCORES":
			phase = Phase.SCOREBOARD
			_show_native_scores(payload)
		elif next_phase == "FINAL_PODIUM":
			phase = Phase.PODIUM
			_show_native_podium(payload)
	elif kind == "VOTE_OPTIONS_LIST":
		current_options = payload.get("options", [])
		native_question_id = str(payload.get("questionId", native_question_id))
		native_selected_option = ""
		native_submitted = false
		native_vote_pending = false
		max_rounds = clampi(int(payload.get("maxRounds", max_rounds)), MIN_ROUNDS, ROUND_COUNT_MAX)
		var question_prompt := str(payload.get("question", ""))
		if not question_prompt.is_empty():
			active_question["prompt"] = question_prompt
		native_score_status = {"ownScore": int(payload.get("ownScore", 0)), "leaderScore": int(payload.get("leaderScore", 0)), "leaderName": str(payload.get("leaderName", "Noch offen"))}
		_update_score_hud(native_score_status)
		_show_native_voting()
	elif kind == "SUBMIT_ACK" or kind == "INPUT_FEEDBACK":
			if bool(payload.get("accepted", false)):
				native_submitted = true
				if kind == "SUBMIT_ACK":
					Monetization.show_waiting_ad()
				_show_native_wait("Antwort versiegelt.", "Pokerface an. Warte auf die anderen Spieler …")
			else:
				native_submitted = false
				_show_native_input_feedback(str(payload.get("reason", "")))
	elif kind == "VOTE_ACK":
		native_vote_pending = false
		if bool(payload.get("accepted", false)):
			native_submitted = true
			Monetization.show_waiting_ad()
			_show_native_wait("Tipp gespeichert.", "Wer hat die Runde reingelegt? Gleich wissen wir mehr.")
		else:
			native_submitted = false
			_show_native_voting_feedback("Dieser Tipp wurde nicht angenommen. Prüfe die Auswahl und sende erneut.", true)
	elif kind == "ROUND_PROGRESS":
		var submitted_count := int(payload.get("submittedCount", 0))
		var total_players := int(payload.get("total", 0))
		var waiting := Array(payload.get("waiting", []))
		var waiting_text := ", ".join(waiting) if not waiting.is_empty() else "alle bereit"
		if phase == Phase.INPUT and native_submitted:
			_show_native_wait("Antwort gespeichert", "%s %d/%d · wartet auf: %s" % [str(payload.get("label", "Antworten")), submitted_count, total_players, waiting_text])
		elif phase == Phase.VOTING and native_submitted:
			_show_native_wait("Tipp gespeichert", "%s %d/%d · wartet auf: %s" % [str(payload.get("label", "Tipps")), submitted_count, total_players, waiting_text])
	elif kind == "ROUND_REVEAL_DATA":
		_show_native_reveal(payload)
	elif kind == "EMOJI_PING":
		_show_emoji_reaction(str(payload.get("emoji", "")))

func _show_native_connection_lost(reason: String) -> void:
	_clear_body()
	body.add_child(_label("Die Show wartet auf dich.", 31, COLOR_INK, true))
	body.add_child(_label(reason, 16, COLOR_MUTED, false))
	body.add_child(_label("Dein Spielerprofil bleibt erhalten. Der Host kann dich in derselben Runde wieder aufnehmen.", 14, COLOR_CYAN, false))
	var reconnect := _button("ERNEUT VERBINDEN", Color(COLOR_ACCENT, 0.22), Callable(self, "_reconnect_native_player"))
	reconnect.custom_minimum_size.y = 72
	action_bar.add_child(reconnect)
	var edit_profile := _button("Profil / Raum ändern", Color(COLOR_SURFACE_2, 0.88), Callable(self, "_show_join_screen"))
	edit_profile.custom_minimum_size.y = 54
	action_bar.add_child(edit_profile)

func _reconnect_native_player() -> void:
	if native_client == null:
		return
	if native_status_label != null:
		native_status_label.text = "● VERBINDE ERNEUT …"
	native_client.connect_to_host(native_client.get_last_host(), native_client.get_last_room_code(), native_client.get_player_name(), selected_avatar, selected_avatar_tint, selected_avatar_expression, native_client.get_last_port())

func _show_native_lobby() -> void:
	if start_show_button != null and is_instance_valid(start_show_button):
		start_show_button.visible = false
	challenge_dock.visible = false
	_set_game_orientation(true)
	phase = Phase.LOBBY
	_set_phase_text("VERBUNDEN · LOBBY")
	_clear_body()
	var status := _card(Color("12333a"), Color(COLOR_GREEN, 0.65))
	body.add_child(status)
	native_status_label = _label("● MIT HOST VERBUNDEN", 15, COLOR_GREEN, true)
	native_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_child(native_status_label)
	var heading := _label("Die Show startet gleich.", 31, COLOR_INK, true)
	body.add_child(heading)
	body.add_child(_label("Du bist drin. Behalte dein Pokerface und warte auf das Ready-Signal des Hosts.", 16, COLOR_MUTED, false))
	var rules_button := _button("SPIELREGELN", Color(COLOR_CYAN, 0.18), Callable(self, "_show_rules_dialog"))
	rules_button.custom_minimum_size.y = 52
	rules_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rules_button)
	var settings_card := _card(Color("12333a"), Color(COLOR_CYAN, 0.48))
	body.add_child(settings_card)
	var settings_box := VBoxContainer.new()
	settings_box.add_theme_constant_override("separation", 5)
	settings_card.add_child(settings_box)
	settings_box.add_child(_label("HOST-EINSTELLUNGEN", 13, COLOR_CYAN, true))
	settings_box.add_child(_label("RUNDEN · %d" % native_lobby_rounds, 16, COLOR_INK, true))
	settings_box.add_child(_label("THEMENMODUS · %s" % native_lobby_category, 14, COLOR_ACCENT, true))
	settings_box.add_child(_label("GEHEIMMISSIONEN · %s" % ("AN" if secret_missions_enabled else "AUS"), 14, COLOR_GREEN if secret_missions_enabled else COLOR_MUTED, true))
	settings_box.add_child(_label("SICHERHEITSBALKEN · %s" % ("AN · 1–100 %" if confidence_system_enabled else "AUS · STANDARDPUNKTE"), 14, COLOR_GREEN if confidence_system_enabled else COLOR_MUTED, true))
	var lobby_avatar := _player_avatar_image({"avatarIndex": selected_avatar}, 96)
	lobby_avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(lobby_avatar)
	body.add_child(_label(_avatar_description(), 15, COLOR_PURPLE, true))
	var avatar_card := _card(Color("211d3a"), Color(COLOR_PURPLE, 0.5))
	body.add_child(avatar_card)
	var avatar_box := VBoxContainer.new()
	avatar_box.add_theme_constant_override("separation", 7)
	avatar_card.add_child(avatar_box)
	avatar_box.add_child(_label("AVATARE · BELEGTE FIGUREN SIND GRAU", 13, COLOR_PURPLE, true))
	var native_avatar_grid := GridContainer.new()
	native_avatar_grid.columns = 4
	native_avatar_grid.add_theme_constant_override("h_separation", 7)
	native_avatar_grid.add_theme_constant_override("v_separation", 7)
	native_avatar_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for avatar_index in range(AVATAR_IMAGES.size()):
		var avatar_button := _button("", Color(COLOR_CYAN, 0.35) if avatar_index == selected_avatar else Color(COLOR_PURPLE, 0.18), Callable(self, "_request_native_avatar"), [avatar_index])
		avatar_button.custom_minimum_size = Vector2(80, 80)
		avatar_button.icon = AVATAR_IMAGES[avatar_index]
		avatar_button.expand_icon = true
		avatar_button.toggle_mode = true
		avatar_button.button_pressed = avatar_index == selected_avatar
		var taken_by := _native_avatar_owner(avatar_index, native_client.player_id)
		avatar_button.disabled = not taken_by.is_empty()
		if not taken_by.is_empty():
			avatar_button.modulate = Color(0.45, 0.48, 0.58, 0.82)
			avatar_button.tooltip_text = "Belegt von %s" % taken_by
		else:
			avatar_button.tooltip_text = AVATAR_NAMES[avatar_index]
		native_avatar_grid.add_child(avatar_button)
	avatar_box.add_child(native_avatar_grid)
	var roster := VBoxContainer.new()
	roster.name = "NativeLobbyRoster"
	roster.add_theme_constant_override("separation", 4)
	for room_player in native_room_players:
		var roster_row := HBoxContainer.new()
		roster_row.custom_minimum_size.y = 58
		var roster_avatar := _player_avatar_image(room_player, 54)
		roster_row.add_child(roster_avatar)
		var room_player_id := str(room_player.get("id", ""))
		var roster_name := "Du · %s" % str(room_player.get("name", "Spieler")) if room_player_id == native_client.player_id else str(room_player.get("name", "Spieler"))
		if bool(room_player.get("isHost", false)):
			roster_name += " · HOST"
		elif not bool(room_player.get("isHuman", true)):
			roster_name += " · BOT"
		var roster_label := _label(roster_name, 15, COLOR_CYAN if room_player_id == native_client.player_id else COLOR_INK, true)
		roster_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		roster_row.add_child(roster_label)
		roster.add_child(roster_row)
	if native_room_players.is_empty():
		roster.add_child(_label("Spielerliste wird geladen …", 12, COLOR_MUTED, false))
	avatar_box.add_child(roster)
	var room := _card(Color("151d3c"), Color(COLOR_ACCENT, 0.5))
	body.add_child(room)
	var room_box := VBoxContainer.new()
	room_box.alignment = BoxContainer.ALIGNMENT_CENTER
	room.add_child(room_box)
	room_box.add_child(_label("DEIN RAUM", 13, COLOR_ACCENT, true))
	var room_code_label := _label(room_code, 48, COLOR_INK, true)
	room_code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_box.add_child(room_code_label)
	room_box.add_child(_label("Warte, bis der Host die Runde öffnet. Host und KI-Mitspieler werden hier synchron angezeigt.", 14, COLOR_MUTED, false))
	var disconnect := _button("Verbindung trennen", Color(COLOR_SURFACE_2, 0.9), Callable(self, "_leave_native_game"))
	disconnect.custom_minimum_size.y = 56
	action_bar.add_child(disconnect)
	_add_emoji_bar()

func _native_avatar_owner(avatar_index: int, own_player_id: String) -> String:
	for room_player in native_room_players:
		if str(room_player.get("id", "")) != own_player_id and int(room_player.get("avatarIndex", -1)) == avatar_index:
			return str(room_player.get("name", "Spieler"))
	return ""

func _request_native_avatar(avatar_index: int) -> void:
	if app_mode != "CLIENT" or phase != Phase.LOBBY or native_client == null:
		return
	if not _native_avatar_owner(avatar_index, native_client.player_id).is_empty():
		return
	native_client.send_avatar_change(avatar_index)

func _show_native_gate(payload: Dictionary) -> void:
	_set_game_orientation(true)
	_set_phase_text("READY · ALLE AUF GO")
	_clear_body()
	var heading := _label("Daumen auf GO!", 34, COLOR_INK, true)
	body.add_child(heading)
	body.add_child(_label("Die nächste Seite öffnet sich, sobald alle bereit sind.", 16, COLOR_MUTED, false))
	var player_card := _card(Color("151d3c"), Color(COLOR_PURPLE, 0.52))
	body.add_child(player_card)
	var player_box := VBoxContainer.new()
	player_box.add_theme_constant_override("separation", 9)
	player_card.add_child(player_box)
	var ready_count := int(payload.get("readyCount", 0))
	var ready_total := int(payload.get("total", 0))
	var waiting_count := maxi(0, ready_total - ready_count)
	var own_id: String = native_client.player_id
	native_gate_ready = false
	for player in payload.get("players", []):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 34
		var ready := bool(player.get("ready", false))
		if str(player.get("id", "")) == own_id:
			native_gate_ready = ready
		var icon := _label("✓" if ready else "…", 21, COLOR_GREEN if ready else COLOR_ACCENT, true)
		icon.custom_minimum_size.x = 30
		row.add_child(icon)
		var name_label := _label(str(player.get("name", "Spieler")), 16, COLOR_INK, true)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_label("BEREIT" if ready else "wartet", 13, COLOR_GREEN if ready else COLOR_MUTED, true))
		player_box.add_child(row)
	var native_ready_state := _derive_ready_state(native_gate_ready, ready_count, ready_total)
	player_box.add_child(_label("%s · %d/%d" % [_ready_state_copy(native_ready_state, waiting_count), ready_count, ready_total], 14, COLOR_GREEN if native_ready_state == ReadyState.ALL_READY else COLOR_CYAN, true))
	var is_placement_gate := str(payload.get("gate", "")) == "PODIUM"
	var go_text := "ZUR PLATZIERUNG" if is_placement_gate and native_ready_state == ReadyState.PLAYER_NOT_READY else ("ALLE BEREIT · WEITER" if native_ready_state == ReadyState.ALL_READY else ("BEREIT · ICH BIN DABEI!" if native_ready_state == ReadyState.PLAYER_NOT_READY else "BEREIT · WARTE AUF DIE ANDEREN"))
	var go := _button(go_text, Color(COLOR_GREEN, 0.24), Callable(self, "_native_ready"))
	go.custom_minimum_size.y = 78
	go.disabled = native_gate_ready
	action_bar.add_child(go)
	if not native_gate_ready:
		_pulse_control(go)
	_add_emoji_bar()

func _native_ready() -> void:
	if native_gate_ready:
		return
	native_gate_ready = true
	native_client.send_ready()
	if not native_reveal_payload.is_empty() and phase == Phase.REVEAL:
		native_gate_payload["gate"] = "ROUND"
		var ready: Array = native_gate_payload.get("ready", [])
		if not ready.has(native_client.player_id):
			ready.append(native_client.player_id)
		native_gate_payload["ready"] = ready
		native_gate_payload["readyCount"] = ready.size()
		_show_native_reveal(native_reveal_payload, native_gate_payload)
	else:
		_show_native_wait("GO gespeichert.", "Der Host sieht, dass du bereit bist.")

func _add_emoji_bar() -> void:
	if action_bar == null or phase == Phase.LOBBY or phase == Phase.PODIUM:
		return
	var targets := _rocket_target_players()
	if targets.is_empty():
		return
	var dock := VBoxContainer.new()
	dock.name = "RocketTargetDock"
	dock.add_theme_constant_override("separation", 3)
	dock.add_child(_label("ABLENKUNG · TIPPE EINEN MITSPIELER", 11, COLOR_MUTED, true))
	var grid := GridContainer.new()
	grid.columns = mini(4, targets.size())
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dock.add_child(grid)
	for target in targets:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 1)
		var avatar_index := clampi(int(target.get("avatarIndex", 0)), 0, AVATAR_IMAGES.size() - 1)
		var target_button := _button("", Color(COLOR_CYAN, 0.26), Callable(self, "_on_rocket_target_pressed").bind(str(target.get("id", ""))))
		target_button.custom_minimum_size = Vector2(64, 58)
		target_button.icon = AVATAR_IMAGES[avatar_index]
		target_button.expand_icon = true
		target_button.tooltip_text = "Rakete auf %s" % str(target.get("name", "Mitspieler"))
		cell.add_child(target_button)
		var name_label := _label(str(target.get("name", "Spieler")).left(9), 10, COLOR_INK, true)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(name_label)
		grid.add_child(cell)
	action_bar.add_child(dock)

func _rocket_target_players() -> Array:
	var targets: Array = []
	if app_mode == "HOST":
		for player in players:
			var player_id := str(player.get("id", ""))
			if player_id == "host" or not bool(player.get("active", true)) or not bool(player.get("is_human", false)):
				continue
			targets.append({"id": player_id, "name": str(player.get("name", "Mitspieler")), "avatarIndex": int(player.get("avatarIndex", 0))})
	elif app_mode == "CLIENT" and native_client != null:
		for player in native_room_players:
			var player_id := str(player.get("id", ""))
			if player_id == native_client.player_id:
				continue
			targets.append({"id": player_id, "name": str(player.get("name", "Mitspieler")), "avatarIndex": int(player.get("avatarIndex", 0))})
	return targets

func _refresh_rocket_targets() -> void:
	if action_bar == null:
		return
	for child in action_bar.get_children():
		if child.name == "RocketTargetDock":
			action_bar.remove_child(child)
			child.queue_free()
	_add_emoji_bar()

func _on_rocket_target_pressed(target_id: String) -> void:
	if app_mode == "CLIENT" and native_client != null:
		native_client.send_player_rocket(target_id)
	elif app_mode == "HOST":
		_route_player_rocket("host", target_id)

func _route_player_rocket(attacker_id: String, target_id: String) -> void:
	if phase == Phase.LOBBY or phase == Phase.PODIUM or target_id == attacker_id:
		return
	var attacker := _find_player(attacker_id)
	var target := _find_player(target_id)
	if attacker.is_empty() or target.is_empty() or not bool(attacker.get("active", true)) or not bool(target.get("active", true)):
		return
	if not bool(attacker.get("is_human", false)) or not bool(target.get("is_human", false)):
		return
	var rocket_payload := {"attackerId": attacker_id, "attackerName": str(attacker.get("name", "Mitspieler")), "avatarIndex": int(attacker.get("avatarIndex", 0)), "targetId": target_id}
	if target_id == "host":
		_show_player_rocket(rocket_payload)
	elif embedded_lan != null:
		_send_client(target_id, "PLAYER_ROCKET", rocket_payload)

func _show_player_rocket(payload: Dictionary) -> void:
	if rocket_effect_overlay == null or not is_instance_valid(rocket_effect_overlay):
		return
	var avatar_index := clampi(int(payload.get("avatarIndex", 0)), 0, AVATAR_IMAGES.size() - 1)
	rocket_effect_overlay.launch(str(payload.get("attackerName", "Mitspieler")), AVATAR_IMAGES[avatar_index])
	if aaa_audio != null:
		aaa_audio.play_cue("click", 1.35)
		aaa_audio.haptic(28)

func _show_emoji_reaction(emoji: String) -> void:
	if not REACTION_EMOJIS.has(emoji):
		return
	if stage_fx != null:
		stage_fx.launch_emoji(emoji)
	aaa_audio.play_cue("click", 1.12)
	aaa_audio.haptic(8)

func _show_native_input(payload: Dictionary) -> void:
	var eligible_ids: Array = payload.get("eligibleIds", [])
	if not eligible_ids.is_empty() and not eligible_ids.has(native_client.player_id):
		_show_native_wait("SCHÄTZ-TIEBREAK", "Du bist nicht in den Top 2 – gleich sehen wir, wer gewinnt.")
		return
	_set_game_orientation(true)
	var estimate_mode := bool(payload.get("estimate", false))
	_set_phase_text("SCHÄTZ-TIEBREAK · TOP 2" if bool(payload.get("tiebreak", false)) else ("SCHÄTZRUNDE %d von %d · SCHNELLTIP" % [int(payload.get("round", round_index + 1)), max_rounds] if estimate_mode else "RUNDE %d von %d · DEIN BLUFF" % [int(payload.get("round", round_index + 1)), max_rounds]))
	_clear_body()
	body.add_child(_brand_mascot(Vector2(86, 86)))
	var question := _card(Color("162442"), Color(COLOR_CYAN, 0.62))
	body.add_child(question)
	var question_box := VBoxContainer.new()
	question.add_child(question_box)
	var native_question_badge := TextureRect.new()
	native_question_badge.texture = QUESTION_BADGE
	native_question_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	native_question_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	native_question_badge.custom_minimum_size = Vector2(54, 54)
	native_question_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	native_question_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	question_box.add_child(native_question_badge)
	question_box.add_child(_label("DIE FRAGE", 13, COLOR_CYAN, true))
	native_question_label = _label(str(payload.get("prompt", active_question.get("prompt", "Frage wird geladen …"))), 25, COLOR_INK, true)
	question_box.add_child(native_question_label)
	question_box.add_child(_label("%s · %s" % [str(payload.get("category", active_question.get("category", selected_category))), str(payload.get("difficulty", active_question.get("difficulty", "mittel")))], 12, COLOR_PURPLE, true))
	question_box.add_child(_label(("Gerade Zahl eingeben · Einheit: %s · danach wird abgestimmt." % str(payload.get("estimateUnit", "Zahl"))) if estimate_mode else "Deine Antwort bleibt geheim, bis die Runde aufgelöst wird.", 13, COLOR_MUTED, false))
	var answer_card := _card(Color("10172e"), Color(COLOR_ACCENT, 0.48))
	body.add_child(answer_card)
	var answer_box := VBoxContainer.new()
	answer_box.add_theme_constant_override("separation", 8)
	answer_card.add_child(answer_box)
	var answer_header := HBoxContainer.new()
	answer_box.add_child(answer_header)
	answer_header.add_child(_label("DEINE SCHÄTZUNG" if estimate_mode else "DEINE FALSCHANTWORT", 14, COLOR_ACCENT, true))
	timer_label = _label("%02d s" % int(ceil(countdown)), 20, COLOR_ACCENT, true)
	timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	answer_header.add_child(timer_label)
	timer_bar = ProgressBar.new()
	timer_bar.max_value = maxf(1.0, float(payload.get("timeLimitSec", countdown)))
	timer_bar.value = countdown
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size.y = 10
	timer_bar.add_theme_stylebox_override("background", _style(Color("283451"), Color("283451"), 5, 0))
	timer_bar.add_theme_stylebox_override("fill", _style(COLOR_ACCENT, COLOR_ACCENT, 5, 0))
	answer_box.add_child(timer_bar)
	answer_input = LineEdit.new()
	answer_input.custom_minimum_size = Vector2(0, 82)
	answer_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_input.placeholder_text = "Nur eine Zahl …" if estimate_mode else "Klingt echt. Ist aber falsch …"
	answer_input.alignment = HORIZONTAL_ALIGNMENT_CENTER if estimate_mode else HORIZONTAL_ALIGNMENT_LEFT
	answer_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER if estimate_mode else LineEdit.KEYBOARD_TYPE_DEFAULT
	answer_input.add_theme_font_override("font", FONT_REGULAR)
	answer_input.add_theme_font_size_override("font_size", 20)
	answer_input.add_theme_color_override("font_color", COLOR_INK)
	answer_input.add_theme_color_override("caret_color", COLOR_ACCENT)
	answer_input.add_theme_stylebox_override("normal", _style(Color("0a1126"), Color("38547d"), 12, 1))
	if estimate_mode:
		var native_numeric_row := HBoxContainer.new()
		native_numeric_row.add_theme_constant_override("separation", 10)
		native_numeric_row.add_child(answer_input)
		native_numeric_row.add_child(_label(str(payload.get("estimateUnit", "Zahl")), 20, COLOR_CYAN, true))
		answer_box.add_child(native_numeric_row)
	else:
		answer_box.add_child(answer_input)
	feedback_label = _label("Schnell tippen – Nähe zum Richtwert gewinnt." if estimate_mode else "75 Zeichen · lieber charmant daneben als langweilig richtig.", 13, COLOR_MUTED, false)
	answer_box.add_child(feedback_label)
	native_answer_submit_button = _button("ANTWORT VERSIEGELN", Color(COLOR_ACCENT, 0.24), Callable(self, "_submit_native_answer"))
	native_answer_submit_button.custom_minimum_size.y = 72
	native_answer_submit_button.disabled = true
	answer_input.text_changed.connect(func(value: String) -> void:
		if native_answer_submit_button != null and is_instance_valid(native_answer_submit_button):
			native_answer_submit_button.disabled = _clean_text(value).is_empty()
	)
	action_bar.add_child(native_answer_submit_button)
	_add_emoji_bar()
	call_deferred("_reset_body_scroll_top")

func _submit_native_answer(force_fallback: bool = false) -> void:
	if native_submitted or answer_input == null:
		return
	var value := _clean_text(answer_input.text)
	var estimate_mode := str(active_question.get("category", "")) == "Schätzrunde" or str(active_question.get("estimate", "false")) == "true"
	if force_fallback and value.is_empty():
		value = "Eine überraschend genaue Sensation aus dem Jahr 1842"
	if value.is_empty():
		if feedback_label != null:
			feedback_label.text = "Schreib zuerst einen Bluff – die Wahrheit darf heute Pause machen."
			feedback_label.add_theme_color_override("font_color", COLOR_RED)
		return
	if value.length() > 75:
		if feedback_label != null:
			feedback_label.text = "Dein Bluff ist zu lang. Kürze ihn auf 75 Zeichen."
		return
	if estimate_mode and not _is_numeric_estimate(value):
		if feedback_label != null:
			feedback_label.text = "Bitte eine nichtnegative gerade Zahl eingeben, z. B. 42."
		return
	if native_client == null or not native_client.send_lie(native_question_id, value):
		native_submitted = false
		if feedback_label != null:
			feedback_label.text = "Keine Verbindung zum Host. Deine Antwort wurde nicht gesendet – bitte erneut versuchen."
			feedback_label.add_theme_color_override("font_color", COLOR_RED)
		return
		native_submitted = true
		if native_answer_submit_button != null and is_instance_valid(native_answer_submit_button):
			native_answer_submit_button.disabled = true
			native_answer_submit_button.text = "ANTWORT GESENDET ✓"
	aaa_audio.play_cue("seal")
	aaa_audio.haptic(22)
	if stage_fx != null:
		stage_fx.emit_burst(Vector2(size.x * 0.5, size.y * 0.48), COLOR_ACCENT, 14)
	_show_native_wait("Antwort versiegelt.", "Pokerface an. Warte auf die anderen Spieler …")

func _show_native_input_feedback(reason: String) -> void:
	native_submitted = false
	var message := "Diese Antwort wurde noch nicht gespeichert. Versuch es noch einmal."
	if reason == "NEEDS_NUMBER": message = "Bitte eine nichtnegative gerade Zahl eingeben, z. B. 42."
	elif reason == "TOO_LONG": message = "Dein Bluff ist zu lang. Kürze ihn auf 75 Zeichen."
	if feedback_label != null:
		feedback_label.text = message
		feedback_label.add_theme_color_override("font_color", COLOR_RED)
		_show_input_action_again()
	else:
		_show_native_input({"prompt": str(active_question.get("prompt", "Frage wird geladen …")), "round": round_index + 1})

func _show_input_action_again() -> void:
	var submit := _button("ANTWORT ERNEUT VERSIEGELN", Color(COLOR_ACCENT, 0.24), Callable(self, "_submit_native_answer"))
	submit.custom_minimum_size.y = 72
	action_bar.add_child(submit)

func _show_native_wait(title: String, detail: String) -> void:
	_clear_body()
	body.add_child(_brand_mascot(Vector2(72, 72)))
	var pulse := _card(Color("12333a"), Color(COLOR_CYAN, 0.55))
	pulse.custom_minimum_size.y = 150
	body.add_child(pulse)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	pulse.add_child(box)
	box.add_child(_label("●", 42, COLOR_CYAN, true))
	var heading := _label(title, 30, COLOR_INK, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var copy := _label(detail, 16, COLOR_MUTED, false)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(copy)
	_add_emoji_bar()

func _show_native_voting() -> void:
	Monetization.hide_ads()
	_set_game_orientation(true)
	_set_phase_text("ABSTIMMUNG · WEM GLAUBST DU?")
	_clear_body()
	body.add_child(_brand_mascot(Vector2(78, 78)))
	body.add_child(_label("Welche Aussage stimmt wirklich?", 31, COLOR_INK, true))
	var question_card := _card(Color("162442"), Color(COLOR_CYAN, 0.62))
	body.add_child(question_card)
	var question_box := VBoxContainer.new()
	question_box.add_theme_constant_override("separation", 5)
	question_card.add_child(question_box)
	question_box.add_child(_label("DIE FRAGE", 13, COLOR_CYAN, true))
	question_box.add_child(_label(str(active_question.get("prompt", "Frage wird geladen …")), 22, COLOR_INK, true))
	body.add_child(_label("Deine eigene Falschantwort ist ausgeblendet. Jetzt zählt dein Bauchgefühl.", 15, COLOR_MUTED, false))
	var confidence := _card(Color("151d3c"), Color(COLOR_PURPLE, 0.48))
	body.add_child(confidence)
	confidence.visible = confidence_system_enabled
	var confidence_box := VBoxContainer.new()
	confidence.add_child(confidence_box)
	var confidence_header := HBoxContainer.new()
	confidence_box.add_child(confidence_header)
	confidence_header.add_child(_label("WIE SICHER BIST DU?", 13, COLOR_CYAN, true))
	confidence_value_label = _label("50%", 16, COLOR_ACCENT, true)
	confidence_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confidence_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	confidence_header.add_child(confidence_value_label)
	confidence_slider = HSlider.new()
	confidence_slider.min_value = 1
	confidence_slider.max_value = 100
	confidence_slider.step = 1
	confidence_slider.value = 50
	confidence_slider.custom_minimum_size.y = 34
	confidence_slider.name = "ConfidenceSlider"
	confidence_slider.tooltip_text = "Vertrauen: 0 Prozent vorsichtig, 100 Prozent mutig"
	confidence_slider.focus_mode = Control.FOCUS_ALL
	confidence_slider.value_changed.connect(_on_confidence_changed)
	confidence_box.add_child(confidence_slider)
	confidence_box.add_child(_label("Vorsichtig 0 %   ·   Standard 50 %   ·   Mutig 100 %", 12, COLOR_MUTED, false))
	confidence_preview_label = _label("", 12, COLOR_PURPLE, true)
	confidence_box.add_child(confidence_preview_label)
	_update_confidence_preview()
	for index in range(current_options.size()):
		var option: Dictionary = current_options[index]
		var visible_index := index + 1
		var option_button := _button("%d  ·  %s" % [visible_index, str(option.get("text", ""))], Color(COLOR_ACCENT, 0.25) if str(option.get("id", "")) == native_selected_option else Color(COLOR_SURFACE_2, 0.96), Callable(self, "_select_native_vote"), [str(option.get("id", ""))])
		option_button.custom_minimum_size.y = 74
		option_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		body.add_child(option_button)
	native_feedback_label = _label("Wähle eine Karte. Danach drücke WEITER.", 13, COLOR_PURPLE, false)
	body.add_child(native_feedback_label)
	native_vote_continue_button = _button("TIPP ABGEBEN · WEITER", Color(COLOR_ACCENT, 0.24), Callable(self, "_confirm_native_vote"))
	native_vote_continue_button.custom_minimum_size.y = 70
	native_vote_continue_button.disabled = true
	action_bar.add_child(native_vote_continue_button)
	_add_emoji_bar()

func _select_native_vote(option_id: String) -> void:
	if option_id.is_empty() or native_submitted or native_vote_pending:
		return
	native_selected_option = option_id
	if native_vote_continue_button != null and is_instance_valid(native_vote_continue_button):
		native_vote_continue_button.disabled = false
	if native_feedback_label != null:
		native_feedback_label.text = "Ausgewählt. Drücke WEITER, um den Tipp abzugeben."

func _confirm_native_vote(force_timeout: bool = false) -> void:
	if native_submitted or native_vote_pending:
		return
	if native_selected_option.is_empty() and not force_timeout:
		if native_feedback_label != null:
			native_feedback_label.text = "Wähle zuerst eine Antwort. Ohne Tipp gibt es bei Zeitablauf keine Punkte."
		return
	var confidence := int(confidence_slider.value) if confidence_slider != null else 50
	if native_client == null or not native_client.send_vote(native_selected_option, confidence, native_question_id):
		_show_native_voting_feedback("Keine Verbindung zum Host. Dein Tipp wurde nicht gesendet.", true)
		return
		native_vote_pending = true
		native_vote_ack_timeout = 4.0
	if native_vote_continue_button != null and is_instance_valid(native_vote_continue_button):
		native_vote_continue_button.disabled = true
		native_vote_continue_button.text = "TIPP WIRD GESENDET …"
	aaa_audio.play_cue("click", 1.08)
	aaa_audio.haptic(16)
	_show_native_wait("Tipp gespeichert.", "Wer hat die Runde reingelegt? Gleich wissen wir mehr.")

func _show_native_voting_feedback(message: String, preserve_selection: bool = false) -> void:
	if not preserve_selection:
		native_selected_option = ""
	if native_feedback_label != null:
		native_feedback_label.text = message
		native_feedback_label.add_theme_color_override("font_color", COLOR_RED)
	_show_native_voting()
	if native_feedback_label != null:
		native_feedback_label.text = message
		native_feedback_label.add_theme_color_override("font_color", COLOR_RED)

func _show_native_reveal(payload: Dictionary, gate_payload: Dictionary = {}) -> void:
	aaa_audio.play_cue("whoosh")
	aaa_audio.haptic(26)
	native_reveal_payload = payload.duplicate(true)
	if not gate_payload.is_empty() and str(gate_payload.get("gate", "")) == "ROUND":
		native_gate_payload = gate_payload.duplicate(true)
	if stage_fx != null:
		stage_fx.emit_burst(Vector2(size.x * 0.5, size.y * 0.36), COLOR_GREEN, 24)
	phase = Phase.REVEAL
	_set_phase_text("AUFLÖSUNG · DIE WAHRHEIT KOMMT ANS LICHT")
	_clear_body()
	body.add_child(_brand_mascot(Vector2(88, 88)))
	body.add_child(_label("Die Wahrheit kommt ans Licht.", 31, COLOR_INK, true))
	var personal_result: Dictionary = {}
	for result in payload.get("playerResults", []):
		if str(result.get("id", "")) == native_client.player_id:
			personal_result = result
			break
	var native_showline := "DEIN BLUFF HAT FUNKTIONIERT." if int(personal_result.get("fooled", 0)) > 0 else "DIE SHOW HAT GESPROCHEN."
	body.add_child(_label(native_showline, 15, COLOR_ACCENT if native_showline != "DIE SHOW HAT GESPROCHEN." else COLOR_PURPLE, true))
	body.add_child(_label(str(payload.get("directive", {}).get("revealCue", "Die Wahrheit kommt ans Licht.")), 15, COLOR_CYAN, true))
	var question_card := _card(Color("17233b"), Color(COLOR_CYAN, 0.45))
	body.add_child(question_card)
	var question_box := VBoxContainer.new()
	question_box.add_theme_constant_override("separation", 5)
	question_card.add_child(question_box)
	question_box.add_child(_label("DIE FRAGE", 13, COLOR_CYAN, true))
	question_box.add_child(_label(str(payload.get("prompt", "")), 24, COLOR_INK, true))
	var truth := _card(Color("123b34"), Color(COLOR_GREEN, 0.82))
	_apply_foil(truth)
	body.add_child(truth)
	var truth_box := VBoxContainer.new()
	truth_box.add_theme_constant_override("separation", 5)
	truth.add_child(truth_box)
	truth_box.add_child(_label("DIE KORREKTE ANTWORT", 13, COLOR_GREEN, true))
	truth_box.add_child(_label(str(payload.get("truth", "")), 22, COLOR_INK, true))
	truth_box.add_child(_label("ERLÄUTERUNG", 13, COLOR_CYAN, true))
	var native_explanation := str(payload.get("explanation", "")).strip_edges()
	if native_explanation.is_empty():
		native_explanation = "Für diese Frage ist keine zusätzliche Erläuterung hinterlegt."
	truth_box.add_child(_label(native_explanation, 14, COLOR_MUTED, false))
	for result in payload.get("playerResults", []):
		if str(result.get("id", "")) == native_client.player_id:
			var personal := _card(Color("202946"), Color(COLOR_CYAN, 0.45))
			_apply_foil(personal)
			var personal_box := VBoxContainer.new()
			personal_box.add_theme_constant_override("separation", 8)
			personal.add_child(personal_box)
			personal_box.add_child(_label("DEIN PERSÖNLICHES ERGEBNIS", 13, COLOR_CYAN, true))
			var selected_text := str(result.get("selectedText", ""))
			personal_box.add_child(_label("Du hast keinen Tipp abgegeben." if selected_text == "Keine Antwort" else ("Du hast die korrekte Antwort gewählt." if bool(result.get("selectedTruth", false)) else "Du hast die korrekte Antwort nicht gewählt."), 19, COLOR_INK, true))
			var native_fooled: Array = result.get("fooledPlayers", [])
			if native_fooled.is_empty():
				personal_box.add_child(_label("Keiner ist auf deinen Bluff hereingefallen · 0 Punkte", 15, COLOR_MUTED, false))
			else:
				personal_box.add_child(_label("Auf deinen Bluff hereingefallen:", 14, COLOR_CYAN, true))
				for fooled_player in native_fooled:
					personal_box.add_child(_label("%s · +%d Punkte" % [str(fooled_player.get("name", "Spieler")), int(fooled_player.get("points", 0))], 15, COLOR_INK, false))
			if result.has("distancePoints"):
				personal_box.add_child(_label("Schätznähe: %+d · Wahrheit gewählt: %+d · Bluff: %+d · Sicherheit: %+d / −%d" % [int(result.get("distancePoints", 0)), int(result.get("truthPickPoints", 0)), int(result.get("fooledPoints", 0)), int(result.get("confidencePoints", 0)), int(result.get("confidencePenalty", 0))], 13, COLOR_CYAN, false))
			else:
				personal_box.add_child(_label("Sicherheit: %d%% · richtig %+d · Risiko −%d" % [int(result.get("confidence", 50)), int(result.get("confidencePoints", 0)), int(result.get("confidencePenalty", 0))], 13, COLOR_CYAN, false))
			personal_box.add_child(_label("Gesamt für diese Runde: %+d Punkte · Gesamtstand: %d Punkte" % [int(result.get("delta", 0)), int(result.get("score", 0))], 17, COLOR_ACCENT, true))
			var native_delta := _label("+0 PUNKTE IN DIESER RUNDE", 25, COLOR_GREEN if int(result.get("delta", 0)) >= 0 else COLOR_RED, true)
			native_delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			personal_box.add_child(native_delta)
			_animate_integer_label(native_delta, int(result.get("delta", 0)), "%+d PUNKTE IN DIESER RUNDE")
			_update_score_hud({"ownScore": int(result.get("score", 0)), "leaderScore": _leader_result_score(payload.get("playerResults", [])), "leaderName": _leader_result_name(payload.get("playerResults", []))})
			body.add_child(personal)
			break
	reveal_details_open = false
	reveal_details_toggle = _button("ALLE DETAILS ANZEIGEN", Color(COLOR_SURFACE_2, 0.82), Callable(self, "_toggle_reveal_details"))
	reveal_details_toggle.custom_minimum_size.y = 52
	body.add_child(reveal_details_toggle)
	reveal_details_panel = VBoxContainer.new()
	reveal_details_panel.visible = false
	reveal_details_panel.add_theme_constant_override("separation", 7)
	body.add_child(reveal_details_panel)
	reveal_details_panel.add_child(_label("DIE ANTWORTEN", 13, COLOR_CYAN, true))
	var native_answer_list := VBoxContainer.new()
	native_answer_list.add_theme_constant_override("separation", 7)
	reveal_details_panel.add_child(native_answer_list)
	var selected_by_id: Dictionary = {}
	for selected_result in payload.get("playerResults", []):
		selected_by_id[str(selected_result.get("id", ""))] = str(selected_result.get("selectedText", "Keine Antwort"))
	for entry in payload.get("entries", []):
		var row := _card(Color("151d3c"), Color(COLOR_PURPLE, 0.32))
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row_box := HBoxContainer.new()
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.add_theme_constant_override("separation", 8)
		row.add_child(row_box)
		if not str(entry.get("ownerId", "")).is_empty():
			row_box.add_child(_player_avatar_image(entry, 54))
		var owner_label := _label(str(entry.get("owner", "Spieler")), 14, COLOR_ACCENT, true)
		owner_label.custom_minimum_size.x = 105
		row_box.add_child(owner_label)
		var answer_label := _label("ANTWORT: „%s“" % str(entry.get("text", "")), 15, COLOR_INK, false)
		answer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.add_child(answer_label)
		if not str(entry.get("ownerId", "")).is_empty():
			var selected_label := _label("GEWÄHLT: „%s“" % str(selected_by_id.get(str(entry.get("ownerId", "")), "Keine Antwort")), 13, COLOR_CYAN, false)
			selected_label.custom_minimum_size.x = 145
			row_box.add_child(selected_label)
		var votes_label := _label("%d Stimmen" % int(entry.get("votes", 0)), 13, COLOR_CYAN, true)
		votes_label.custom_minimum_size.x = 72
		row_box.add_child(votes_label)
		native_answer_list.add_child(row)
	reveal_details_panel.add_child(_label("TABELLE NACH DIESER RUNDE", 13, COLOR_PURPLE, true))
	var native_results: Array = payload.get("playerResults", []).duplicate()
	native_results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	for index in range(native_results.size()):
			var score_row := HBoxContainer.new()
			score_row.add_child(_label("%d" % (index + 1), 18, COLOR_ACCENT, true))
			score_row.add_child(_player_avatar_image(native_results[index], 54))
			var result_row := _label("%s · %+d · %d Pkt" % [str(native_results[index].get("name", "Spieler")), int(native_results[index].get("delta", 0)), int(native_results[index].get("score", 0))], 15, COLOR_INK, true)
			result_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			score_row.add_child(result_row)
			reveal_details_panel.add_child(score_row)
	if not gate_payload.is_empty() and str(gate_payload.get("gate", "")) == "ROUND":
		native_gate_ready = (gate_payload.get("ready", []) as Array).has(native_client.player_id)
		var ready_card := _card(Color("163b3b"), Color(COLOR_GREEN, 0.72))
		body.add_child(ready_card)
		var ready_box := VBoxContainer.new()
		ready_box.add_theme_constant_override("separation", 7)
		ready_card.add_child(ready_box)
		ready_box.add_child(_label("NÄCHSTE SEITE · %d/%d BEREIT" % [int(gate_payload.get("readyCount", 0)), int(gate_payload.get("total", 0))], 14, COLOR_CYAN, true))
		ready_box.add_child(_label("Tippe unten auf WEITER. Nach dem Ready aller startet 3–2–1.", 14, COLOR_INK, false))
		var ready_button := _button("WEITER · BEREIT" if not native_gate_ready else "BEREIT · WARTE AUF DIE ANDEREN", Color(COLOR_GREEN, 0.25), Callable(self, "_native_ready"))
		ready_button.custom_minimum_size.y = 72
		ready_button.disabled = native_gate_ready
		action_bar.add_child(ready_button)
		if not native_gate_ready:
			_pulse_control(ready_button)
	else:
		body.add_child(_label("Der Showrunner wartet auf den Ready-Klick aller Spieler …", 14, COLOR_MUTED, false))
	_add_emoji_bar()

func _show_native_gate_countdown(payload: Dictionary) -> void:
	if phase != Phase.REVEAL:
		return
	var seconds := int(payload.get("seconds", 0))
	if seconds > 0:
		_show_flying_countdown(seconds)
		_set_phase_text("BEREIT · WEITER IN %d" % seconds)
		aaa_audio.play_cue("tick", 1.12)
		aaa_audio.haptic(22)
	else:
		_set_phase_text("AUFLÖSUNG · WEITER")

func _show_native_scores(payload: Dictionary) -> void:
	_set_phase_text("ZWISCHENSTAND · NOCH IST ALLES OFFEN")
	_clear_body()
	body.add_child(_brand_mascot(Vector2(82, 82)))
	body.add_child(_label("Wer führt die Lügenrunde an?", 31, COLOR_INK, true))
	var scores: Array = payload.get("scores", [])
	for index in range(scores.size()):
		var score: Dictionary = scores[index]
		var row := _card(Color("151d3c") if index > 0 else Color("30284b"), Color(COLOR_ACCENT, 0.58) if index == 0 else Color("2b395b"))
		var row_box := HBoxContainer.new()
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(row_box)
		row_box.add_child(_label("%d" % (index + 1), 24, COLOR_ACCENT, true))
		var name := _label(str(score.get("name", "Spieler")), 18, COLOR_INK, true)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.add_child(name)
		row_box.add_child(_label("%d Pkt" % int(score.get("score", 0)), 18, COLOR_GREEN, true))
		body.add_child(row)
	body.add_child(_label("Der Host öffnet gleich die nächste Runde. Halte dein Pokerface bereit.", 14, COLOR_MUTED, false))
	_add_emoji_bar()

func _show_native_podium(payload: Dictionary) -> void:
	Monetization.show_placement_ad()
	aaa_audio.play_cue("fanfare")
	aaa_audio.haptic(42)
	if stage_fx != null:
		stage_fx.emit_burst(Vector2(size.x * 0.5, size.y * 0.28), COLOR_ACCENT, 32)
	_set_phase_text("FINALE · DIE SHOW HAT EINEN CHAMPION")
	_clear_body()
	body.add_child(_brand_mascot(Vector2(96, 96)))
	body.add_child(_label("Der Bluff-Champion steht fest!", 32, COLOR_INK, true))
	for player in payload.get("podium", []):
		var place := int(player.get("rank", 0))
		var row := _card(Color("30284b") if place == 1 else Color("151d3c"), Color(COLOR_ACCENT, 0.85) if place == 1 else Color(COLOR_PURPLE, 0.38))
		if place == 1:
			_apply_foil(row)
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 16)
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(row_box)
		row_box.add_child(_player_avatar_image(player, 104))
		var details := VBoxContainer.new()
		details.alignment = BoxContainer.ALIGNMENT_CENTER
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rank_badge: String = ["🥇", "🥈", "🥉"][place - 1] if place >= 1 and place <= 3 else "%d." % place
		details.add_child(_label("%s · %s" % [rank_badge, str(player.get("name", "Spieler"))], 20, COLOR_INK, true))
		details.add_child(_label("%d Punkte" % int(player.get("score", 0)), 19, COLOR_GREEN, true))
		var quip := _label(str(player.get("quip", "")), 14, COLOR_MUTED, false)
		quip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(quip)
		var mission_text := str(player.get("challengeText", ""))
		if not mission_text.is_empty():
			var mission := _label("MISSION: %s" % mission_text, 12, COLOR_CYAN, false)
			mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_child(mission)
			var mission_bonus := int(player.get("challengeBonus", 0))
			details.add_child(_label("Geschafft · +%d Punkte" % mission_bonus if mission_bonus > 0 else "Erwischt · +0 Missionspunkte", 12, COLOR_GREEN if mission_bonus > 0 else COLOR_MUTED, true))
		if str(player.get("id", "")) == native_client.player_id:
			native_challenge_text = mission_text
			native_challenge_caught = bool(player.get("challengeCaught", false))
			native_challenge_bonus = int(player.get("challengeBonus", 0))
			native_challenge_resolved = true
			challenge_session_active = false
			_update_challenge_dock(native_challenge_text, native_challenge_caught, true, native_challenge_bonus)
		row_box.add_child(details)
		body.add_child(row)
	var awards: Dictionary = payload.get("awards", {})
	body.add_child(_label("MEISTERLÜGNER · %s   ·   DETEKTIV · %s   ·   LEICHTGLÄUBIGES OPFER · %s" % [str(awards.get("liar", "—")), str(awards.get("detective", "—")), str(awards.get("victim", "—"))], 14, COLOR_PURPLE, true))

func _leave_native_game() -> void:
	native_client.disconnect_from_host()
	app_mode = "HOME"
	_show_welcome()

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = COLOR_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var backdrop := TextureRect.new()
	backdrop.texture = STAGE_BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(1.0, 1.0, 1.0, 0.32)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	stage_fx = AAA_STAGE_FX.new()
	stage_fx.name = "AAAStageFX"
	stage_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage_fx)

	var glow := ColorRect.new()
	glow.color = Color(0.30, 0.18, 0.58, 0.11)
	glow.position = Vector2(-160, -120)
	glow.size = Vector2(620, 270)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var top := HBoxContainer.new()
	top_header = top
	top.custom_minimum_size.y = 58
	top.add_theme_constant_override("separation", 14)
	root.add_child(top)

	var brand := HBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.mouse_filter = Control.MOUSE_FILTER_STOP
	brand.gui_input.connect(_on_brand_gui_input)
	var badge := TextureRect.new()
	badge.texture = MINDFOX_APP_ICON
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.custom_minimum_size = Vector2(46, 46)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand.add_child(badge)
	var brand_copy := VBoxContainer.new()
	brand_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_logo_image = TextureRect.new()
	brand_logo_image.texture = MINDFOX_TOP_LOGO
	brand_logo_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_logo_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_logo_image.custom_minimum_size = Vector2(210, 48)
	brand_logo_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_logo_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_subtitle_label = _label("Die Lügenrunde · lokale Party-Beta", 15, COLOR_MUTED, false)
	brand_copy.add_child(brand_logo_image)
	brand_copy.add_child(brand_subtitle_label)
	brand.add_child(brand_copy)
	top.add_child(brand)

	phase_label = _label("LOBBY", 16, COLOR_ACCENT, true)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phase_label.custom_minimum_size = Vector2(150, 52)
	phase_label.add_theme_stylebox_override("normal", _style(Color("241f32"), Color(COLOR_ACCENT, 0.55), 14, 1))
	top.add_child(phase_label)
	start_show_button = _button("STARTE DEINE SHOW", Color(COLOR_ACCENT, 0.20), Callable(self, "_start_host_mode"))
	start_show_button.custom_minimum_size = Vector2(150, 52)
	start_show_button.add_theme_font_size_override("font_size", 11)
	start_show_button.tooltip_text = "Neue MindFox-Runde starten"
	top.add_child(start_show_button)

	room_label = _label("RAUM ----", 17, COLOR_CYAN, true)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	room_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	room_label.custom_minimum_size = Vector2(150, 52)
	top.add_child(room_label)

	score_hud = _card(Color("12333a"), Color(COLOR_GREEN, 0.58))
	score_hud.visible = false
	root.add_child(score_hud)
	var score_hud_box := VBoxContainer.new()
	score_hud_box.add_theme_constant_override("separation", 2)
	score_hud.add_child(score_hud_box)
	score_own_label = _label("DEIN GESAMTSTAND · 0", 13, COLOR_GREEN, true)
	score_hud_box.add_child(score_own_label)
	score_leader_label = _label("AKTUELL VORN · Noch offen · 0 Pkt", 13, COLOR_ACCENT, true)
	score_hud_box.add_child(score_leader_label)
	
	body_scroll = ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	# Buttons in langen Profil-/Lobby-Seiten dürfen beim Anklicken nicht
	# automatisch die Scrollposition verändern.
	body_scroll.follow_focus = false
	body_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	body_scroll.scroll_deadzone = 8
	root.add_child(body_scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.custom_minimum_size.x = 1
	body.add_theme_constant_override("separation", 10)
	body_scroll.add_child(body)
	var action_bar_shell := PanelContainer.new()
	action_bar_shell.name = "StickyActionBar"
	action_bar_shell.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	action_bar_shell.add_theme_stylebox_override("panel", _style(Color("10172e", 0.97), Color(COLOR_CYAN, 0.28), 14, 1))
	action_bar_shell.add_theme_constant_override("margin_left", 10)
	action_bar_shell.add_theme_constant_override("margin_right", 10)
	action_bar_shell.add_theme_constant_override("margin_top", 8)
	action_bar_shell.add_theme_constant_override("margin_bottom", 12)
	root.add_child(action_bar_shell)
	action_bar = VBoxContainer.new()
	action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	action_bar.add_theme_constant_override("separation", 6)
	action_bar_shell.add_child(action_bar)

	challenge_dock = _card(Color("171f3a"), Color(COLOR_ACCENT, 0.72))
	challenge_dock.visible = false
	root.add_child(challenge_dock)
	var challenge_box := VBoxContainer.new()
	challenge_box.add_theme_constant_override("separation", 3)
	challenge_dock.add_child(challenge_box)
	challenge_header_label = _label("GEHEIMMISSION · CA. 20 % DER MÖGLICHEN RUNDENPUNKTE", 12, COLOR_ACCENT, true)
	challenge_box.add_child(challenge_header_label)
	challenge_toggle_button = _button("MISSION ANSEHEN", Color(COLOR_SURFACE_2, 0.72), Callable(self, "_toggle_challenge_details"))
	challenge_toggle_button.custom_minimum_size.y = 48
	challenge_toggle_button.add_theme_font_size_override("font_size", 13)
	challenge_box.add_child(challenge_toggle_button)
	challenge_detail_row = VBoxContainer.new()
	challenge_detail_row.visible = false
	challenge_detail_row.add_theme_constant_override("separation", 8)
	challenge_box.add_child(challenge_detail_row)
	challenge_text_label = _label("", 14, COLOR_INK, true)
	challenge_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	challenge_detail_row.add_child(challenge_text_label)
	challenge_caught_button = CheckButton.new()
	challenge_caught_button.text = "Ich wurde erwischt"
	challenge_caught_button.custom_minimum_size = Vector2(178, 48)
	challenge_caught_button.add_theme_font_size_override("font_size", 12)
	challenge_caught_button.toggled.connect(_on_challenge_caught_toggled)
	challenge_detail_row.add_child(challenge_caught_button)

	footer_label = _label("Offline-Beta · keine Konten · keine Cloud nötig", 13, COLOR_MUTED, false)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer_label)

func _show_lobby() -> void:
	if start_show_button != null and is_instance_valid(start_show_button):
		start_show_button.visible = false
	var preserve_scroll := app_mode == "HOST" and phase == Phase.LOBBY and body_scroll != null and is_instance_valid(body_scroll)
	var previous_scroll := body_scroll.scroll_vertical if preserve_scroll else 0
	challenge_dock.visible = false
	if score_hud != null:
		score_hud.visible = false
	app_mode = "HOST"
	_set_game_orientation(true)
	phase = Phase.LOBBY
	if room_code.is_empty():
		room_code = _new_room_code()
	_set_phase_text("LOBBY · BEREIT ZUM BLUFFEN")
	if embedded_lan != null:
		embedded_lan.set_room(room_code)
		embedded_lan.set_discovery_metadata("Bluff-Host", selected_category)
		embedded_lan.set_player_count(_active_player_count())
	_publish_lobby_state()
	_clear_body()

	var lobby_hero := _card(Color("121b38"), Color(COLOR_CYAN, 0.42))
	lobby_hero.custom_minimum_size.y = 350
	body.add_child(lobby_hero)
	var lobby_hero_image := TextureRect.new()
	lobby_hero_image.texture = MINDFOCK_HOST_BANNER
	lobby_hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lobby_hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lobby_hero_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	lobby_hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobby_hero.add_child(lobby_hero_image)

	var columns := VBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	body.add_child(columns)

	var profile_card := _card(Color("211d3a"), Color(COLOR_PURPLE, 0.62))
	columns.add_child(profile_card)
	var profile_box := VBoxContainer.new()
	profile_box.add_theme_constant_override("separation", 8)
	profile_card.add_child(profile_box)
	profile_box.add_child(_label("DEIN HOST-PROFIL", 14, COLOR_ACCENT, true))
	host_name_input = _line_edit("Host-Name", "Dein Spielername", false)
	host_name_input.text = str(players[0].get("name", "Host")) if not players.is_empty() else "Host"
	profile_box.add_child(host_name_input)
	profile_box.add_child(_label("WÄHLE DEINEN SHOW-CHARAKTER", 13, COLOR_PURPLE, true))
	var host_avatar_row := GridContainer.new()
	host_avatar_row.columns = 4
	host_avatar_row.add_theme_constant_override("h_separation", 8)
	host_avatar_row.add_theme_constant_override("v_separation", 8)
	host_avatar_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for avatar_index in range(AVATAR_IMAGES.size()):
		var host_avatar_button := _avatar_button(avatar_index, avatar_index == selected_avatar, _avatar_taken_by_other(avatar_index, "host"))
		host_avatar_row.add_child(host_avatar_button)
	profile_box.add_child(host_avatar_row)

	var players_card := _card()
	players_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(players_card)
	var player_box := VBoxContainer.new()
	player_box.add_theme_constant_override("separation", 9)
	players_card.add_child(player_box)
	player_box.add_child(_label("MITSPIELER · %d/%d" % [_active_player_count(), MAX_PLAYERS], 15, COLOR_CYAN, true))
	var lobby_status := _label("%d Spieler dabei · %d Platz%s frei" % [_active_player_count(), MAX_PLAYERS - _active_player_count(), "" if MAX_PLAYERS - _active_player_count() == 1 else "e"], 13, COLOR_GREEN if _active_player_count() >= 2 else COLOR_ACCENT, true)
	player_box.add_child(lobby_status)
	for player in players:
		if not bool(player.get("active", true)):
			continue
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 86
		var avatar_image := TextureRect.new()
		var avatar_index := clampi(int(player.get("avatarIndex", 0)), 0, AVATAR_IMAGES.size() - 1)
		avatar_image.texture = AVATAR_IMAGES[avatar_index]
		avatar_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar_image.custom_minimum_size = Vector2(80, 80)
		avatar_image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		avatar_image.tooltip_text = AVATAR_NAMES[avatar_index]
		row.add_child(avatar_image)
		var name_label := _label(str(player.name), 16, COLOR_INK, true)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var is_connected := bool(player.get("connected", true))
		var status_text := "HOST · BEREIT" if bool(player.get("is_host", false)) else ("DABEI" if is_connected else "VERBINDUNG PAUSIERT")
		var role := _label(status_text, 13, COLOR_GREEN if is_connected else COLOR_RED, true)
		role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		role.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(role)
		if not bool(player.get("is_human", true)):
			var remove_bot := _button("×", Color(COLOR_RED, 0.18), Callable(self, "_remove_bot"), [str(player.get("id", ""))])
			remove_bot.custom_minimum_size = Vector2(48, 48)
			remove_bot.add_theme_font_size_override("font_size", 22)
			remove_bot.tooltip_text = "KI-Mitspieler entfernen"
			row.add_child(remove_bot)
		player_box.add_child(row)
	if _active_player_count() < MAX_PLAYERS:
		var add_button := _button("+ KI-Mitspieler hinzufügen", Color(COLOR_PURPLE, 0.16), Callable(self, "_add_bot"))
		add_button.custom_minimum_size.y = 48
		player_box.add_child(add_button)
	var round_card := _card(Color("12333a"), Color(COLOR_CYAN, 0.5))
	columns.add_child(round_card)
	var round_box := VBoxContainer.new()
	round_box.add_theme_constant_override("separation", 7)
	round_card.add_child(round_box)
	var round_row := HBoxContainer.new()
	round_row.add_theme_constant_override("separation", 12)
	round_box.add_child(round_row)
	var round_label := _label("ANZAHL DER RUNDEN", 15, COLOR_CYAN, true)
	round_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	round_row.add_child(round_label)
	round_count_selector = OptionButton.new()
	round_count_selector.custom_minimum_size = Vector2(150, 54)
	for round_count in range(MIN_ROUNDS, ROUND_COUNT_MAX + 1):
		round_count_selector.add_item("%d Runden" % round_count)
		round_count_selector.set_item_metadata(round_count - MIN_ROUNDS, round_count)
	round_count_selector.select(clampi(max_rounds - MIN_ROUNDS, 0, ROUND_COUNT_MAX - MIN_ROUNDS))
	round_count_selector.item_selected.connect(_on_round_count_selected)
	round_row.add_child(round_count_selector)
	var mission_toggle := _button("GEHEIMMISSIONEN: %s" % ("AN" if secret_missions_enabled else "AUS"), Color(COLOR_ACCENT, 0.18) if secret_missions_enabled else Color(COLOR_SURFACE_2, 0.86), Callable(self, "_toggle_secret_missions"))
	mission_toggle.custom_minimum_size.y = 48
	mission_toggle.tooltip_text = "Private Zusatzaufgaben vor dem Start aktivieren oder deaktivieren"
	round_box.add_child(mission_toggle)
	var confidence_toggle := _button("SICHERHEITSBALKEN: %s" % ("AN · 1–100 %" if confidence_system_enabled else "AUS · STANDARDPUNKTE"), Color(COLOR_ACCENT, 0.18) if confidence_system_enabled else Color(COLOR_SURFACE_2, 0.86), Callable(self, "_toggle_confidence_system"))
	confidence_toggle.custom_minimum_size.y = 48
	confidence_toggle.tooltip_text = "Die prozentuale Risiko-/Belohnungswertung für Abstimmungen aktivieren oder deaktivieren"
	round_box.add_child(confidence_toggle)
	var showrunner_button := _button("Spielmodus: %s" % _showrunner_mode_title(), Color(COLOR_PURPLE, 0.18), Callable(self, "_cycle_showrunner_mode"))
	showrunner_button.custom_minimum_size.y = 56
	showrunner_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	showrunner_button.tooltip_text = "Klassisch: reine Bluff- und Wissensrunden. Mix: wechselnde Sonderaufträge und Showrunner-Boni."
	round_box.add_child(showrunner_button)

	var category_card := _card(Color("211d3a"), Color(COLOR_PURPLE, 0.62))
	columns.add_child(category_card)
	var category_box := VBoxContainer.new()
	category_box.add_theme_constant_override("separation", 7)
	category_card.add_child(category_box)
	category_box.add_child(_label("THEMENMODUS · %s" % selected_category, 14, COLOR_ACCENT, true))
	category_box.add_child(_label("Der Host bestimmt, worüber heute gelogen wird.", 13, COLOR_MUTED, false))
	var category_actions := VBoxContainer.new()
	category_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	category_actions.add_theme_constant_override("separation", 5)
	for category in DISCOVERY_CATEGORIES:
		var topic_unlocked: bool = Monetization.is_topic_unlocked(category)
		var category_title: String = ("✓ " if category == selected_category else ("🔒 " if not topic_unlocked else "")) + category
		var category_button := _button(category_title, Color(COLOR_ACCENT, 0.22) if category == selected_category else Color(COLOR_SURFACE_2, 0.84), Callable(self, "_select_category"), [category])
		category_button.custom_minimum_size.y = 48
		category_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		category_button.add_theme_font_size_override("font_size", 11)
		var localized_price := Monetization.topic_price_label(category)
		category_button.tooltip_text = "Freigeschaltet" if topic_unlocked else ("Einmalig %s im Play Store freischalten" % localized_price if not localized_price.is_empty() else "Einmaliger Play-Store-Kauf; dein Preis wird dort angezeigt")
		category_actions.add_child(category_button)
	category_box.add_child(category_actions)
	category_box.add_child(_label("ODER · ALLE FREIGESCHALTETEN THEMEN", 12, COLOR_ACCENT, true))
	category_box.add_child(_label("Mischt das Gratis-Thema mit allen Themen, die du gekauft hast.", 12, COLOR_MUTED, false))
	var all_available_button := _button(("✓ " if selected_category == ALL_AVAILABLE_CATEGORY else "🎲 ") + ALL_AVAILABLE_CATEGORY.to_upper(), Color(COLOR_PURPLE, 0.22) if selected_category == ALL_AVAILABLE_CATEGORY else Color(COLOR_SURFACE_2, 0.84), Callable(self, "_select_category"), [ALL_AVAILABLE_CATEGORY])
	all_available_button.custom_minimum_size.y = 48
	all_available_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_box.add_child(all_available_button)
	if OS.get_name() == "Android":
		var restore_button := _button("KÄUFE WIEDERHERSTELLEN", Color(COLOR_SURFACE_2, 0.68), Callable(Monetization, "restore_purchases"))
		restore_button.custom_minimum_size.y = 42
		category_box.add_child(restore_button)

	var network_join_card := _card(Color("101b35"), Color(COLOR_CYAN, 0.48))
	columns.add_child(network_join_card)
	var network_join_box := VBoxContainer.new()
	network_join_box.add_theme_constant_override("separation", 8)
	network_join_card.add_child(network_join_box)
	network_join_toggle_button = _button("NETZWERK & BEITRITT · AUSBLENDEN" if network_join_expanded else "NETZWERK & BEITRITT · ANZEIGEN", Color(COLOR_CYAN, 0.16), Callable(self, "_toggle_network_join"))
	network_join_toggle_button.custom_minimum_size.y = 54
	network_join_toggle_button.add_theme_font_size_override("font_size", 14)
	network_join_box.add_child(network_join_toggle_button)
	network_join_details_box = VBoxContainer.new()
	network_join_details_box.visible = network_join_expanded
	network_join_details_box.add_theme_constant_override("separation", 9)
	network_join_box.add_child(network_join_details_box)

	var network_card := _card(Color("12333a") if network_has_link else Color("3a2630"), Color(COLOR_GREEN, 0.62) if network_has_link else Color(COLOR_RED, 0.72))
	network_join_details_box.add_child(network_card)
	var network_box := VBoxContainer.new()
	network_box.add_theme_constant_override("separation", 7)
	network_card.add_child(network_box)
	if network_has_link:
		network_box.add_child(_label("NETZWERK ERKANNT · SPIELER KÖNNEN BEITRETEN", 13, COLOR_GREEN, true))
		network_box.add_child(_label("Verbindung bereit · Raum kann entdeckt werden", 13, COLOR_INK, false))
	else:
		network_box.add_child(_label("KEIN WLAN / LOKALES NETZWERK ERKANNT", 13, COLOR_RED, true))
		network_box.add_child(_label("Aktiviere den persönlichen Hotspot. Danach können alle Spieler diesem Handy beitreten.", 13, COLOR_INK, false))
		var hotspot_button := _button("ANDROID-HOTSPOT ÖFFNEN", Color(COLOR_RED, 0.20), Callable(self, "_open_hotspot_settings"))
		hotspot_button.custom_minimum_size.y = 52
		network_box.add_child(hotspot_button)
	var refresh_network := _button("Netzwerkstatus aktualisieren", Color(COLOR_SURFACE_2, 0.86), Callable(self, "_refresh_host_network"))
	refresh_network.custom_minimum_size.y = 48
	network_box.add_child(refresh_network)

	var join_card := _card()
	join_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	network_join_details_box.add_child(join_card)
	var join_box := VBoxContainer.new()
	join_box.alignment = BoxContainer.ALIGNMENT_CENTER
	join_box.add_theme_constant_override("separation", 9)
	join_card.add_child(join_box)
	join_box.add_child(_label("BEITRETEN", 14, COLOR_ACCENT, true))
	join_box.add_child(_label("NATIVE HANDY-LOBBY · GLEICHES WLAN", 13, COLOR_GREEN, true))
	join_box.add_child(_label("RAUMCODE", 12, COLOR_MUTED, true))
	var room_big := _label(room_code, 62, COLOR_INK, true)
	room_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	join_box.add_child(room_big)
	var copy_room := _button("Raumcode kopieren", Color(COLOR_PURPLE, 0.18), Callable(self, "_copy_url"), [room_code])
	copy_room.custom_minimum_size.y = 48
	copy_room.add_theme_font_size_override("font_size", 14)
	join_box.add_child(copy_room)
	var refresh_room := _button("Neuer Raumcode", Color(COLOR_SURFACE_2, 0.9), Callable(self, "_refresh_room"))
	refresh_room.custom_minimum_size.y = 48
	refresh_room.add_theme_font_size_override("font_size", 14)
	join_box.add_child(refresh_room)
	var details_toggle := _button("Verbindungsdetails anzeigen", Color(COLOR_SURFACE_2, 0.72), Callable(self, "_toggle_host_connection_details"))
	details_toggle.custom_minimum_size.y = 48
	details_toggle.add_theme_font_size_override("font_size", 13)
	join_box.add_child(details_toggle)
	host_connection_details_box = VBoxContainer.new()
	host_connection_details_box.visible = false
	host_connection_details_box.add_theme_constant_override("separation", 7)
	join_box.add_child(host_connection_details_box)
	host_connection_details_box.add_child(_label("MANUELLE VERBINDUNG · NUR FALLS DISCOVERY NICHT FUNKTIONIERT", 12, COLOR_MUTED, true))
	var displayed_ips: Array[String] = local_ip_addresses.duplicate()
	if displayed_ips.is_empty():
		displayed_ips.append(local_ip)
	var host_ip_label := _label("\n".join(PackedStringArray(displayed_ips)), 18 if displayed_ips.size() > 1 else 26, COLOR_CYAN, true)
	host_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host_connection_details_box.add_child(host_ip_label)
	var copy_ips := _button("Host-IP-Adressen kopieren", Color(COLOR_PURPLE, 0.18), Callable(self, "_copy_host_ips"))
	copy_ips.custom_minimum_size.y = 48
	host_connection_details_box.add_child(copy_ips)
	host_connection_details_box.add_child(_label("Auf jedem Handy: App öffnen → Spiel beitreten → IP und Code eingeben. Beide Geräte müssen lokale Verbindungen im selben WLAN zulassen.", 12, COLOR_MUTED, false))
	var mascot := TextureRect.new()
	mascot.texture = MINDFOX_MASCOT
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.custom_minimum_size = Vector2(190, 78)
	mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	join_box.add_child(mascot)
	join_box.add_child(_label("Keine Browser-Adresse nötig. Alles läuft direkt in der App.", 12, COLOR_GREEN, false))

	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	action_bar.add_child(actions)
	var enough_players := _active_player_count() >= 2
	var start := _button("RUNDE STARTEN" if enough_players else "MINDESTENS 2 SPIELER NÖTIG", Color(COLOR_ACCENT, 0.22), Callable(self, "_start_game"))
	start.custom_minimum_size = Vector2(0, 68)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.disabled = not enough_players
	actions.add_child(start)
	var home_button := _button("← ZUR STARTSEITE", Color(COLOR_SURFACE_2, 0.82), Callable(self, "_return_to_home"))
	home_button.custom_minimum_size.y = 50
	actions.add_child(home_button)
	Monetization.show_lobby_ad()
	if preserve_scroll:
		call_deferred("_restore_body_scroll", previous_scroll)

func _show_rules_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "KURZREGELN · MINDFOX"
	dialog.get_ok_button().text = "Alles klar!"
	dialog.min_size = Vector2(320, 405)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 350)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rules := VBoxContainer.new()
	rules.add_theme_constant_override("separation", 6)
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rules)
	rules.add_child(_brand_mascot(Vector2(96, 96)))
	var add_rule := func(title: String, text: String) -> void:
		rules.add_child(_label(title, 15, COLOR_ACCENT, true))
		rules.add_child(_label(text, 13, COLOR_INK, false))
	var round_rule := "Erfinde eine glaubwürdige falsche Antwort. Jede 3. Runde ist eine Schätzfrage: gib die Zahl mit der angezeigten Einheit ein." if _has_estimation_questions() else "Erfinde eine glaubwürdige falsche Antwort. Schätzrunden sind pausiert, bis Zahlenfragen vorliegen."
	add_rule.call("1 · BLUFFEN ODER SCHÄTZEN", round_rule)
	add_rule.call("2 · ABSTIMMEN", "Wähle die Wahrheit oder einen fremden Bluff – nie deinen eigenen. Der Vertrauensregler steuert Gewinn und Risiko.")
	var points_rule := "Normal: richtig bei 0/50/100 % Sicherheit = +250/+500/+750; falsch kostet bis 50 % nichts, danach bis zu −250. Blufffänge bleiben +250. Rundenregeln können Punkte vervielfachen."
	if _has_estimation_questions():
		points_rule += " Schätzung: Nähe bleibt am wichtigsten; Sicherheit verstärkt gute Tipps abgeschwächt und bestraft weit entfernte Tipps moderat."
	add_rule.call("3 · PUNKTE", points_rule)
	add_rule.call("4 · GEHEIMMISSION", "Erledige deine private Aufgabe unauffällig. Bei Erfolg: ca. 20 % Bonus. Bei Entdeckung: abhaken. Sicherheit und Fairness gehen vor.")
	add_rule.call("5 · SPIELENDE", "%d Runden (Host wählt 3–15). Nach jeder Auflösung geht es weiter, sobald alle bereit sind. Höchste Gesamtpunktzahl gewinnt; Gleichstand: Schätzrunde." % max_rounds)
	dialog.add_child(scroll)
	add_child(dialog)
	dialog.popup_centered(Vector2(minf(get_viewport_rect().size.x - 28.0, 580.0), minf(get_viewport_rect().size.y - 80.0, 640.0)))

func _return_to_home() -> void:
	if native_client != null:
		native_client.disconnect_from_host()
	if embedded_lan != null and is_instance_valid(embedded_lan):
		embedded_lan.queue_free()
		embedded_lan = null
	room_code = ""
	players.clear()
	_show_welcome()

func _select_category(category: String) -> void:
	if category == ALL_AVAILABLE_CATEGORY:
		selected_category = ALL_AVAILABLE_CATEGORY
		_show_lobby()
		return
	if DISCOVERY_CATEGORIES.has(category):
		if not Monetization.is_topic_unlocked(category):
			if Monetization.purchase_topic(category):
				if feedback_label != null and is_instance_valid(feedback_label):
					feedback_label.text = "Der Play-Store-Kauf wird vorbereitet. Nach erfolgreicher Zahlung wird das Thema dauerhaft freigeschaltet."
			if feedback_label != null and is_instance_valid(feedback_label):
				feedback_label.add_theme_color_override("font_color", COLOR_ACCENT)
				return
			selected_category = category
			_show_lobby()

func _on_topic_unlocked(category: String) -> void:
	if app_mode == "HOST" and phase == Phase.LOBBY:
		if selected_category != ALL_AVAILABLE_CATEGORY:
			selected_category = category
		_show_lobby()

func _on_topic_purchase_unavailable(category: String) -> void:
	if feedback_label != null and is_instance_valid(feedback_label):
		var topic_name := "Play-Store-Kauf" if category.is_empty() else "„%s“" % category
		feedback_label.text = "%s ist gerade nicht verfügbar. Prüfe deine Play-Store-Verbindung und versuche es erneut." % topic_name
		feedback_label.add_theme_color_override("font_color", COLOR_ACCENT)

func _on_restore_status(message: String) -> void:
	if feedback_label != null and is_instance_valid(feedback_label):
		feedback_label.text = message
		feedback_label.add_theme_color_override("font_color", COLOR_ACCENT)

func _player_avatar_text(player: Dictionary) -> String:
	if bool(player.get("is_host", false)):
		return "🎤"
	var avatar_index := clampi(int(player.get("avatarIndex", 0)), 0, AVATAR_ICONS.size() - 1)
	return AVATAR_ICONS[avatar_index]

func _player_avatar_image(player: Dictionary, size: int = 54) -> TextureRect:
	var avatar := TextureRect.new()
	var avatar_index := clampi(int(player.get("avatarIndex", 0)), 0, AVATAR_IMAGES.size() - 1)
	avatar.texture = AVATAR_IMAGES[avatar_index]
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.custom_minimum_size = Vector2(size, size)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.tooltip_text = AVATAR_NAMES[avatar_index]
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return avatar

func _podium_quip_for_rank(rank: int) -> String:
	if podium_quips.is_empty() and FileAccess.file_exists(_localized_data_path("podium_quips.json")):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_localized_data_path("podium_quips.json")))
		if parsed is Dictionary:
			podium_quips = parsed
	var choices: Array = podium_quips.get(str(rank), [])
	if choices.is_empty():
		return "Der Applaus ist echt – die Ausrede fürs nächste Spiel bitte auch."
	return str(choices[rng.randi_range(0, choices.size() - 1)])

func _shuffle_challenge_pool() -> void:
	challenge_pool_order = challenge_tasks.duplicate(true)
	for i in range(challenge_pool_order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap_value: Variant = challenge_pool_order[i]
		challenge_pool_order[i] = challenge_pool_order[j]
		challenge_pool_order[j] = swap_value
	challenge_pool_cursor = 0

func _assign_challenge_to_player(player: Dictionary) -> void:
	player["challengeText"] = ""
	player["challengeCaught"] = not bool(player.get("is_human", false))
	player["challengeBonus"] = 0
	if not bool(player.get("is_human", false)) or challenge_pool_cursor >= challenge_pool_order.size():
		return
	var task: Dictionary = challenge_pool_order[challenge_pool_cursor]
	challenge_pool_cursor += 1
	player["challengeText"] = str(task.get("text", ""))
	player["challengeCaught"] = false

func _assign_challenges_for_game() -> bool:
	if not secret_missions_enabled:
		challenge_session_active = false
		challenge_rewards_settled = true
		challenge_details_open = false
		for player in players:
			player["challengeText"] = ""
			player["challengeCaught"] = true
			player["challengeBonus"] = 0
		if challenge_dock != null and is_instance_valid(challenge_dock):
			challenge_dock.visible = false
		return true
	if challenge_tasks.size() != 300:
		return false
	challenge_details_open = false
	_shuffle_challenge_pool()
	challenge_session_active = true
	challenge_rewards_settled = false
	for player in players:
		_assign_challenge_to_player(player)
		if bool(player.get("is_human", false)) and str(player.get("id", "")) != "host":
			_send_client(str(player.get("id", "")), "PLAYER_CHALLENGE", {"text": str(player.get("challengeText", "")), "caught": false})
	var host := _find_player("host")
	_update_challenge_dock(str(host.get("challengeText", "")), bool(host.get("challengeCaught", false)))
	return not str(host.get("challengeText", "")).is_empty()

func _update_challenge_dock(text: String, caught: bool, resolved: bool = false, bonus: int = 0) -> void:
	if challenge_dock == null or not is_instance_valid(challenge_dock):
		return
	if not secret_missions_enabled:
		challenge_dock.visible = false
		return
	challenge_dock.visible = not text.is_empty()
	if not challenge_dock.visible:
		return
	challenge_detail_row.visible = challenge_details_open or resolved or caught
	challenge_toggle_button.text = "MISSION ERGEBNIS ANSEHEN" if resolved or caught else ("MISSION AUSBLENDEN" if challenge_details_open else "MISSION ANSEHEN")
	challenge_text_label.text = text
	if resolved:
		challenge_header_label.text = "MISSION ERFÜLLT · +%d PUNKTE" % bonus if bonus > 0 else "MISSION BEENDET · KEIN BONUS"
		challenge_caught_button.button_pressed = caught
		challenge_caught_button.disabled = true
	elif caught:
		challenge_header_label.text = "ERWISCHT · DIESMAL KEIN MISSIONSBONUS"
		challenge_caught_button.button_pressed = true
		challenge_caught_button.disabled = true
	else:
		challenge_header_label.text = "GEHEIMMISSION · CA. 20 % DER MÖGLICHEN RUNDENPUNKTE"
		challenge_caught_button.button_pressed = false
		challenge_caught_button.disabled = false

func _toggle_challenge_details() -> void:
	if challenge_detail_row == null or not is_instance_valid(challenge_detail_row):
		return
	challenge_details_open = not challenge_details_open
	challenge_detail_row.visible = challenge_details_open
	if challenge_toggle_button != null and is_instance_valid(challenge_toggle_button):
		challenge_toggle_button.text = "MISSION AUSBLENDEN" if challenge_details_open else "MISSION ANSEHEN"

func _toggle_confidence_system() -> void:
	if phase != Phase.LOBBY or app_mode != "HOST":
		return
	confidence_system_enabled = not confidence_system_enabled
	_show_lobby()

func _toggle_secret_missions() -> void:
	if phase != Phase.LOBBY or app_mode != "HOST":
		return
	secret_missions_enabled = not secret_missions_enabled
	challenge_session_active = false
	challenge_details_open = false
	if challenge_dock != null and is_instance_valid(challenge_dock):
		challenge_dock.visible = false
	_show_lobby()

func _toggle_reveal_details() -> void:
	if reveal_details_panel == null or not is_instance_valid(reveal_details_panel):
		return
	reveal_details_open = not reveal_details_open
	reveal_details_panel.visible = reveal_details_open
	if reveal_details_toggle != null and is_instance_valid(reveal_details_toggle):
		reveal_details_toggle.text = "DETAILS AUSBLENDEN" if reveal_details_open else "ALLE DETAILS ANZEIGEN"

func _on_challenge_caught_toggled(pressed: bool) -> void:
	if not pressed:
		return
	challenge_caught_button.disabled = true
	if app_mode == "HOST":
		_mark_challenge_caught("host")
	elif app_mode == "CLIENT":
		native_challenge_caught = true
		_update_challenge_dock(native_challenge_text, true, native_challenge_resolved, native_challenge_bonus)
		if native_client != null:
			native_client.send_challenge_caught()

func _mark_challenge_caught(player_id: String) -> void:
	if not challenge_session_active or challenge_rewards_settled or phase == Phase.PODIUM:
		return
	var player := _find_player(player_id)
	if player.is_empty() or not bool(player.get("is_human", false)) or str(player.get("challengeText", "")).is_empty():
		return
	player["challengeCaught"] = true
	if player_id == "host":
		_update_challenge_dock(str(player.get("challengeText", "")), true)
	else:
		_send_client(player_id, "PLAYER_CHALLENGE_STATUS", {"caught": true})

func _challenge_reward_points() -> int:
	var participant_count := clampi(_active_player_count(), 2, MAX_PLAYERS)
	var possible_round_points := 0
	for game_round in range(max_rounds):
		var is_estimation := estimation_questions_available and ((game_round + 1) % 3 == 0)
		if is_estimation:
			# Schätzrunde: nächster Tipp + Wahrheit + mögliche Bluff-Fänge.
			possible_round_points += 900 + 500 + (participant_count - 1) * 250
			continue
		var directive := _directive_for_round(game_round)
		var multiplier := maxi(1, int(directive.get("multiplier", 1)))
		var truth_bonus := maxi(0, int(directive.get("truthBonus", 0)))
		var perfect_round := 500 + truth_bonus + 100 + (participant_count - 1) * 250
		possible_round_points += perfect_round * multiplier
	var reward := int(round(float(possible_round_points) * CHALLENGE_REWARD_SHARE / 50.0) * 50.0)
	return maxi(reward, 50)

func _settle_challenge_rewards() -> void:
	if challenge_rewards_settled:
		return
	challenge_rewards_settled = true
	challenge_session_active = false
	for player in players:
		var text := str(player.get("challengeText", ""))
		var caught := bool(player.get("challengeCaught", true))
		var bonus := 0
		if bool(player.get("is_human", false)) and not text.is_empty() and not caught:
			bonus = _challenge_reward_points()
			player["score"] = int(player.get("score", 0)) + bonus
			player["delta"] = int(player.get("delta", 0)) + bonus
		player["challengeBonus"] = bonus
		player["challengeResolved"] = true
	var host := _find_player("host")
	_update_challenge_dock(str(host.get("challengeText", "")), bool(host.get("challengeCaught", true)), true, int(host.get("challengeBonus", 0)))

func _start_game() -> void:
	if phase != Phase.LOBBY:
		return
	app_mode = "HOST"
	_ensure_host_server()
	if not players.is_empty() and host_name_input != null:
		var entered_host_name := host_name_input.text.strip_edges().left(18)
		if not entered_host_name.is_empty():
			players[0].name = entered_host_name
		players[0].avatarIndex = selected_avatar
		players[0].avatarTint = selected_avatar_tint
		players[0].avatarExpression = selected_avatar_expression
		players[0].avatar_expression = AVATAR_EXPRESSIONS[selected_avatar_expression]
	if _active_player_count() < 2:
		if feedback_label != null and is_instance_valid(feedback_label):
			feedback_label.text = "Mindestens zwei aktive Spieler müssen verbunden sein."
		return
	if secret_missions_enabled and challenge_tasks.size() != 300:
		feedback_label.text = "Die Geheimmissionen konnten nicht geladen werden. Bitte App aktualisieren."
		return
	_set_game_orientation(true)
	round_index = 0
	previous_best_lie = ""
	tiebreak_active = false
	tiebreak_players.clear()
	_prepare_question_order()
	for player in players:
		player.score = 0
	if not _assign_challenges_for_game():
		challenge_session_active = false
		feedback_label.text = "Geheimmission konnte nicht verteilt werden. Bitte erneut versuchen."
		return
	host_gate_ready = false
	embedded_lan.begin_ready_gate("LOBBY")
	_show_ready_gate("Alle auf GO!", "Die Runde startet erst, wenn jeder verbundene Spieler bereit ist.")

func _host_ready() -> void:
	if host_gate_ready:
		return
	host_gate_ready = true
	var phase_before_gate := phase
	embedded_lan.mark_host_ready()
	if phase != phase_before_gate:
		return
	if phase == Phase.SCOREBOARD:
		return
	if phase == Phase.PODIUM:
		return
	if phase == Phase.REVEAL:
		# Die Ergebnisansicht bleibt sichtbar, bis alle bereit sind. Der
		# synchronisierte Countdown wird darüber eingeblendet und führt direkt
		# in die nächste Quizfrage – ohne zusätzliche Ready-Seite.
		_show_ready_gate("Auflösung bereit", "Der Host sieht jetzt denselben Stand wie die Spieler.")
		return
	_show_ready_gate("GO gespeichert", "Du bist bereit. Der Showrunner wartet noch auf die anderen Daumen.")

func _on_gate_completed(kind: String) -> void:
	host_gate_ready = false
	if kind == "LOBBY":
		_show_input()
	elif kind == "ROUND":
		_start_gate_transition(kind)
	elif kind == "PODIUM":
		_start_gate_transition(kind)
	elif kind == "REMATCH":
		_start_gate_transition(kind)

func _start_gate_transition(kind: String) -> void:
	if gate_transition_seconds >= 0.0:
		return
	if kind == "ROUND" and not tiebreak_active and round_index >= max_rounds - 1:
		# Nach der letzten regulären Runde führt WEITER direkt zur Platzierung.
		_advance_after_gate(kind)
		return
	gate_transition_kind = kind
	gate_transition_seconds = 3.0
	gate_transition_last_second = -1
	_set_phase_text("BEREIT · ALLE AUF GO")

func _show_flying_countdown(seconds: int) -> void:
	if seconds <= 0:
		return
	if gate_countdown_label != null and is_instance_valid(gate_countdown_label):
		gate_countdown_label.queue_free()
	gate_countdown_label = Label.new()
	gate_countdown_label.text = str(seconds)
	gate_countdown_label.z_index = 100
	gate_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gate_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gate_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gate_countdown_label.add_theme_font_override("font", FONT_BOLD)
	gate_countdown_label.add_theme_font_size_override("font_size", 312)
	gate_countdown_label.add_theme_color_override("font_color", COLOR_ACCENT)
	gate_countdown_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.85, 0.95, 0.9))
	gate_countdown_label.add_theme_constant_override("shadow_offset_x", 5)
	gate_countdown_label.add_theme_constant_override("shadow_offset_y", 7)
	gate_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	gate_countdown_label.position += Vector2(0, 140)
	gate_countdown_label.scale = Vector2(0.25, 0.25)
	add_child(gate_countdown_label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(gate_countdown_label, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(gate_countdown_label, "position", gate_countdown_label.position - Vector2(0, 140), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(gate_countdown_label, "modulate", Color(1, 1, 1, 0.0), 0.22).set_delay(0.48)

func _advance_after_gate(kind: String) -> void:
	if kind == "ROUND":
		if tiebreak_active:
			_show_podium()
		elif round_index >= max_rounds - 1:
			_show_scoreboard() if _final_has_tie() else _show_podium()
		else:
			_next_round()
	elif kind == "PODIUM":
		_show_podium()
	elif kind == "REMATCH":
		_new_game()

func _show_ready_gate(title: String, detail: String) -> void:
	_clear_body()
	_set_phase_text("READY-GATE · ALLE AUF GO")
	body.add_child(_label(title, 34, COLOR_INK, true))
	body.add_child(_label(detail, 17, COLOR_MUTED, false))
	var card := _card(Color("163b3b"), Color(COLOR_GREEN, 0.75))
	card.custom_minimum_size.y = 130
	body.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var waiting_names: Array[String] = []
	var ready_count := 0
	var gate_total := 0
	if embedded_lan != null and embedded_lan.gate_active:
		gate_total = embedded_lan.gate_ready.size()
		for player_id in embedded_lan.gate_ready.keys():
			if bool(embedded_lan.gate_ready[player_id]):
				ready_count += 1
			else:
				waiting_names.append(str(embedded_lan.gate_names.get(player_id, "Gast")))
		var gate_status := "%d/%d bereit · Warte auf: %s" % [ready_count, gate_total, ", ".join(waiting_names)] if not waiting_names.is_empty() else "Alle %d Spieler bereit · Start möglich" % gate_total
		box.add_child(_label(gate_status, 14, COLOR_ACCENT if not waiting_names.is_empty() else COLOR_GREEN, true))
	var host_ready_state := _derive_ready_state(host_gate_ready, ready_count, gate_total)
	box.add_child(_label("HOST · %s" % _ready_state_copy(host_ready_state, maxi(0, gate_total - ready_count)), 18, COLOR_GREEN if host_ready_state == ReadyState.ALL_READY or host_gate_ready else COLOR_ACCENT, true))
	var go := _button("ICH BIN BEREIT · GO!" if host_ready_state == ReadyState.PLAYER_NOT_READY else ("ALLE BEREIT · STARTEN" if host_ready_state == ReadyState.ALL_READY else "BEREIT ✓ · WARTE AUF ALLE"), Color(COLOR_GREEN, 0.25), Callable(self, "_host_ready"))
	go.custom_minimum_size = Vector2(360, 72)
	go.disabled = host_gate_ready
	action_bar.add_child(go)
	if not host_gate_ready:
		_pulse_control(go)
	var skip := _button("Spieler überspringen · Admin", Color(COLOR_RED, 0.16), Callable(self, "_confirm_host_skip_gate"))
	skip.custom_minimum_size = Vector2(270, 44)
	action_bar.add_child(skip)
	_add_admin_button()

func _confirm_host_skip_gate() -> void:
	if embedded_lan == null or not embedded_lan.gate_active:
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Ready-Gate überspringen?"
	dialog.dialog_text = "Nicht alle Spieler sind bereit. Trotzdem zur nächsten Seite wechseln?"
	dialog.ok_button_text = "Trotzdem weiter"
	dialog.cancel_button_text = "Abbrechen"
	dialog.confirmed.connect(func() -> void:
		if embedded_lan != null and embedded_lan.gate_active:
			embedded_lan.skip_gate()
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _active_human_ids() -> Array:
	var result := []
	for player in players:
		if bool(player.get("is_human", false)) and bool(player.get("active", true)) and bool(player.get("connected", true)):
			result.append(str(player.id))
	return result

func _expire_paused_players() -> void:
	var now := Time.get_ticks_msec()
	var changed := false
	for player in players:
		if not bool(player.get("is_human", false)) or bool(player.get("connected", true)):
			continue
		var deadline := int(player.get("reconnectDeadlineMs", 0))
		if deadline > 0 and now >= deadline:
			player.active = false
			player.reconnectDeadlineMs = 0
			changed = true
	if changed and embedded_lan != null:
		embedded_lan.set_player_count(_active_player_count())

func _update_round_progress(label: String, submitted: Dictionary) -> void:
	var ready_names: Array[String] = []
	var waiting_names: Array[String] = []
	for player in players:
		if not bool(player.get("is_human", false)) or not bool(player.get("active", true)) or not bool(player.get("connected", true)):
			continue
		var player_id := str(player.get("id", ""))
		if submitted.has(player_id):
			ready_names.append(str(player.get("name", "Spieler")))
		else:
			waiting_names.append(str(player.get("name", "Spieler")))
	var total := ready_names.size() + waiting_names.size()
	var text := "%s %d/%d" % [label, ready_names.size(), total]
	if not waiting_names.is_empty():
		text += " · wartet: " + ", ".join(waiting_names)
	else:
		text += " · alle bereit"
	if round_progress_label != null and is_instance_valid(round_progress_label):
		round_progress_label.text = text
		round_progress_label.add_theme_color_override("font_color", COLOR_ACCENT if not waiting_names.is_empty() else COLOR_GREEN)
	if embedded_lan != null and app_mode == "HOST":
		embedded_lan.publish([{"type": "ROUND_PROGRESS", "payload": {"label": label, "submittedCount": ready_names.size(), "total": total, "waiting": waiting_names}}])

func _eligible_input_ids() -> Array:
	if not tiebreak_active:
		return _active_human_ids()
	var result: Array = []
	for player_id in tiebreak_players:
		var player := _find_player(player_id)
		if not player.is_empty() and bool(player.get("is_human", false)) and bool(player.get("active", true)) and bool(player.get("connected", true)):
			result.append(player_id)
	return result

func _find_player(player_id: String) -> Dictionary:
	for player in players:
		if str(player.id) == player_id:
			return player
	return {}

func _fooled_player_breakdown(owner_id: String, points_each: int) -> Array:
	var result: Array = []
	for voter_id in votes.keys():
		if str(votes.get(voter_id, "")) == "lie:" + owner_id:
			var voter := _find_player(str(voter_id))
			result.append({"id": str(voter_id), "name": str(voter.get("name", "Spieler")), "points": points_each})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("name", "")).to_lower() < str(b.get("name", "")).to_lower())
	return result

func _leader_result_score(results: Array) -> int:
	var best := 0
	for result in results:
		best = maxi(best, int(result.get("score", 0)))
	return best

func _leader_result_name(results: Array) -> String:
	var leader_name := "Noch offen"
	var best := -1
	for result in results:
		var score := int(result.get("score", 0))
		if score > best:
			best = score
			leader_name = str(result.get("name", "Spieler"))
	return leader_name

func _update_score_hud(status: Dictionary) -> void:
	if score_hud == null or not is_instance_valid(score_hud):
		return
	score_hud.visible = true
	if score_own_label != null:
		score_own_label.text = "DEIN GESAMTSTAND · %d" % int(status.get("ownScore", 0))
	if score_leader_label != null:
		score_leader_label.text = "AKTUELL VORN · %s · %d Pkt" % [str(status.get("leaderName", "Noch offen")), int(status.get("leaderScore", 0))]

func _score_summary_for_player(player_id: String) -> Dictionary:
	var own_player := _find_player(player_id)
	var own_score := int(own_player.get("score", 0))
	var leader_name := "Noch offen"
	var leader_score := 0
	var has_leader := false
	for player in players:
		var candidate_score := int(player.get("score", 0))
		if not has_leader or candidate_score > leader_score:
			leader_name = str(player.get("name", "Spieler"))
			leader_score = candidate_score
			has_leader = true
	return {"ownScore": own_score, "leaderScore": leader_score, "leaderName": leader_name}

func _on_round_count_selected(index: int) -> void:
	if phase != Phase.LOBBY:
		return
	max_rounds = clampi(index + MIN_ROUNDS, MIN_ROUNDS, ROUND_COUNT_MAX)
	_publish_lobby_state()

func _send_client(player_id: String, kind: String, payload: Dictionary) -> void:
	if embedded_lan != null:
		embedded_lan.send_to_player(player_id, kind, payload)

func _send_current_state_to_player(player_id: String) -> void:
	if embedded_lan == null or phase == Phase.LOBBY:
		return
	if phase == Phase.INPUT:
		embedded_lan.send_to_player(player_id, "SHOW_DIRECTIVE", current_directive)
		embedded_lan.send_to_player(player_id, "PHASE_CHANGE", {"newPhase": "INPUT", "timeLimitSec": maxf(0.0, countdown), "round": round_index + 1, "maxRounds": max_rounds, "prompt": str(active_question.get("prompt", "")), "category": str(active_question.get("category", selected_category)), "estimate": _is_estimation_round() or tiebreak_active, "estimateUnit": str(active_question.get("estimate_unit", "Zahl")), "tiebreak": tiebreak_active, "eligibleIds": tiebreak_players})
		embedded_lan.send_to_player(player_id, "QUESTION_BROADCAST", {"questionId": str(active_question.get("id", "")), "prompt": str(active_question.get("prompt", "")), "category": str(active_question.get("category", selected_category)), "difficulty": str(active_question.get("difficulty", "mittel")), "round": round_index + 1})
		if submitted_lies.has(player_id):
			embedded_lan.send_to_player(player_id, "SUBMIT_ACK", {"accepted": true, "reason": "RECONNECTED"})
		elif phase == Phase.VOTING:
			var filtered: Array = []
			for option in current_options:
				if str(option.get("ownerId", "")) != player_id:
					filtered.append(option)
			embedded_lan.send_to_player(player_id, "PHASE_CHANGE", {"newPhase": "VOTING", "timeLimitSec": maxf(0.0, countdown), "round": round_index + 1, "maxRounds": max_rounds})
			var player_score_status := _score_summary_for_player(player_id)
			var vote_payload := {"options": filtered, "round": round_index + 1, "maxRounds": max_rounds, "questionId": str(active_question.get("id", "")), "question": str(active_question.get("prompt", "")), "confidenceEnabled": confidence_system_enabled}
			vote_payload.merge(player_score_status, true)
			embedded_lan.send_to_player(player_id, "VOTE_OPTIONS_LIST", vote_payload)
			if submitted_votes.has(player_id):
				embedded_lan.send_to_player(player_id, "VOTE_ACK", {"accepted": true, "reason": "RECONNECTED"})
	elif phase == Phase.REVEAL:
		embedded_lan.send_to_player(player_id, "PHASE_CHANGE", {"newPhase": "REVEAL", "timeLimitSec": 0, "round": round_index + 1})
		if not network_reveal_snapshot.is_empty():
			embedded_lan.send_to_player(player_id, "ROUND_REVEAL_DATA", network_reveal_snapshot)
	elif phase == Phase.SCOREBOARD:
		if not network_score_snapshot.is_empty():
			embedded_lan.send_to_player(player_id, "PHASE_CHANGE", network_score_snapshot)
	elif phase == Phase.PODIUM:
		if not network_podium_snapshot.is_empty():
			embedded_lan.send_to_player(player_id, "PHASE_CHANGE", network_podium_snapshot)

func _on_client_event(event: Dictionary) -> void:
	var kind := str(event.get("type", ""))
	var player_id := str(event.get("playerId", ""))
	if kind == "CONNECT":
		var player_name := str(event.get("playerName", "Gast")).left(18)
		var requested_tint := clampi(int(event.get("avatarTint", 0)), 0, AVATAR_TINTS.size() - 1)
		var requested_expression := clampi(int(event.get("avatarExpression", 0)), 0, AVATAR_EXPRESSIONS.size() - 1)
		var existing := _find_player(player_id)
		if existing.is_empty():
			var avatar_index := _random_free_avatar()
			if _active_player_count() >= MAX_PLAYERS or avatar_index < 0:
				_send_client(player_id, "JOIN_ERROR", {"reason": "ROOM_FULL"})
				return
			players.append({"id": player_id, "name": player_name, "avatarIndex": avatar_index, "avatarTint": requested_tint, "avatarExpression": requested_expression, "avatar_expression": AVATAR_EXPRESSIONS[requested_expression], "score": 0, "lie": "", "fooled": 0, "deceived_total": 0, "correct": 0, "delta": 0, "confidence": 50, "confidence_award": "", "role": "", "role_hint": "", "role_task": "", "is_host": false, "is_human": true, "active": true, "connected": true, "reconnectDeadlineMs": 0})
		else:
			var assigned_avatar := int(existing.get("avatarIndex", -1))
			if _avatar_taken_by_other(assigned_avatar, player_id):
				assigned_avatar = _random_free_avatar(player_id)
				if assigned_avatar >= 0:
					existing.avatarIndex = assigned_avatar
				existing.name = player_name
				existing.active = true
				existing.connected = true
				existing.reconnectDeadlineMs = 0
		if embedded_lan != null:
			embedded_lan.send_player_count(_active_player_count())
			embedded_lan.set_player_count(_active_player_count())
			if challenge_session_active:
				var joined := _find_player(player_id)
				if not joined.is_empty() and str(joined.get("challengeText", "")).is_empty():
					_assign_challenge_to_player(joined)
				if not joined.is_empty() and not str(joined.get("challengeText", "")).is_empty():
					_send_client(player_id, "PLAYER_CHALLENGE", {"text": str(joined.get("challengeText", "")), "caught": bool(joined.get("challengeCaught", false))})
			if app_mode == "HOST":
				if phase == Phase.LOBBY:
					_show_lobby()
				else:
					_broadcast_lobby_players()
					_send_current_state_to_player(player_id)
					_refresh_rocket_targets()
			return
		if kind == "DISCONNECT":
			var disconnected := _find_player(player_id)
			if not disconnected.is_empty():
				disconnected.connected = false
				disconnected.reconnectDeadlineMs = Time.get_ticks_msec() + RECONNECT_GRACE_MS
				if embedded_lan != null and embedded_lan.gate_active:
					embedded_lan.gate_ready.erase(player_id)
					embedded_lan.gate_names.erase(player_id)
					embedded_lan._publish_gate()
				if phase == Phase.INPUT and submitted_lies.size() >= _eligible_input_ids().size():
					_show_voting()
				elif phase == Phase.VOTING and submitted_votes.size() >= _active_human_ids().size():
					_show_reveal()
			if embedded_lan != null:
				embedded_lan.set_player_count(_active_player_count())
			if app_mode == "HOST":
				if phase == Phase.LOBBY:
					_show_lobby()
				else:
					_broadcast_lobby_players()
					_refresh_rocket_targets()
			return
	if kind == "READY_GATE_REQ":
		if app_mode == "HOST" and embedded_lan != null and embedded_lan.gate_active:
			_show_ready_gate("Auflösung bereit" if phase == Phase.REVEAL else "Alle auf GO!", "Die Runde startet erst, wenn jeder verbundene Spieler bereit ist.")
		return
	if kind == "AVATAR_CHANGE_REQ":
		var target_player := _find_player(player_id)
		var avatar_payload: Dictionary = event.get("payload", {})
		var requested_avatar := int(avatar_payload.get("avatarIndex", -1))
		if phase == Phase.LOBBY and requested_avatar >= 0 and requested_avatar < AVATAR_IMAGES.size() and not target_player.is_empty() and bool(target_player.get("active", true)) and bool(target_player.get("is_human", false)) and not _avatar_taken_by_other(requested_avatar, player_id):
			target_player.avatarIndex = requested_avatar
			_show_lobby()
		elif phase == Phase.LOBBY:
			_broadcast_lobby_players()
		return
	if kind == "PLAYER_ROCKET_REQ":
		var rocket_request: Dictionary = event.get("payload", {})
		_route_player_rocket(player_id, str(rocket_request.get("targetId", "")))
		return
	if kind == "CHALLENGE_CAUGHT":
		_mark_challenge_caught(player_id)
	elif kind == "SUBMIT_LIE_REQ":
		_submit_remote_lie(player_id, event.get("payload", {}))
	elif kind == "SUBMIT_VOTE_REQ":
		_submit_remote_vote(player_id, event.get("payload", {}))
	elif kind == "EMOJI_PING":
		var emoji_payload: Dictionary = event.get("payload", {})
		var emoji := str(emoji_payload.get("emoji", ""))
		if REACTION_EMOJIS.has(emoji) and embedded_lan != null:
			embedded_lan.broadcast_event("EMOJI_PING", {"emoji": emoji, "from": player_id})
			_show_emoji_reaction(emoji)

func _submit_remote_lie(player_id: String, payload: Dictionary) -> void:
	if phase != Phase.INPUT:
		_send_client(player_id, "SUBMIT_ACK", {"accepted": false, "reason": "WRONG_PHASE"})
		return
	var active_question_id := str(active_question.get("id", ""))
	if active_question_id.is_empty() or str(payload.get("questionId", "")) != active_question_id:
		_send_client(player_id, "SUBMIT_ACK", {"accepted": false, "reason": "STALE_QUESTION"})
		return
	var player := _find_player(player_id)
	if player.is_empty() or not bool(player.get("is_human", false)):
		return
	var value := _clean_text(str(payload.get("lieText", "")))
	if submitted_lies.has(player_id):
		var was_accepted := str(submitted_lies[player_id]) == value
		_send_client(player_id, "SUBMIT_ACK", {"accepted": was_accepted, "reason": "ALREADY_ACCEPTED" if was_accepted else "ALREADY_SUBMITTED"})
		return
	var reason := ""
	if value.is_empty(): reason = "EMPTY"
	elif (_is_estimation_round() or tiebreak_active) and not _is_numeric_estimate(value): reason = "NEEDS_NUMBER"
	elif value.length() > 75: reason = "TOO_LONG"
	if not reason.is_empty():
		_send_client(player_id, "SUBMIT_ACK", {"accepted": false, "reason": reason})
		_send_client(player_id, "INPUT_FEEDBACK", {"accepted": false, "reason": reason})
		return
	player.lie = value
	submitted_lies[player_id] = value
	_update_round_progress("Antworten", submitted_lies)
	_send_client(player_id, "SUBMIT_ACK", {"accepted": true, "reason": "OK"})
	_send_client(player_id, "INPUT_FEEDBACK", {"accepted": true, "reason": "OK"})
	if submitted_lies.size() >= _eligible_input_ids().size():
		host_selected_option = ""
		_show_voting()

func _submit_remote_vote(player_id: String, payload: Dictionary) -> void:
	if phase != Phase.VOTING:
		_send_client(player_id, "VOTE_ACK", {"accepted": false, "reason": "WRONG_PHASE"})
		return
	if str(payload.get("questionId", "")) != str(active_question.get("id", "")):
		_send_client(player_id, "VOTE_ACK", {"accepted": false, "reason": "STALE_QUESTION"})
		return
	var option_id := str(payload.get("selectedOptionId", "")).strip_edges()
	var own_id := "lie:" + player_id
	if submitted_votes.has(player_id):
		var same_vote := str(submitted_votes[player_id]) == option_id
		_send_client(player_id, "VOTE_ACK", {"accepted": same_vote, "reason": "ALREADY_ACCEPTED" if same_vote else "ALREADY_SUBMITTED"})
		return
	var valid := option_id.is_empty()
	for option in current_options:
		if str(option.id) == option_id and option_id != own_id:
			valid = true
			break
	if not valid:
		_send_client(player_id, "VOTE_ACK", {"accepted": false, "reason": "INVALID_OPTION"})
		return
	submitted_votes[player_id] = option_id
	votes[player_id] = option_id
	_update_round_progress("Tipps", submitted_votes)
	var player := _find_player(player_id)
	if not player.is_empty(): player.confidence = clampi(int(payload.get("confidence", 50)), 0, 100)
	_send_client(player_id, "VOTE_ACK", {"accepted": true})
	if submitted_votes.size() >= _active_human_ids().size():
		_show_reveal()

func _refresh_room() -> void:
	room_code = _new_room_code()
	_show_lobby()

func _toggle_chain_bluff() -> void:
	chain_bluff = not chain_bluff
	_show_lobby()

func _showrunner_modes() -> Array:
	var modes: Array = showrunner_config.get("modes", [])
	return modes if not modes.is_empty() else [{"id": "classic", "title": "Klassisch", "rounds": []}]

func _showrunner_mode_title() -> String:
	for mode in _showrunner_modes():
		if str(mode.get("id", "")) == showrunner_mode:
			return str(mode.get("title", "Klassisch"))
	return "Klassisch"

func _cycle_showrunner_mode() -> void:
	var modes := _showrunner_modes()
	showrunner_mode_index = (showrunner_mode_index + 1) % modes.size()
	showrunner_mode = str(modes[showrunner_mode_index].get("id", "classic"))
	_show_lobby()

func _directive_for_round(index: int) -> Dictionary:
	var selected: Dictionary = {}
	for mode in _showrunner_modes():
		if str(mode.get("id", "")) == showrunner_mode:
			selected = mode
	if selected.is_empty():
		selected = _showrunner_modes()[0]
	var rounds: Array = selected.get("rounds", [])
	if rounds.is_empty():
		return {"id": "classic", "title": "Klassische Runde", "cue": "Die Show läuft nach den Grundregeln.", "inputHint": "Erfinde eine glaubwürdige Falschantwort.", "votingHint": "Welche Aussage ist wahr?", "revealCue": "Die Wahrheit kommt ans Licht.", "multiplier": 1}
	return rounds[index % rounds.size()].duplicate(true)

func _add_bot() -> void:
	if _active_player_count() >= MAX_PLAYERS:
		return
	var names := ["Juri", "Nele", "Oskar", "Toni"]
	var bot_name: String = names[(players.size() - 4) % names.size()]
	var avatar_index := _next_free_avatar()
	if avatar_index < 0:
		return
	players.append({"id": "bot_%d" % (players.size() + 1), "name": bot_name, "avatarIndex": avatar_index, "avatarTint": players.size() % AVATAR_TINTS.size(), "avatarExpression": players.size() % AVATAR_EXPRESSIONS.size(), "avatar_expression": AVATAR_EXPRESSIONS[players.size() % AVATAR_EXPRESSIONS.size()], "score": 0, "lie": "", "fooled": 0, "deceived_total": 0, "correct": 0, "delta": 0, "confidence": 50, "confidence_award": "", "role": "", "role_hint": "", "role_task": "", "is_host": false, "is_human": false, "active": true})
	_show_lobby()

func _active_player_count() -> int:
	var count := 0
	for player in players:
		if bool(player.get("active", true)):
			count += 1
	return count

func _avatar_taken_by_other(index: int, player_id: String) -> bool:
	for player in players:
		if bool(player.get("active", true)) and str(player.get("id", "")) != player_id and int(player.get("avatarIndex", -1)) == index:
			return true
	return false

func _next_free_avatar() -> int:
	for index in range(AVATAR_IMAGES.size()):
		if not _avatar_in_use(index):
			return index
	return -1

func _random_free_avatar(exclude_player_id: String = "") -> int:
	var available: Array[int] = []
	for index in range(AVATAR_IMAGES.size()):
		if not _avatar_taken_by_other(index, exclude_player_id):
			available.append(index)
	return available.pick_random() if not available.is_empty() else -1

func _avatar_in_use(index: int) -> bool:
	for player in players:
		if bool(player.get("active", true)) and int(player.get("avatarIndex", -1)) == index:
			return true
	return false

func _broadcast_lobby_players() -> void:
	if embedded_lan == null:
		return
	var room_players: Array = []
	for player in players:
		if not bool(player.get("active", true)):
			continue
		room_players.append({"id": str(player.get("id", "")), "name": str(player.get("name", "Spieler")), "avatarIndex": int(player.get("avatarIndex", 0)), "avatarTint": int(player.get("avatarTint", 0)), "avatarExpression": int(player.get("avatarExpression", 0)), "isHost": bool(player.get("is_host", false)), "isHuman": bool(player.get("is_human", true))})
	embedded_lan.broadcast_event("LOBBY_PLAYERS", {"players": room_players, "maxRounds": max_rounds, "category": selected_category, "secretMissionsEnabled": secret_missions_enabled, "confidenceEnabled": confidence_system_enabled, "showMode": showrunner_mode})

func _publish_lobby_state() -> void:
	if embedded_lan == null or phase != Phase.LOBBY:
		return
	embedded_lan.set_discovery_metadata("Bluff-Host", selected_category)
	embedded_lan.publish([{"type": "ROOM_STATE", "payload": {"playerCount": _active_player_count(), "phase": "LOBBY", "round": 0, "maxRounds": max_rounds, "category": selected_category, "roomCode": room_code, "showMode": showrunner_mode, "secretMissionsEnabled": secret_missions_enabled, "confidenceEnabled": confidence_system_enabled}}])
	_broadcast_lobby_players()

func _remove_bot(bot_id: String) -> void:
	if phase != Phase.LOBBY:
		return
	for index in range(players.size() - 1, -1, -1):
		var player: Dictionary = players[index]
		if str(player.get("id", "")) == bot_id and not bool(player.get("is_human", true)):
			players.remove_at(index)
			break
	_show_lobby()

func _show_input() -> void:
	_set_game_orientation(true)
	phase = Phase.INPUT
	countdown = 18.0 if (_is_estimation_round() or tiebreak_active) else 45.0
	_timer_refresh = -1
	var estimate_draw_index := round_index
	if _is_estimation_round():
		estimate_draw_index = int((round_index + 1) / 3) - 1
	active_question = _estimation_question_for_round(estimate_draw_index) if (_is_estimation_round() or tiebreak_active) else _question_for_round(round_index)
	_mark_question_seen(active_question)
	current_directive = _directive_for_round(round_index)
	chain_bluff = str(current_directive.get("id", "")) == "chain_bluff"
	current_options.clear()
	votes.clear()
	submitted_lies.clear()
	submitted_votes.clear()
	_assign_round_roles()
	for player in players:
		player.lie = ""
		player.fooled = 0
		player.delta = 0
	_prepare_bot_lies()
	if score_hud != null:
		score_hud.visible = true
		_update_score_hud(_score_summary_for_player("host"))
	if embedded_lan != null:
		embedded_lan.publish([
			{"type": "SHOW_DIRECTIVE", "payload": current_directive},
				{"type": "PHASE_CHANGE", "payload": {"newPhase": "INPUT", "timeLimitSec": 18 if (_is_estimation_round() or tiebreak_active) else 45, "round": round_index + 1, "maxRounds": max_rounds, "prompt": str(active_question.get("prompt", "")), "category": str(active_question.get("category", selected_category)), "estimate": _is_estimation_round() or tiebreak_active, "estimateUnit": str(active_question.get("estimate_unit", "Zahl")), "tiebreak": tiebreak_active, "eligibleIds": tiebreak_players}},
			{"type": "QUESTION_BROADCAST", "payload": {"questionId": str(active_question.get("id", "")), "prompt": str(active_question.get("prompt", "")), "category": str(active_question.get("category", "Kurioses Wissen")), "difficulty": str(active_question.get("difficulty", "mittel")), "round": round_index + 1, "chainHint": ""}}
		])
		for score_player_id in _active_human_ids():
			embedded_lan.send_to_player(score_player_id, "SCORE_STATUS", _score_summary_for_player(score_player_id))
	_set_phase_text("SCHÄTZ-TIEBREAK · TOP 2" if tiebreak_active else ("SCHÄTZRUNDE %d von %d · SCHNELLTIP" % [round_index + 1, max_rounds] if _is_estimation_round() else "RUNDE %d von %d · FALSCHE ANTWORT" % [round_index + 1, max_rounds]))
	_clear_body()
	body.add_child(_brand_mascot(Vector2(86, 86)))

	var question_card := _card(Color("162442"), Color(COLOR_CYAN, 0.62))
	body.add_child(question_card)
	var qbox := VBoxContainer.new()
	question_card.add_child(qbox)
	var question_badge := TextureRect.new()
	question_badge.texture = QUESTION_BADGE
	question_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	question_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	question_badge.custom_minimum_size = Vector2(54, 54)
	question_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	question_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qbox.add_child(question_badge)
	qbox.add_child(_label("DIE FRAGE", 13, COLOR_CYAN, true))
	qbox.add_child(_label(str(active_question.get("prompt", "")), 25, COLOR_INK, true))
	qbox.add_child(_label("%s · %s" % [str(active_question.get("category", "Kurioses Wissen")), str(active_question.get("difficulty", "mittel"))], 12, COLOR_PURPLE, true))
	qbox.add_child(_label("Zahl eingeben · schnellster plausibler Tipp gewinnt." if (_is_estimation_round() or tiebreak_active) else "Die Wahrheit bleibt bis zur Auflösung geheim.", 13, COLOR_MUTED, false))

	var input_card := _card()
	body.add_child(input_card)
	var input_box := VBoxContainer.new()
	input_box.add_theme_constant_override("separation", 8)
	input_card.add_child(input_box)
	var input_header := HBoxContainer.new()
	input_box.add_child(input_header)
	input_header.add_child(_label("DEINE SCHÄTZUNG" if (_is_estimation_round() or tiebreak_active) else "DEINE FALSCHANTWORT", 14, COLOR_ACCENT, true))
	timer_label = _label("%02d s" % int(ceil(countdown)), 20, COLOR_ACCENT, true)
	timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	input_header.add_child(timer_label)
	answer_input = LineEdit.new()
	answer_input.custom_minimum_size = Vector2(0, 82)
	answer_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_input.placeholder_text = "Deine Schätzung als Zahl …" if (_is_estimation_round() or tiebreak_active) else "Was würdest du behaupten? (maximal 75 Zeichen)"
	answer_input.max_length = 10 if (_is_estimation_round() or tiebreak_active) else 75
	answer_input.add_theme_font_override("font", FONT_REGULAR)
	answer_input.add_theme_font_size_override("font_size", 20)
	answer_input.add_theme_color_override("font_color", COLOR_INK)
	answer_input.add_theme_color_override("caret_color", COLOR_ACCENT)
	if _is_estimation_round() or tiebreak_active:
		var numeric_row := HBoxContainer.new()
		numeric_row.add_theme_constant_override("separation", 10)
		numeric_row.add_child(answer_input)
		var unit_label := _label(str(active_question.get("estimate_unit", "Zahl")), 20, COLOR_CYAN, true)
		numeric_row.add_child(unit_label)
		input_box.add_child(numeric_row)
	else:
		input_box.add_child(answer_input)
	timer_bar = ProgressBar.new()
	timer_bar.max_value = 45.0
	timer_bar.value = 45.0
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size.y = 10
	timer_bar.add_theme_stylebox_override("background", _style(Color("283451"), Color("283451"), 5, 0))
	timer_bar.add_theme_stylebox_override("fill", _style(COLOR_ACCENT, COLOR_ACCENT, 5, 0))
	input_box.add_child(timer_bar)
	feedback_label = _label("Schnell tippen – Nähe zum Richtwert gewinnt." if (_is_estimation_round() or tiebreak_active) else "75 Zeichen · lieber charmant daneben als langweilig richtig.", 13, COLOR_MUTED, false)
	input_box.add_child(feedback_label)
	round_progress_label = _label("", 13, COLOR_CYAN, true)
	input_box.add_child(round_progress_label)
	_update_round_progress("Antworten", submitted_lies)

	var actions: BoxContainer = VBoxContainer.new() if portrait_layout else HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8 if portrait_layout else 12)
	answer_submit_button = _button("ANTWORT VERSIEGELN", Color(COLOR_ACCENT, 0.24), Callable(self, "_submit_player_answer"))
	answer_submit_button.custom_minimum_size = Vector2(0, 72)
	answer_submit_button.disabled = true
	answer_input.text_changed.connect(func(value: String) -> void:
		if answer_submit_button != null and is_instance_valid(answer_submit_button):
			answer_submit_button.disabled = _clean_text(value).is_empty()
	)
	if portrait_layout:
		answer_submit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(answer_submit_button)
	action_bar.add_child(actions)
	_add_emoji_bar()
	_add_admin_button()
	call_deferred("_reveal_input_control")

func _add_admin_button() -> void:
	var gear := _button("⚙ Host-Menü", Color(COLOR_SURFACE_2, 0.82), Callable(self, "_toggle_admin_drawer"))
	gear.custom_minimum_size = Vector2(150, 48)
	gear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_bar.add_child(gear)

func _toggle_admin_drawer() -> void:
	if admin_drawer != null and is_instance_valid(admin_drawer):
		admin_drawer.queue_free()
		admin_drawer = null
		return
	admin_drawer = VBoxContainer.new()
	admin_drawer.alignment = BoxContainer.ALIGNMENT_CENTER
	admin_drawer.add_theme_constant_override("separation", 6)
	admin_drawer.add_child(_label("HOST-AKTIONEN", 12, COLOR_ACCENT, true))
	var skip := _button("RUNDE ÜBERSPRINGEN", Color(COLOR_RED, 0.18), Callable(self, "_show_scoreboard"))
	skip.custom_minimum_size.y = 48
	admin_drawer.add_child(skip)
	var stop := _button("SPIEL BEENDEN", Color(COLOR_SURFACE_2, 0.95), Callable(self, "_confirm_stop_host"))
	stop.custom_minimum_size.y = 48
	admin_drawer.add_child(stop)
	var connection := _button("VERBINDUNG PRÜFEN", Color(COLOR_CYAN, 0.14), Callable(self, "_show_connection_check"))
	connection.custom_minimum_size.y = 48
	admin_drawer.add_child(connection)
	var mission := _button("MISSION ANZEIGEN", Color(COLOR_PURPLE, 0.16), Callable(self, "_toggle_challenge_details"))
	mission.custom_minimum_size.y = 48
	mission.disabled = challenge_dock == null or not challenge_dock.visible
	admin_drawer.add_child(mission)
	var results := _button("ERGEBNISDETAILS", Color(COLOR_ACCENT, 0.14), Callable(self, "_toggle_reveal_details"))
	results.custom_minimum_size.y = 48
	results.disabled = reveal_details_panel == null or not is_instance_valid(reveal_details_panel)
	admin_drawer.add_child(results)
	admin_drawer.add_child(_label("Netzwerk: %s · %s" % [network_interface_name.to_upper(), local_ip], 12, COLOR_MUTED, false))
	action_bar.add_child(admin_drawer)

func _stop_host() -> void:
	if embedded_lan != null:
		embedded_lan.queue_free()
	_show_lobby()

func _confirm_stop_host() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Spiel beenden?"
	dialog.dialog_text = "Die aktuelle Runde und die Verbindung zu allen Spielern werden beendet."
	dialog.ok_button_text = "Beenden"
	dialog.cancel_button_text = "Weiter spielen"
	dialog.confirmed.connect(_stop_host)
	add_child(dialog)
	dialog.popup_centered(Vector2(420, 190))

func _confirm_leave_native_game() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Lobby verlassen?"
	dialog.dialog_text = "Du verlässt die aktuelle Verbindung und kehrst zum Startscreen zurück."
	dialog.ok_button_text = "Lobby verlassen"
	dialog.cancel_button_text = "Weiter dabei"
	dialog.confirmed.connect(_leave_native_game)
	add_child(dialog)
	dialog.popup_centered(Vector2(420, 190))

func _show_connection_check() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Verbindung prüfen"
	var status := "Host-Server: bereit" if embedded_lan != null and embedded_lan.started else "Host-Server: nicht aktiv"
	var discovery := "Raum auffindbar" if embedded_lan != null and embedded_lan.discovery_ready else "Raum-Discovery nicht verfügbar"
	dialog.dialog_text = "%s\n%s\nNetzwerk: %s\nAdresse: %s\n\nAlle Geräte müssen im selben lokalen WLAN sein." % [status, discovery, network_interface_name.to_upper(), local_ip]
	add_child(dialog)
	dialog.popup_centered(Vector2(460, 250))

func _reveal_input_control() -> void:
	if body_scroll == null or not is_instance_valid(body_scroll):
		return
	if answer_input != null and is_instance_valid(answer_input):
		answer_input.release_focus()
	_reset_body_scroll_top()

func _reset_body_scroll_top() -> void:
	if body_scroll == null or not is_instance_valid(body_scroll):
		return
	body_scroll.scroll_vertical = 0
	body_scroll.set_deferred("scroll_vertical", 0)

func _assign_round_roles() -> void:
	var roles := [
		{"title": "Faktenfuchs", "hint": "Vertraue deinem ersten Bauchgefühl – es ist heute besonders wach.", "icon": "🦊"},
		{"title": "Chaosmacher", "hint": "Je mehr Stimmen eine Lüge bekommt, desto größer dein Auftritt.", "icon": "⚡"},
		{"title": "Doppelbluff", "hint": "Deine Antwort darf verdächtig gut klingen.", "icon": "🎭"},
		{"title": "Stiller Zeuge", "hint": "Beobachte die Menschen hinter den Antworten.", "icon": "👁️"},
	]
	roles.shuffle()
	var secret_tasks: Array = current_directive.get("secretTasks", [])
	for i in range(players.size()):
		var assigned: Dictionary = roles[i % roles.size()]
		if not secret_tasks.is_empty():
			assigned["task"] = str(secret_tasks[i % secret_tasks.size()])
		players[i].role = str(assigned.title)
		players[i].role_hint = str(assigned.hint)
		players[i].role_task = str(assigned.get("task", ""))
		players[i].confidence = 50
		if i == 0:
			role_brief = assigned

func _prepare_bot_lies() -> void:
	var decoys: Array = active_question.get("fallbackDecoys", [])
	var used_answers: Dictionary = {}
	var bot_decoys: Array = []
	var is_estimate := active_question.has("estimate_value") or _is_estimation_round() or tiebreak_active
	var used_numeric_decoys: Dictionary = {}
	var true_value := float(active_question.get("estimate_value", 0))
	for decoy in decoys:
		var candidate := str(decoy).strip_edges()
		if candidate.is_empty():
			continue
		if is_estimate:
			var numeric_text := candidate.replace(",", ".")
			if not _is_numeric_estimate(numeric_text):
				continue
			var numeric_value := float(numeric_text)
			var numeric_key := str(numeric_value)
			if is_equal_approx(numeric_value, true_value) or used_numeric_decoys.has(numeric_key):
				continue
			candidate = str(int(numeric_value)) if is_equal_approx(numeric_value, round(numeric_value)) else str(numeric_value)
			bot_decoys.append(candidate)
			used_numeric_decoys[numeric_key] = true
		elif not bot_decoys.has(candidate):
			bot_decoys.append(candidate)
	var bot_count := 0
	for index in range(1, players.size()):
		if not bool(players[index].get("is_human", true)):
			bot_count += 1
	if is_estimate:
		var step := maxf(1.0, round(absf(true_value) * 0.1))
		var candidate_index := 1
		while bot_decoys.size() < 8:
			var numeric_value := true_value + step * float(candidate_index)
			var numeric_key := str(numeric_value)
			if not used_numeric_decoys.has(numeric_key):
				var candidate := str(int(numeric_value)) if is_equal_approx(numeric_value, round(numeric_value)) else str(numeric_value)
				bot_decoys.append(candidate)
				used_numeric_decoys[numeric_key] = true
			candidate_index += 1
			if candidate_index > 10000:
				break
	if bot_count < bot_decoys.size():
		_shuffle_with_rng(bot_decoys)
	var generated_answers: Array = [
		"Eine regionale Sonderregelung aus dieser Zeit",
		"Eine zeitlich begrenzte Ausnahme der zuständigen Behörden",
		"Ein praktischer Grund aus dem damaligen Alltag",
		"Eine politische Entscheidung mit ähnlichem Hintergrund",
		"Eine technische Lösung, die damals verbreitet war",
		"Eine lokale Tradition, die später verändert wurde",
		"Eine überlieferte Erklärung aus der ursprünglichen Quelle",
		"Eine sachliche Gegenposition zu dieser Deutung"
	]
	_shuffle_with_rng(generated_answers)
	var bot_answer_index := 0
	for i in range(1, players.size()):
		if bool(players[i].get("is_human", true)):
			continue
		var answer := ""
		if bot_answer_index < bot_decoys.size():
			answer = str(bot_decoys[bot_answer_index])
		elif is_estimate:
			answer = _estimate_guess(str(players[i].id))
		else:
			answer = str(generated_answers[bot_answer_index % generated_answers.size()])
		bot_answer_index += 1
		var normalized := answer.strip_edges().to_lower()
		if is_estimate:
			var numeric_answer := float(answer.replace(",", "."))
			var true_estimate := float(active_question.get("estimate_value", 0))
			while is_equal_approx(numeric_answer, true_estimate) or used_answers.has(str(numeric_answer)):
				numeric_answer += 1.0
			answer = str(int(numeric_answer)) if is_equal_approx(numeric_answer, round(numeric_answer)) else str(numeric_answer)
			normalized = str(numeric_answer)
		else:
			var generated_index := 0
			while used_answers.has(normalized) or normalized.is_empty():
				answer = str(generated_answers[generated_index % generated_answers.size()])
				generated_index += 1
				normalized = answer.strip_edges().to_lower()
		used_answers[normalized] = true
		players[i].lie = answer

func _clean_bot_answer(value: String) -> String:
	var answer := value.strip_edges()
	if answer.is_empty() or answer in ["-", "–", "—", "..."]:
		return ""
	var lower := answer.to_lower()
	var banned := ["onkel", "mutter", "vater", "hat mein", "keine ahnung", "weiß ich nicht", "weiss ich nicht", "keine idee", "selbstfahr", "toaster", "gedichte", "lotteriegewinn", "echte märchen", "königliche elefanten", "schuhplattler", "käfer-rennbahn", "regenschirm für pferde", "mittelalterliche wettervorhersage", "konzert nur für katzen", "gedichte aufsagte"]
	for term in banned:
		if lower.contains(term):
			return ""
	return answer

func _is_numeric_estimate(value: String) -> bool:
	var normalized := value.strip_edges().replace(",", ".")
	if normalized.begins_with("+"):
		normalized = normalized.substr(1)
	if not normalized.is_valid_float():
		return false
	var number := float(normalized)
	return is_finite(number) and number >= 0.0

func _estimate_truth_text(question: Dictionary) -> String:
	if question.has("estimate_value"):
		var raw: Variant = question.get("estimate_value", 0)
		var answer := str(int(raw)) if raw is float and is_equal_approx(float(raw), round(float(raw))) else str(raw).strip_edges()
		var unit := str(question.get("estimate_unit", "")).strip_edges()
		return "%s %s" % [answer, unit] if not unit.is_empty() else answer
	return str(question.get("truth", "")).strip_edges()

func _estimate_truth_value_text(question: Dictionary) -> String:
	if question.has("estimate_value"):
		var raw: Variant = question.get("estimate_value", 0)
		return str(int(raw)) if raw is float and is_equal_approx(float(raw), round(float(raw))) else str(raw).strip_edges()
	return str(question.get("truth", "")).strip_edges()

func _estimate_guess(player_id: String) -> String:
	var target := float(active_question.get("estimate_value", 100))
	var offset := rng.randf_range(-0.24, 0.24)
	if player_id == "host":
		offset = rng.randf_range(-0.18, 0.18)
	var guess := maxi(0, int(round(target * (1.0 + offset))))
	if guess % 2 != 0:
		guess += 1
	return str(guess)

func _question_for_round(index: int) -> Dictionary:
	if question_order.is_empty():
		_prepare_question_order()
	if question_order.is_empty():
		return {}
	return question_order[index % question_order.size()].duplicate(true)

func _prepare_question_order() -> void:
	var normal_pool: Array = []
	var estimate_pool: Array = []
	var available_categories: PackedStringArray = Monetization.available_topic_categories()
	for question in questions:
		if not (question is Dictionary):
			continue
		if question.has("estimate_value"):
			estimate_pool.append(question.duplicate(true))
		else:
			var question_category := str(question.get("category", ""))
			if (selected_category == ALL_AVAILABLE_CATEGORY and available_categories.has(question_category)) or (selected_category != ALL_AVAILABLE_CATEGORY and question_category == selected_category):
				normal_pool.append(question.duplicate(true))
	if normal_pool.is_empty():
		for question in questions:
			if question is Dictionary and not question.has("estimate_value") and available_categories.has(str(question.get("category", ""))):
				normal_pool.append(question.duplicate(true))
	if normal_pool.is_empty():
		push_warning("Keine freigeschalteten Themenfragen verfügbar.")
	estimation_questions_available = not estimate_pool.is_empty()
	question_order = _unseen_questions_first(normal_pool)
	estimation_question_order = _unseen_questions_first(estimate_pool)

func _unseen_questions_first(pool: Array) -> Array:
	var unseen: Array = []
	var seen: Array = []
	for question in pool:
		var question_id := str(question.get("id", "")).strip_edges()
		if question_id.is_empty() or not played_question_ids.has(question_id):
			unseen.append(question.duplicate(true))
		else:
			seen.append(question.duplicate(true))
	_shuffle_with_rng(unseen)
	_shuffle_with_rng(seen)
	unseen.append_array(seen)
	return unseen

func _shuffle_with_rng(items: Array) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary: Variant = items[index]
		items[index] = items[swap_index]
		items[swap_index] = temporary

func _has_estimation_questions() -> bool:
	return estimation_questions_available

func _is_estimation_round() -> bool:
	return estimation_questions_available and not tiebreak_active and ((round_index + 1) % 3 == 0)

func _estimation_question_for_round(index: int) -> Dictionary:
	if estimation_question_order.is_empty():
		_prepare_question_order()
	if estimation_question_order.is_empty():
		return _question_for_round(index)
	return estimation_question_order[index % estimation_question_order.size()].duplicate(true)

func _fill_fallback() -> void:
	if answer_input == null:
		return
	var decoys: Array = active_question.get("fallbackDecoys", [])
	if decoys.is_empty():
		answer_input.text = "Eine sehr überzeugende, aber komplett falsche Erklärung"
	else:
		answer_input.text = str(decoys[0])
	answer_input.grab_focus()

func _submit_player_answer(force_fallback: bool = false) -> void:
	if phase != Phase.INPUT:
		return
	if submitted_lies.has("host"):
		return
	if force_fallback:
		_prepare_bot_lies()
		for player_id in _eligible_input_ids():
			if player_id == "host" or submitted_lies.has(player_id):
				continue
			var remote_player := _find_player(player_id)
			var fallback_list: Array = active_question.get("fallbackDecoys", [])
			if bool(remote_player.get("is_human", false)):
				remote_player.lie = _estimate_guess(player_id) if (_is_estimation_round() or tiebreak_active) else (str(fallback_list[0]) if not fallback_list.is_empty() else "Eine sachliche Antwort aus einer zeitgenössischen Quelle")
			submitted_lies[player_id] = remote_player.lie
	var value := "" if answer_input == null else _clean_text(answer_input.text)
	if force_fallback and value.is_empty():
		var decoys: Array = active_question.get("fallbackDecoys", [])
		value = _estimate_guess("host") if (_is_estimation_round() or tiebreak_active) else (str(decoys[0]) if not decoys.is_empty() else "Eine zufällige Sensation aus dem Jahr 1842")
	if value.is_empty():
		feedback_label.text = "Bitte schreibe zuerst eine Antwort."
		return
	if (_is_estimation_round() or tiebreak_active) and not _is_numeric_estimate(value):
		feedback_label.text = "Bitte gib eine nichtnegative Zahl ein – zum Beispiel 150."
		return
	if value.length() > 75:
		feedback_label.text = "Deine Antwort ist zu lang. Kürze sie auf 75 Zeichen."
		return
	players[0].lie = value
	submitted_lies["host"] = value
	if answer_submit_button != null and is_instance_valid(answer_submit_button):
		answer_submit_button.disabled = true
		answer_submit_button.text = "ANTWORT GESENDET ✓"
	_update_round_progress("Antworten", submitted_lies)
	aaa_audio.play_cue("seal")
	aaa_audio.haptic_pattern([20, 20])
	if submitted_lies.size() >= _eligible_input_ids().size():
		host_selected_option = ""
		_show_voting()
	else:
		Monetization.show_waiting_ad()
		if answer_input != null:
			answer_input.editable = false
		if feedback_label != null:
			feedback_label.text = "Antwort versiegelt. Warte auf die anderen Bluff-Poeten …"
			feedback_label.add_theme_color_override("font_color", COLOR_GREEN)

func _show_voting() -> void:
	Monetization.hide_ads()
	_set_game_orientation(true)
	phase = Phase.VOTING
	countdown = 30.0
	_timer_refresh = -1
	submitted_votes.clear()
	votes.clear()
	_set_phase_text(("SCHÄTZRUNDE %d von %d · ZAHL AUSWÄHLEN" if (_is_estimation_round() or tiebreak_active) else "RUNDE %d von %d · ABSTIMMUNG") % [round_index + 1, max_rounds])
	_clear_body()
	body.add_child(_brand_mascot(Vector2(78, 78)))
	var title := _label("Welche Aussage stimmt wirklich?", 31, COLOR_INK, true)
	body.add_child(title)
	var question_card := _card(Color("162442"), Color(COLOR_CYAN, 0.62))
	body.add_child(question_card)
	var question_box := VBoxContainer.new()
	question_box.add_theme_constant_override("separation", 5)
	question_card.add_child(question_box)
	question_box.add_child(_label("DIE FRAGE", 13, COLOR_CYAN, true))
	question_box.add_child(_label(str(active_question.get("prompt", "Frage wird geladen …")), 22, COLOR_INK, true))
	body.add_child(_label("Deine eigene Falschantwort ist ausgeblendet. Jetzt zählt dein Bauchgefühl.", 15, COLOR_MUTED, false))
	var confidence := _card(Color("151d3c"), Color(COLOR_PURPLE, 0.48))
	body.add_child(confidence)
	confidence.visible = confidence_system_enabled
	var confidence_box := VBoxContainer.new()
	confidence.add_child(confidence_box)
	var confidence_header := HBoxContainer.new()
	confidence_box.add_child(confidence_header)
	confidence_header.add_child(_label("WIE SICHER BIST DU?", 13, COLOR_CYAN, true))
	confidence_value_label = _label("50%", 16, COLOR_ACCENT, true)
	confidence_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confidence_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	confidence_header.add_child(confidence_value_label)
	confidence_slider = HSlider.new()
	confidence_slider.min_value = 1
	confidence_slider.max_value = 100
	confidence_slider.step = 1
	confidence_slider.value = 50
	confidence_slider.custom_minimum_size.y = 34
	confidence_slider.name = "ConfidenceSlider"
	confidence_slider.tooltip_text = "Vertrauen: 0 Prozent vorsichtig, 100 Prozent mutig"
	confidence_slider.focus_mode = Control.FOCUS_ALL
	confidence_slider.value_changed.connect(_on_confidence_changed)
	confidence_box.add_child(confidence_slider)
	confidence_box.add_child(_label("Vorsichtig 0 %   ·   Standard 50 %   ·   Mutig 100 %", 12, COLOR_MUTED, false))
	confidence_preview_label = _label("", 12, COLOR_PURPLE, true)
	confidence_box.add_child(confidence_preview_label)
	_update_confidence_preview()
	round_progress_label = null
	# Die Einheit bleibt nur in der Frage-/Auflösungsinformation sichtbar.
	# In der Abstimmung darf sie nicht ausschließlich die Wahrheit markieren.
	current_options = [{"id": "truth", "text": _estimate_truth_value_text(active_question), "kind": "truth", "owner": ""}]
	for i in range(players.size()):
		if str(players[i].id) == "host" or not str(players[i].lie).is_empty():
			current_options.append({"id": "lie:" + str(players[i].id), "text": str(players[i].lie), "kind": "lie", "owner": str(players[i].name), "ownerId": str(players[i].id)})
	current_options.shuffle()
	var options_box := VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 10)
	body.add_child(options_box)
	for index in range(current_options.size()):
		var option: Dictionary = current_options[index]
		if str(option.get("ownerId", "")) == "host":
			continue
		var visible_index := options_box.get_child_count() + 1
		var label_text := "%d   %s" % [visible_index, str(option.text)]
		var button := _button(label_text, Color(COLOR_ACCENT, 0.25) if str(option.id) == host_selected_option else Color(COLOR_SURFACE_2, 0.95), Callable(self, "_select_host_vote"), [str(option.id)])
		button.custom_minimum_size.y = 74
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		options_box.add_child(button)
	host_vote_selection_label = _label("Wähle eine Karte. Danach drücke WEITER.", 13, COLOR_PURPLE, false)
	body.add_child(host_vote_selection_label)
	host_vote_continue_button = _button("TIPP ABGEBEN · WEITER", Color(COLOR_ACCENT, 0.24), Callable(self, "_confirm_host_vote"))
	host_vote_continue_button.custom_minimum_size.y = 70
	host_vote_continue_button.disabled = true
	action_bar.add_child(host_vote_continue_button)
	if embedded_lan != null:
		embedded_lan.publish([
			{"type": "SHOW_DIRECTIVE", "payload": current_directive},
			{"type": "PHASE_CHANGE", "payload": {"newPhase": "VOTING", "timeLimitSec": 30, "round": round_index + 1, "maxRounds": max_rounds}}
			])
		for player_id in _active_human_ids():
			var filtered: Array = []
			for option in current_options:
				if str(option.get("ownerId", "")) != player_id:
					filtered.append(option)
				var client_score_status := _score_summary_for_player(player_id)
				var vote_payload := {"options": filtered, "round": round_index + 1, "maxRounds": max_rounds, "questionId": str(active_question.get("id", "")), "question": str(active_question.get("prompt", "")), "confidenceEnabled": confidence_system_enabled}
				vote_payload.merge(client_score_status, true)
				embedded_lan.send_to_player(player_id, "VOTE_OPTIONS_LIST", vote_payload)
	_add_admin_button()
	_add_emoji_bar()

func _select_host_vote(option_id: String) -> void:
	if phase != Phase.VOTING:
		return
	host_selected_option = option_id
	if host_vote_continue_button != null and is_instance_valid(host_vote_continue_button):
		host_vote_continue_button.disabled = false
	if host_vote_selection_label != null:
		host_vote_selection_label.text = "Ausgewählt. Drücke WEITER, um den Tipp abzugeben."

func _confirm_host_vote(force_timeout: bool = false) -> void:
	if host_selected_option.is_empty() and not force_timeout:
		if host_vote_selection_label != null:
			host_vote_selection_label.text = "Wähle zuerst eine Antwort. Ohne Tipp gibt es bei Zeitablauf keine Punkte."
		return
	_cast_vote(host_selected_option, force_timeout)

func _cast_vote(option_id: String, force_timeout: bool = false) -> void:
	if phase != Phase.VOTING:
		return
	votes["host"] = option_id
	submitted_votes["host"] = option_id
	if host_vote_continue_button != null and is_instance_valid(host_vote_continue_button):
		host_vote_continue_button.disabled = true
		host_vote_continue_button.text = "TIPP GESENDET ✓"
	_update_round_progress("Tipps", submitted_votes)
	players[0].confidence = clampi(int(confidence_slider.value if confidence_slider != null else 50.0), 0, 100)
	if force_timeout:
		for player_id in _active_human_ids():
			if not submitted_votes.has(player_id):
				submitted_votes[player_id] = ""
				votes[player_id] = ""
	for i in range(1, players.size()):
		if bool(players[i].get("is_human", false)):
			continue
		var choices: Array = []
		for option in current_options:
			if str(option.id) != "lie:" + str(players[i].id):
				choices.append(str(option.id))
			if not choices.is_empty():
				votes[str(players[i].id)] = choices[rng.randi_range(0, choices.size() - 1)]
				players[i].confidence = rng.randi_range(1, 100)
	if submitted_votes.size() >= _active_human_ids().size():
		_show_reveal()

func _on_confidence_changed(value: float) -> void:
	if confidence_value_label != null:
		confidence_value_label.text = "%d%%" % int(value)
	_update_confidence_preview()

func _update_confidence_preview() -> void:
	if confidence_preview_label == null or not is_instance_valid(confidence_preview_label):
		return
	var confidence := int(confidence_slider.value) if confidence_slider != null else 50
	if _is_estimation_round() or tiebreak_active:
		var estimate_gain := int(round(900.0 * GAME_RULES.estimate_confidence_factor(confidence)))
		var estimate_loss := GAME_RULES.estimate_confidence_penalty(250, confidence, 1.0)
		confidence_preview_label.text = "%d%% · Nähe bleibt entscheidend\nSehr nah: +%d · Weit daneben: −%d Punkte" % [confidence, estimate_gain, estimate_loss]
		return
	var multiplier := int(current_directive.get("multiplier", 2 if round_index == 2 else 1))
	var base := 500 + int(current_directive.get("truthBonus", 0))
	var gain := GAME_RULES.confidence_correct_points(base, confidence) * multiplier
	var penalty := GAME_RULES.confidence_wrong_penalty(250, confidence) * multiplier
	var risk_label := "Sicherer Tipp" if confidence <= 50 else "Hohes Risiko"
	var loss_text := "0" if penalty == 0 else "−%d" % penalty
	confidence_preview_label.text = "%d%% · %s\nRichtig: +%d Punkte · Falsch: %s Punkte" % [confidence, risk_label, gain, loss_text]

func _contains_number(value: String) -> bool:
	for character in value:
		if character >= "0" and character <= "9":
			return true
	return false

func _selected_option_text(option_id: String) -> String:
	if option_id.is_empty():
		return "Keine Antwort"
	for option in current_options:
		if str(option.get("id", "")) == option_id:
			return str(option.get("text", ""))
	return "Antwort nicht mehr verfügbar"

func _calculate_estimation_scores() -> void:
	var target := float(active_question.get("estimate_value", 100))
	target_counts.clear()
	for target_id in votes.values():
		target_counts[str(target_id)] = int(target_counts.get(str(target_id), 0)) + 1
	var ranking: Array = []
	for player in players:
		if tiebreak_active and not tiebreak_players.has(str(player.id)):
			continue
		var raw := str(player.get("lie", "0")).replace(",", ".")
		var guess := float(raw) if raw.is_valid_float() else target * 2.0
		ranking.append({"player": player, "distance": absf(guess - target), "guess": guess})
	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
	if ranking.is_empty():
		return
	var closest_distance := float(ranking[0].distance)
	var fooled_counts: Dictionary = {}
	for voter_id in votes.keys():
		var selected_id := str(votes.get(voter_id, ""))
		if not selected_id.begins_with("lie:"):
			continue
		var owner_id := selected_id.trim_prefix("lie:")
		fooled_counts[owner_id] = int(fooled_counts.get(owner_id, 0)) + 1
	for item in ranking:
		var reset_player: Dictionary = item.player
		reset_player.delta = 0
		reset_player.fooled = 0
		reset_player.confidence_award = ""
	for item in ranking:
		var player: Dictionary = item.player
		var is_closest := is_equal_approx(float(item.distance), closest_distance)
		var confidence := clampi(int(player.get("confidence", 50)), 0, 100) if confidence_system_enabled else 50
		var distance_ratio := clampf(float(item.distance) / maxf(target, 1.0), 0.0, 1.0)
		var distance_points := int(round(900.0 * GAME_RULES.estimate_confidence_factor(confidence))) if is_closest else 0
		var estimate_penalty := GAME_RULES.estimate_confidence_penalty(250, confidence, distance_ratio) if not is_closest else 0
		var truth_pick_points := int(round(500.0 * GAME_RULES.estimate_confidence_factor(confidence))) if str(votes.get(str(player.id), "")) == "truth" else 0
		if truth_pick_points > 0:
			player.correct = int(player.get("correct", 0)) + 1
		var fooled_count := int(fooled_counts.get(str(player.id), 0))
		var fooled_points := fooled_count * 250
		player.fooled = fooled_count
		player.deceived_total = int(player.get("deceived_total", 0)) + fooled_count
		player.distance_points = distance_points
		player.truth_pick_points = truth_pick_points
		player.fooled_points = fooled_points
		player.confidence_points = distance_points + truth_pick_points
		player.confidence_penalty = estimate_penalty
		player.delta = distance_points + truth_pick_points + fooled_points - estimate_penalty
		if player.delta < 0:
			player.delta = -mini(int(player.get("score", 0)), abs(player.delta))
		player.score = int(player.score) + int(player.delta)
		if is_closest:
			player.confidence_award = "SCHÄTZKÖNIG"
	if score_hud != null:
		score_hud.visible = true
		_update_score_hud(_score_summary_for_player("host"))
	if embedded_lan != null:
		var reveal_entries: Array = [{"owner": "DIE RICHTIGE ZAHL", "ownerId": "", "text": _estimate_truth_text(active_question), "votes": int(target_counts.get("truth", 0)), "kind": "truth"}]
		var player_results: Array = []
		for ranking_entry in ranking:
			var ranked_player: Dictionary = ranking_entry.player
			reveal_entries.append({"owner": str(ranked_player.name), "ownerId": str(ranked_player.id), "avatarIndex": int(ranked_player.get("avatarIndex", 0)), "text": str(ranked_player.lie), "votes": int(target_counts.get("lie:" + str(ranked_player.id), 0)), "kind": "estimate", "award": str(ranked_player.confidence_award)})
			player_results.append({"id": str(ranked_player.id), "name": str(ranked_player.name), "avatarIndex": int(ranked_player.get("avatarIndex", 0)), "delta": int(ranked_player.delta), "score": int(ranked_player.score), "fooled": int(ranked_player.fooled), "fooledPoints": int(ranked_player.fooled) * 250, "fooledPlayers": _fooled_player_breakdown(str(ranked_player.id), 250), "selectedTruth": str(votes.get(str(ranked_player.id), "")) == "truth", "distancePoints": int(ranked_player.get("distance_points", 0)), "truthPickPoints": int(ranked_player.get("truth_pick_points", 0)), "confidence": int(ranked_player.get("confidence", 50)), "confidencePoints": int(ranked_player.get("confidence_points", 0)), "confidencePenalty": int(ranked_player.get("confidence_penalty", 0)), "correct": int(ranked_player.correct), "award": str(ranked_player.confidence_award), "selectedText": _selected_option_text(str(votes.get(str(ranked_player.id), "")))})
		var estimate_reveal_payload := {"prompt": str(active_question.get("prompt", "")), "truth": _estimate_truth_text(active_question), "explanation": str(active_question.get("reveal", active_question.get("explanation", ""))), "entries": reveal_entries, "playerResults": player_results, "round": round_index + 1, "bestLie": "", "directive": {"revealCue": "Wer lag am nächsten?"}}
		network_reveal_snapshot = estimate_reveal_payload.duplicate(true)
		embedded_lan.publish([
			{"type": "SHOW_DIRECTIVE", "payload": {"title": "SCHÄTZRUNDE", "revealCue": "Wer lag am nächsten?"}},
			{"type": "PHASE_CHANGE", "payload": {"newPhase": "REVEAL", "timeLimitSec": 0, "round": round_index + 1}},
			{"type": "ROUND_REVEAL_DATA", "payload": estimate_reveal_payload}
		])

func _calculate_scores() -> void:
	if _is_estimation_round() or tiebreak_active:
		_calculate_estimation_scores()
		return
	target_counts.clear()
	for target in votes.values():
		target_counts[str(target)] = int(target_counts.get(str(target), 0)) + 1
	var multiplier := int(current_directive.get("multiplier", 2 if round_index == 2 else 1))
	var truth_bonus := int(current_directive.get("truthBonus", 0))
	for player in players:
		var id := str(player.id)
		var delta := 0
		player.confidence_award = ""
		var confidence := clampi(int(player.get("confidence", 50)), 0, 100)
		var selected_truth := str(votes.get(id, "")) == "truth"
		if selected_truth:
			player.correct = int(player.get("correct", 0)) + 1
		if confidence_system_enabled:
			if selected_truth:
				delta += GAME_RULES.confidence_correct_points(500 + truth_bonus, confidence) * multiplier
				if confidence >= 80:
					player.confidence_award = "NERVEN AUS STAHL"
			else:
				var penalty := GAME_RULES.confidence_wrong_penalty(250, confidence) * multiplier
				delta -= mini(int(player.get("score", 0)), penalty)
		elif selected_truth:
			delta += (500 + truth_bonus) * multiplier
		var lie_id := "lie:" + id
		var fooled := int(target_counts.get(lie_id, 0))
		delta += fooled * 250 * multiplier
		if str(player.role) == "Chaosmacher" and fooled > 0:
			delta += 100 * multiplier
			player.confidence_award = "CHAOS-ENERGIE"
		player.fooled = fooled
		player.deceived_total = int(player.get("deceived_total", 0)) + fooled
		player.delta = delta
		player.score = int(player.score) + delta
	if score_hud != null:
		score_hud.visible = true
		_update_score_hud(_score_summary_for_player("host"))
	var best_votes := 0
	previous_best_lie = ""
	for player in players:
		var lie_votes := int(target_counts.get("lie:" + str(player.id), 0))
		if lie_votes > best_votes:
			best_votes = lie_votes
			previous_best_lie = str(player.lie)
	if embedded_lan != null:
		var reveal_entries: Array = [{"owner": "DIE WAHRHEIT", "ownerId": "", "text": _estimate_truth_text(active_question), "votes": int(target_counts.get("truth", 0)), "kind": "truth"}]
		var player_results: Array = []
		for reveal_player in players:
				reveal_entries.append({"owner": str(reveal_player.name), "ownerId": str(reveal_player.id), "avatarIndex": int(reveal_player.get("avatarIndex", 0)), "text": str(reveal_player.lie), "votes": int(target_counts.get("lie:" + str(reveal_player.id), 0)), "kind": "lie", "award": str(reveal_player.confidence_award)})
				player_results.append({"id": str(reveal_player.id), "name": str(reveal_player.name), "avatarIndex": int(reveal_player.get("avatarIndex", 0)), "delta": int(reveal_player.delta), "score": int(reveal_player.score), "fooled": int(reveal_player.fooled), "fooledPoints": int(reveal_player.fooled) * 250 * multiplier, "fooledPlayers": _fooled_player_breakdown(str(reveal_player.id), 250 * multiplier), "selectedTruth": str(votes.get(str(reveal_player.id), "")) == "truth", "confidence": int(reveal_player.get("confidence", 50)), "confidencePoints": GAME_RULES.confidence_correct_points(500 + truth_bonus, int(reveal_player.get("confidence", 50))) * multiplier if confidence_system_enabled and str(votes.get(str(reveal_player.id), "")) == "truth" else 0, "confidencePenalty": GAME_RULES.confidence_wrong_penalty(250, int(reveal_player.get("confidence", 50))) * multiplier if confidence_system_enabled and str(votes.get(str(reveal_player.id), "")) != "truth" else 0, "correct": int(reveal_player.correct), "award": str(reveal_player.confidence_award), "selectedText": _selected_option_text(str(votes.get(str(reveal_player.id), "")))})
		var standard_reveal_payload := {"prompt": str(active_question.get("prompt", "")), "truth": _estimate_truth_text(active_question), "explanation": str(active_question.get("reveal", active_question.get("explanation", ""))), "entries": reveal_entries, "playerResults": player_results, "round": round_index + 1, "bestLie": previous_best_lie, "directive": current_directive}
		network_reveal_snapshot = standard_reveal_payload.duplicate(true)
		embedded_lan.publish([
			{"type": "SHOW_DIRECTIVE", "payload": current_directive},
			{"type": "PHASE_CHANGE", "payload": {"newPhase": "REVEAL", "timeLimitSec": 0, "round": round_index + 1}},
			{"type": "ROUND_REVEAL_DATA", "payload": standard_reveal_payload}
		])

func _show_reveal() -> void:
	_calculate_scores()
	aaa_audio.play_cue("whoosh")
	aaa_audio.haptic(28)
	if stage_fx != null:
		stage_fx.emit_burst(Vector2(size.x * 0.5, size.y * 0.34), COLOR_GREEN, 26)
	if int(players[0].fooled) > 0:
		aaa_audio.haptic_pattern([65, 35, 65])
	phase = Phase.REVEAL
	countdown = 20.0
	_timer_refresh = -1
	_set_phase_text("SCHÄTZRUNDEN-REVEAL" if (_is_estimation_round() or tiebreak_active) else "RUNDE %d von %d · AUFLÖSUNG" % [round_index + 1, max_rounds])
	_clear_body()
	var reveal_mascot := _brand_mascot(Vector2(88, 88))
	body.add_child(reveal_mascot)
	_celebrate_mascot(reveal_mascot, false)
	var title := _label("Die Wahrheit kommt ans Licht", 31, COLOR_INK, true)
	body.add_child(title)
	var showline := "NERVEN AUS STAHL!" if str(players[0].confidence_award) == "NERVEN AUS STAHL" else ("DEIN BLUFF HAT FUNKTIONIERT." if int(players[0].fooled) > 0 else "DIE SHOW HAT GESPROCHEN.")
	body.add_child(_label(showline, 15, COLOR_ACCENT if showline != "DIE SHOW HAT GESPROCHEN." else COLOR_PURPLE, true))
	body.add_child(_label("Wer lag am nächsten?" if (_is_estimation_round() or tiebreak_active) else str(current_directive.get("revealCue", "Die Wahrheit kommt ans Licht.")), 15, COLOR_CYAN, true))
	var question_card := _card(Color("17233b"), Color(COLOR_CYAN, 0.45))
	body.add_child(question_card)
	var question_box := VBoxContainer.new()
	question_box.add_theme_constant_override("separation", 5)
	question_card.add_child(question_box)
	question_box.add_child(_label("DIE FRAGE", 13, COLOR_CYAN, true))
	question_box.add_child(_label(str(active_question.get("prompt", "")), 24, COLOR_INK, true))
	var truth_card := _card(Color("123b34"), Color(COLOR_GREEN, 0.82))
	_apply_foil(truth_card)
	body.add_child(truth_card)
	var truth_box := VBoxContainer.new()
	truth_box.add_theme_constant_override("separation", 5)
	truth_card.add_child(truth_box)
	truth_box.add_child(_label("DIE KORREKTE ANTWORT", 13, COLOR_GREEN, true))
	truth_box.add_child(_label(_estimate_truth_text(active_question), 23, COLOR_INK, true))
	truth_box.add_child(_label("ERLÄUTERUNG", 13, COLOR_CYAN, true))
	var host_explanation := str(active_question.get("reveal", active_question.get("explanation", ""))).strip_edges()
	if host_explanation.is_empty():
		host_explanation = "Für diese Frage ist keine zusätzliche Erläuterung hinterlegt."
	truth_box.add_child(_label(host_explanation, 14, COLOR_MUTED, false))
	var personal_card := _card(Color("202946"), Color(COLOR_CYAN, 0.45))
	_apply_foil(personal_card)
	body.add_child(personal_card)
	var personal_box := VBoxContainer.new()
	personal_box.add_theme_constant_override("separation", 8)
	personal_card.add_child(personal_box)
	personal_box.add_child(_label("DEIN PERSÖNLICHES ERGEBNIS", 13, COLOR_CYAN, true))
	var host_vote := str(votes.get("host", ""))
	personal_box.add_child(_label("Du hast keinen Tipp abgegeben." if host_vote.is_empty() else ("Du hast die korrekte Antwort gewählt." if host_vote == "truth" else "Du hast die korrekte Antwort nicht gewählt."), 19, COLOR_INK, true))
	var host_points_each := 250 if (_is_estimation_round() or tiebreak_active) else 250 * int(current_directive.get("multiplier", 2 if round_index == 2 else 1))
	var host_fooled := _fooled_player_breakdown("host", host_points_each)
	if host_fooled.is_empty():
		personal_box.add_child(_label("Keiner ist auf deinen Bluff hereingefallen · 0 Punkte", 15, COLOR_MUTED, false))
	else:
		personal_box.add_child(_label("Auf deinen Bluff hereingefallen:", 14, COLOR_CYAN, true))
		for fooled_player in host_fooled:
			personal_box.add_child(_label("%s · +%d Punkte" % [str(fooled_player.get("name", "Spieler")), int(fooled_player.get("points", 0))], 15, COLOR_INK, false))
			if _is_estimation_round() or tiebreak_active:
				personal_box.add_child(_label("Schätznähe: %+d · Wahrheit gewählt: %+d · Bluff: %+d · Sicherheit: %+d / −%d" % [int(players[0].get("distance_points", 0)), int(players[0].get("truth_pick_points", 0)), int(players[0].get("fooled_points", 0)), int(players[0].get("confidence_points", 0)), int(players[0].get("confidence_penalty", 0))], 13, COLOR_CYAN, false))
			else:
				personal_box.add_child(_label("Sicherheit: %d%% · richtig %+d · Risiko −%d" % [int(players[0].get("confidence", 50)), GAME_RULES.confidence_correct_points(500 + int(current_directive.get("truthBonus", 0)), int(players[0].get("confidence", 50))) * int(current_directive.get("multiplier", 2 if round_index == 2 else 1)) if confidence_system_enabled and host_vote == "truth" else 0, GAME_RULES.confidence_wrong_penalty(250, int(players[0].get("confidence", 50))) * int(current_directive.get("multiplier", 2 if round_index == 2 else 1)) if confidence_system_enabled and host_vote != "truth" else 0], 13, COLOR_CYAN, false))
		personal_box.add_child(_label("Gesamt für diese Runde: %+d Punkte · Gesamtstand: %d Punkte" % [int(players[0].delta), int(players[0].score)], 17, COLOR_ACCENT, true))
		var personal_delta := _label("+0 PUNKTE IN DIESER RUNDE", 25, COLOR_GREEN if int(players[0].delta) >= 0 else COLOR_RED, true)
		personal_delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		personal_box.add_child(personal_delta)
		_animate_integer_label(personal_delta, int(players[0].delta), "%+d PUNKTE IN DIESER RUNDE")
		_update_score_hud(_score_summary_for_player("host"))
	personal_box.add_child(_label("Die vollständige Auflösung läuft jetzt auf allen Handys.", 14, COLOR_MUTED, false))
	reveal_details_open = false
	reveal_details_toggle = _button("ALLE DETAILS ANZEIGEN", Color(COLOR_SURFACE_2, 0.82), Callable(self, "_toggle_reveal_details"))
	reveal_details_toggle.custom_minimum_size.y = 52
	body.add_child(reveal_details_toggle)
	reveal_details_panel = VBoxContainer.new()
	reveal_details_panel.visible = false
	reveal_details_panel.add_theme_constant_override("separation", 7)
	body.add_child(reveal_details_panel)
	reveal_details_panel.add_child(_label("DIE RUNDE IM RÜCKBLICK", 15, COLOR_ACCENT, true))
	var reveal_list := VBoxContainer.new()
	reveal_list.add_theme_constant_override("separation", 7)
	reveal_details_panel.add_child(reveal_list)
	for player in players:
		if tiebreak_active and not tiebreak_players.has(str(player.id)):
			continue
		var answer_card := _card(Color("151d3c"), Color(COLOR_PURPLE, 0.42))
		answer_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reveal_list.add_child(answer_card)
		var answer_header: BoxContainer = VBoxContainer.new() if portrait_layout else HBoxContainer.new()
		answer_header.add_theme_constant_override("separation", 8)
		answer_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_card.add_child(answer_header)
		var player_name_label := _label(str(player.name), 16 if portrait_layout else 15, COLOR_ACCENT, true)
		if portrait_layout:
			var answer_identity := HBoxContainer.new()
			answer_identity.add_theme_constant_override("separation", 8)
			answer_identity.add_child(_player_avatar_image(player, 54))
			player_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			answer_identity.add_child(player_name_label)
			answer_header.add_child(answer_identity)
		else:
			answer_header.add_child(_player_avatar_image(player, 62))
			player_name_label.custom_minimum_size.x = 110
			answer_header.add_child(player_name_label)
		var answer_label := _label("GESCHRIEBEN: „%s“" % str(player.lie), 16, COLOR_INK, false)
		answer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		answer_header.add_child(answer_label)
		var selected := _selected_option_text(str(votes.get(str(player.id), "")))
		var selected_label := _label("GEWÄHLT: „%s“" % selected, 13, COLOR_CYAN, false)
		if not portrait_layout:
			selected_label.custom_minimum_size.x = 150
		answer_header.add_child(selected_label)
	reveal_details_panel.add_child(_label("TABELLE NACH DIESER RUNDE", 15, COLOR_PURPLE, true))
	var round_table := VBoxContainer.new()
	round_table.add_theme_constant_override("separation", 6)
	reveal_details_panel.add_child(round_table)
	var round_players: Array = players.duplicate()
	round_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	for index in range(round_players.size()):
		var row := _card(Color("151d3c") if index > 0 else Color("30284b"), Color(COLOR_ACCENT, 0.34))
		var row_box := HBoxContainer.new()
		row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(row_box)
		row_box.add_child(_label("%d" % (index + 1), 18, COLOR_ACCENT, true))
		row_box.add_child(_player_avatar_image(round_players[index], 58))
		var name_label := _label(str(round_players[index].name), 16, COLOR_INK, true)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.add_child(name_label)
		row_box.add_child(_label("%+d · %d Pkt" % [int(round_players[index].delta), int(round_players[index].score)], 15, COLOR_GREEN, true))
		round_table.add_child(row)
	if app_mode == "HOST":
		embedded_lan.begin_ready_gate("ROUND")
		var host_ready_card := _card(Color("163b3b"), Color(COLOR_GREEN, 0.72))
		body.add_child(host_ready_card)
		var host_ready_box := VBoxContainer.new()
		host_ready_box.add_theme_constant_override("separation", 7)
		host_ready_card.add_child(host_ready_box)
		var initial_ready := 0
		var initial_total := 0
		if embedded_lan != null and embedded_lan.gate_active:
			initial_total = embedded_lan.gate_ready.size()
			for ready_value in embedded_lan.gate_ready.values():
				if bool(ready_value):
					initial_ready += 1
		host_ready_box.add_child(_label("NÄCHSTE SEITE · %d/%d BEREIT" % [initial_ready, initial_total], 14, COLOR_CYAN, true))
		host_ready_box.add_child(_label("Der Host und alle Spieler sehen denselben Ready-Stand.", 14, COLOR_INK, false))
		var next_button := _button("WEITER · HOST BEREIT", Color(COLOR_GREEN, 0.24), Callable(self, "_host_ready"))
		next_button.custom_minimum_size.y = 64
		action_bar.add_child(next_button)
	_add_emoji_bar()
	_add_admin_button()

func _host_advance_after_reveal() -> void:
	if phase != Phase.REVEAL:
		return
	if tiebreak_active:
		_show_podium()
	elif round_index >= max_rounds - 1:
		_show_scoreboard()
	else:
		_next_round()

func _show_scoreboard() -> void:
	phase = Phase.SCOREBOARD
	countdown = 10.0
	_timer_refresh = -1
	var final_round := round_index >= max_rounds - 1
	var final_tie := final_round and _has_estimation_questions() and _final_has_tie()
	_set_phase_text("FINALE · TIEBREAK" if final_tie else ("FINALE" if final_round else "ZWISCHENSTAND"))
	_clear_body()
	body.add_child(_brand_mascot(Vector2(82, 82)))
	var title := _label("SCHÄTZ-TIEBREAK für die Top 2" if final_tie else ("Die Lügenrunde ist entschieden" if final_round else "Wer führt?"), 31, COLOR_INK, true)
	body.add_child(title)
	var scoreboard_note := ("%d Runden · Jede 3. Runde ist eine Schätzfrage." % max_rounds) if _has_estimation_questions() else ("%d Runden · Schätzrunden pausieren bis passende Zahlenfragen vorliegen." % max_rounds)
	if final_tie:
		scoreboard_note = "Noch kein eindeutiger Sieger – die zwei Erstplatzierten entscheiden es mit einer letzten Schätzung."
	body.add_child(_label(scoreboard_note, 16, COLOR_MUTED, false))
	var sorted_players: Array = players.duplicate()
	sorted_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 9)
	body.add_child(list)
	list.add_child(_label("RANG · SPIELER · GESAMTSTAND · RUNDE", 12, COLOR_CYAN, true))
	for index in range(sorted_players.size()):
		var player: Dictionary = sorted_players[index]
		var card := _card(Color("1d2741") if index == 0 else COLOR_SURFACE, Color(COLOR_ACCENT, 0.6) if index == 0 else Color("2b395b"))
		card.custom_minimum_size.y = 78 if portrait_layout else 52
		list.add_child(card)
		var row: BoxContainer = VBoxContainer.new() if portrait_layout else HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(row)
		var scoreboard_name := str(player.name)
		if not str(player.confidence_award).is_empty():
			scoreboard_name += " · " + str(player.confidence_award)
		if portrait_layout:
			var identity_row := HBoxContainer.new()
			identity_row.add_theme_constant_override("separation", 8)
			identity_row.add_child(_label("%d" % (index + 1), 24, COLOR_ACCENT if index == 0 else COLOR_MUTED, true))
			identity_row.add_child(_player_avatar_image(player, 48))
			var name_label := _label(scoreboard_name, 17, COLOR_INK, true)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			identity_row.add_child(name_label)
			row.add_child(identity_row)
			row.add_child(_label("GESAMT %d Pkt · RUNDE %+d" % [int(player.score), int(player.delta)], 15, COLOR_GREEN if int(player.delta) > 0 else COLOR_MUTED, true))
		else:
			row.add_child(_label("%d" % (index + 1), 24, COLOR_ACCENT if index == 0 else COLOR_MUTED, true))
			row.add_child(_player_avatar_image(player, 58))
			var name_label := _label(scoreboard_name, 19, COLOR_INK, true)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_label)
			row.add_child(_label("%+d" % int(player.delta), 15, COLOR_GREEN if int(player.delta) > 0 else COLOR_MUTED, true))
			row.add_child(_label("  %d Pkt" % int(player.score), 21, COLOR_INK, true))
	if embedded_lan != null:
		var score_rows: Array = []
		for player in sorted_players:
			score_rows.append({"name": str(player.name), "score": int(player.score)})
		network_score_snapshot = {"newPhase": "SCORES", "timeLimitSec": 0, "scores": score_rows, "final": final_round, "tiebreak": final_tie}
		embedded_lan.publish([
			{"type": "PHASE_CHANGE", "payload": network_score_snapshot}
		])
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	if round_index < max_rounds - 1:
		embedded_lan.begin_ready_gate("ROUND")
		var next := _button("ICH BIN BEREIT · NÄCHSTE RUNDE", Color(COLOR_GREEN, 0.22), Callable(self, "_host_ready"))
		next.custom_minimum_size = Vector2(260, 60)
		actions.add_child(next)
		var fast_next := _button("HOST · SOFORT WEITER", Color(COLOR_ACCENT, 0.22), Callable(self, "_host_continue_now"))
		fast_next.custom_minimum_size = Vector2(220, 60)
		actions.add_child(fast_next)
	elif final_tie:
		var tie := _button("SCHÄTZ-TIEBREAK STARTEN", Color(COLOR_ACCENT, 0.24), Callable(self, "_start_tiebreak"))
		tie.custom_minimum_size = Vector2(300, 60)
		actions.add_child(tie)
	else:
		embedded_lan.begin_ready_gate("PODIUM")
		var podium_ready := _button("ZUR PLATZIERUNG", Color(COLOR_ACCENT, 0.24), Callable(self, "_host_ready"))
		podium_ready.custom_minimum_size = Vector2(300, 60)
		actions.add_child(podium_ready)
		var restart := _button("Neue Runde", Color(COLOR_PURPLE, 0.18), Callable(self, "_new_game"))
		restart.custom_minimum_size = Vector2(210, 60)
		actions.add_child(restart)
		action_bar.add_child(actions)
		_add_admin_button()
		_add_emoji_bar()

func _final_has_tie() -> bool:
	if players.size() < 2:
		return false
	var sorted_players: Array = players.duplicate()
	sorted_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	return int(sorted_players[0].score) == int(sorted_players[1].score)

func _host_continue_now() -> void:
	if phase == Phase.SCOREBOARD and embedded_lan != null and embedded_lan.gate_active:
		embedded_lan.skip_gate()

func _start_tiebreak() -> void:
	if not _has_estimation_questions() or not _final_has_tie():
		_show_podium()
		return
	var sorted_players: Array = players.duplicate()
	sorted_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	tiebreak_players = [str(sorted_players[0].id), str(sorted_players[1].id)]
	tiebreak_active = true
	round_index = max_rounds
	_show_input()

func _show_podium() -> void:
	Monetization.show_placement_ad()
	_settle_challenge_rewards()
	aaa_audio.play_cue("fanfare")
	aaa_audio.haptic_pattern([55, 30, 80, 30, 120])
	if stage_fx != null:
		stage_fx.emit_burst(Vector2(size.x * 0.5, size.y * 0.3), COLOR_ACCENT, 34)
	phase = Phase.PODIUM
	host_gate_ready = false
	_set_phase_text("FINALE · CHAMPION-PODIUM")
	_clear_body()
	var podium_mascot := _brand_mascot(Vector2(104, 104))
	body.add_child(podium_mascot)
	_celebrate_mascot(podium_mascot, true)
	var sorted_players: Array = players.duplicate()
	sorted_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.score) > int(b.score))
	body.add_child(_label("DAS GROSSE FINALE", 18, COLOR_ACCENT, true))
	body.add_child(_label("Wer blufft, gewinnt.", 34, COLOR_INK, true))
	var podium_entries := _podium_payload(sorted_players)
	for entry in podium_entries:
		var place := int(entry.get("rank", 0))
		var card := _card(Color("3b2d4d") if place == 1 else COLOR_SURFACE, Color(COLOR_ACCENT, 0.8) if place <= 3 else Color(COLOR_PURPLE, 0.38))
		if place == 1:
			_apply_foil(card)
			card.scale = Vector2(0.94, 0.94)
			card.pivot_offset = Vector2(0, 0)
			create_tween().tween_property(card, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var row_box: BoxContainer = VBoxContainer.new() if portrait_layout else HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 16)
		card.add_child(row_box)
		var podium_avatar := _player_avatar_image(entry, 128 if place == 1 else 92)
		podium_avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if portrait_layout else Control.SIZE_FILL
		row_box.add_child(podium_avatar)
		var details := VBoxContainer.new()
		details.alignment = BoxContainer.ALIGNMENT_CENTER
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rank_badge: String = ["🥇", "🥈", "🥉"][place - 1] if place >= 1 and place <= 3 else "%d." % place
		details.add_child(_label("%s · %s" % [rank_badge, str(entry.get("name", "Spieler"))], 24 if place == 1 else 20, COLOR_INK, true))
		var podium_score := _label("0 GESAMTPUNKTE" if place == 1 else "%d GESAMTPUNKTE" % int(entry.get("score", 0)), 26 if place == 1 else 19, COLOR_GREEN, true)
		details.add_child(podium_score)
		if place == 1:
			_animate_integer_label(podium_score, int(entry.get("score", 0)), "%d GESAMTPUNKTE")
		var quip := _label(str(entry.get("quip", "")), 14, COLOR_MUTED, false)
		quip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(quip)
		var mission_text := str(entry.get("challengeText", ""))
		if not mission_text.is_empty():
			var mission := _label("MISSION: %s" % mission_text, 12, COLOR_CYAN, false)
			mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_child(mission)
			var mission_result := "Geschafft · +%d Punkte" % int(entry.get("challengeBonus", 0)) if int(entry.get("challengeBonus", 0)) > 0 else "Erwischt · +0 Missionspunkte"
			details.add_child(_label(mission_result, 12, COLOR_GREEN if int(entry.get("challengeBonus", 0)) > 0 else COLOR_MUTED, true))
		row_box.add_child(details)
		body.add_child(card)
	var awards := _award_payload(sorted_players)
	body.add_child(_label("DER GRÖSSTE LÜGNER · %s" % str(awards.liar), 14, COLOR_PURPLE, true))
	body.add_child(_label("DER MEISTERDETEKTIV · %s · %s" % [str(awards.detective), str(awards.victim)], 14, COLOR_CYAN, true))
	network_podium_snapshot = {"newPhase": "FINAL_PODIUM", "podium": podium_entries, "awards": awards}
	embedded_lan.publish([{"type": "PHASE_CHANGE", "payload": network_podium_snapshot}])
	embedded_lan.begin_ready_gate("REMATCH")
	var rematch := _button("NOCHMAL SPIELEN · ALLE AUF GO!", Color(COLOR_GREEN, 0.24), Callable(self, "_host_ready"))
	rematch.custom_minimum_size = Vector2(330, 64)
	action_bar.add_child(rematch)
	_add_admin_button()

func _podium_payload(sorted_players: Array) -> Array:
	var result: Array = []
	for index in range(sorted_players.size()):
		var player: Dictionary = sorted_players[index]
		result.append({"id": str(player.get("id", "")), "rank": index + 1, "name": str(player.get("name", "Spieler")), "score": int(player.get("score", 0)), "avatarIndex": int(player.get("avatarIndex", 0)), "quip": _podium_quip_for_rank(index + 1), "challengeText": str(player.get("challengeText", "")), "challengeCaught": bool(player.get("challengeCaught", false)), "challengeBonus": int(player.get("challengeBonus", 0))})
	return result

func _award_payload(sorted_players: Array) -> Dictionary:
	var liar: Dictionary = sorted_players[0]
	var detective: Dictionary = sorted_players[0]
	var victim: Dictionary = sorted_players[0]
	for player in sorted_players:
		if int(player.get("deceived_total", 0)) > int(liar.get("deceived_total", 0)): liar = player
		if int(player.get("correct", 0)) > int(detective.get("correct", 0)): detective = player
		if int(player.get("fooled", 0)) > int(victim.get("fooled", 0)): victim = player
	return {"liar": str(liar.name), "detective": str(detective.name), "victim": str(victim.name)}

func _next_round() -> void:
	round_index += 1
	_show_input()

func _new_game() -> void:
	challenge_session_active = false
	challenge_rewards_settled = false
	challenge_pool_order.clear()
	challenge_pool_cursor = 0
	native_challenge_text = ""
	native_challenge_caught = false
	native_challenge_bonus = 0
	native_challenge_resolved = false
	_reset_players()
	round_index = 0
	previous_best_lie = ""
	tiebreak_active = false
	tiebreak_players.clear()
	_prepare_question_order()
	_show_lobby()

func _set_phase_text(text: String) -> void:
	if phase_label != null:
		var display_text := text
		if portrait_layout:
			display_text = display_text.replace("ABSTIMMUNG", "TIPP").replace("WEM GLAUBST DU?", "AUSWÄHLEN")
			if display_text.length() > 20:
				display_text = display_text.substr(0, 19).strip_edges() + "…"
		phase_label.text = display_text
	if room_label != null:
		room_label.text = "RAUM %s" % room_code

func _clear_body() -> void:
	if body == null:
		return
	if body_scroll != null and is_instance_valid(body_scroll):
		body_scroll.scroll_vertical = 0
		body_scroll.set_deferred("scroll_vertical", 0)
	for child in body.get_children():
		# Nie den gerade klickenden Button synchron freigeben: Android kann
		# sonst während des pressed-Callbacks in eine ungültige Signal-Node laufen.
		body.remove_child(child)
		child.queue_free()
	if action_bar != null:
		for child in action_bar.get_children():
			action_bar.remove_child(child)
			child.queue_free()
			timer_label = null
			timer_bar = null
			answer_input = null
			feedback_label = null
			round_progress_label = null
			native_question_label = null
			native_feedback_label = null
			native_status_label = null
	if body_scroll != null and is_instance_valid(body_scroll):
		body_scroll.set_deferred("scroll_vertical", 0)

func _card(bg: Color = COLOR_SURFACE, border: Color = Color("2b395b")) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(bg, border, 15, 1))
	panel.material = _shader_material(GLASS_SHADER, border)
	return panel

func _brand_mascot(minimum_size: Vector2 = Vector2(84, 84)) -> TextureRect:
	var mascot := TextureRect.new()
	mascot.texture = MINDFOX_MASCOT
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.custom_minimum_size = minimum_size
	mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mascot

func _style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style

func _label(text: String, size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT_BOLD if bold else FONT_REGULAR)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 1
	return label

func _button(text: String, bg: Color, callback: Callable, args: Array = []) -> Button:
	var button := Button.new()
	button.text = text
	button.name = "Button_%s" % text.replace("\n", "_").replace(" ", "_").left(28)
	button.tooltip_text = text.replace("\n", " · ")
	button.custom_minimum_size = Vector2(0, 52)
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", COLOR_INK)
	button.add_theme_color_override("font_hover_color", COLOR_INK)
	button.add_theme_color_override("font_pressed_color", COLOR_BG)
	button.add_theme_color_override("font_disabled_color", Color("65718e"))
	button.add_theme_stylebox_override("normal", _style(bg, Color(bg, 0.9), 12, 1))
	button.add_theme_stylebox_override("hover", _style(Color(bg, minf(1.0, bg.a + 0.10)), COLOR_ACCENT, 12, 2))
	button.add_theme_stylebox_override("pressed", _style(COLOR_ACCENT, COLOR_ACCENT, 12, 2))
	button.add_theme_stylebox_override("focus", _style(bg, COLOR_ACCENT, 12, 2))
	button.add_theme_stylebox_override("disabled", _style(Color("202a43"), Color("35415e"), 12, 1))
	button.material = _shader_material(NEON_SHADER, COLOR_ACCENT if bg.a > 0.1 else COLOR_CYAN)
	button.pressed.connect(func() -> void: _juicy_press(button))
	if args.is_empty():
		button.pressed.connect(callback)
	else:
		button.pressed.connect(callback.bindv(args))
	return button

func _shader_material(shader: Shader, accent: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	if shader == GLASS_SHADER:
		material.set_shader_parameter("rim_color", accent)
		material.set_shader_parameter("rim_strength", 0.2)
	elif shader == NEON_SHADER:
		material.set_shader_parameter("glow_color", accent)
		material.set_shader_parameter("pulse_strength", 0.16)
	return material

func _apply_foil(control: CanvasItem) -> void:
	if control == null:
		return
	var material := ShaderMaterial.new()
	material.shader = FOIL_SHADER
	material.set_shader_parameter("foil_color_a", COLOR_ACCENT)
	material.set_shader_parameter("foil_color_b", COLOR_CYAN)
	material.set_shader_parameter("sweep_strength", 0.32)
	control.material = material

func _animate_integer_label(label: Label, target: int, format_text: String) -> void:
	if label == null or not is_instance_valid(label):
		return
	if _reduced_motion_enabled():
		label.text = format_text % target
		return
	label.text = format_text % 0
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		if is_instance_valid(label):
			label.text = format_text % int(round(value))
	, 0.0, float(target), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _pulse_control(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	if _reduced_motion_enabled():
		return
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2(1.025, 1.025), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _celebrate_mascot(mascot: Control, strong: bool) -> void:
	if mascot == null or not is_instance_valid(mascot) or _reduced_motion_enabled():
		return
	mascot.pivot_offset = mascot.size * 0.5
	var peak := 1.08 if strong else 1.045
	var tween := create_tween()
	tween.tween_property(mascot, "scale", Vector2(peak, peak), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mascot, "rotation", -0.035 if strong else 0.02, 0.16).set_trans(Tween.TRANS_SINE)
	tween.tween_property(mascot, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(mascot, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _juicy_press(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	aaa_audio.play_cue("click")
	aaa_audio.haptic(10)
	if _reduced_motion_enabled():
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.965, 0.965), 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _reduced_motion_enabled() -> bool:
	return reduced_motion_user or bool(ProjectSettings.get_setting("mindfox/accessibility/reduced_motion", false)) or OS.get_environment("MINDFOX_REDUCED_MOTION") == "1"

func _load_accessibility_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://mindfox_settings.cfg") == OK:
		reduced_motion_user = bool(config.get_value("accessibility", "reduced_motion", false))

func _save_accessibility_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("accessibility", "reduced_motion", reduced_motion_user)
	config.save("user://mindfox_settings.cfg")

func _show_accessibility_settings() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = _ui_text("mf.settings.title", "Einstellungen")
	dialog.dialog_text = "%s\n%s" % [_ui_text("mf.settings.local_note", "Diese Einstellung wird lokal auf diesem Gerät gespeichert."), _ui_text("mf.settings.motion_desc", "Nicht notwendige Animationen und Score-Übergänge deaktivieren.")]
	var reduced_motion := CheckButton.new()
	reduced_motion.text = _ui_text("mf.settings.motion", "Bewegung reduzieren")
	reduced_motion.button_pressed = reduced_motion_user
	reduced_motion.custom_minimum_size.y = 48
	reduced_motion.toggled.connect(func(enabled: bool) -> void:
		reduced_motion_user = enabled
		_save_accessibility_settings()
	)
	dialog.add_child(reduced_motion)
	var language_button := _button(_ui_text("mf.settings.language", "SPRACHE: {language}").replace("{language}", _locale_display_name()), Color(COLOR_SURFACE_2, 0.82), Callable(self, "_cycle_locale"))
	language_button.custom_minimum_size.y = 48
	dialog.add_child(language_button)
	add_child(dialog)
	dialog.popup_centered(Vector2(440, 220))

func _on_brand_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var now := Time.get_ticks_msec()
	if now - _brand_last_click_ms > 2500:
		_brand_click_count = 0
	_brand_last_click_ms = now
	_brand_click_count += 1
	if _brand_click_count >= 6:
		_brand_click_count = 0
		_show_hidden_settings()
	get_viewport().set_input_as_handled()

func _show_hidden_settings() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = _ui_text("mf.settings.title", "Einstellungen")
	dialog.dialog_text = "MindFox\nVersion: %s\nBuild: %s" % [str(ProjectSettings.get_setting("application/config/version", "unbekannt")), str(ProjectSettings.get_setting("application/config/build", "1"))]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var diagnosis := _button("DIAGNOSE", Color(COLOR_PURPLE, 0.20), Callable(self, "_copy_diagnostics"))
	diagnosis.custom_minimum_size.y = 48
	diagnosis.tooltip_text = "App- und Netzwerkprobleme in die Zwischenablage kopieren"
	box.add_child(diagnosis)
	var accessibility := _button("BEDIENUNG & SPRACHE", Color(COLOR_SURFACE_2, 0.82), Callable(self, "_show_accessibility_settings"))
	accessibility.custom_minimum_size.y = 48
	box.add_child(accessibility)
	dialog.add_child(box)
	add_child(dialog)
	dialog.popup_centered(Vector2(440, 250))

func _locale_display_name() -> String:
	if I18n == null:
		return "Deutsch"
	match I18n.get_locale():
		"en": return "English"
		"zh-CN": return "中文"
		_: return "Deutsch"

func _cycle_locale() -> void:
	if I18n == null:
		return
	I18n.toggle_locale()
	for child in get_children():
		if child is AcceptDialog:
			child.queue_free()

func _on_locale_changed(_locale: String) -> void:
	if app_mode == "HOME":
		_show_welcome()
	elif app_mode == "JOIN":
		_show_join_screen()
	elif app_mode == "HOST" and phase == Phase.LOBBY:
		_show_lobby()
	elif app_mode == "CLIENT" and phase == Phase.LOBBY:
		_show_native_lobby()

func _ui_text(key: String, fallback: String) -> String:
	if I18n != null:
		var translated := I18n.t(key)
		if translated != key:
			return translated
	return fallback

func _copy_url_button(text: String, url: String, bg: Color) -> Button:
	var button := _button(text, bg, Callable(self, "_copy_url"), [url])
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 14)
	return button

func _copy_host_ips() -> void:
	var addresses: Array[String] = local_ip_addresses.duplicate()
	if addresses.is_empty():
		addresses.append(local_ip)
	DisplayServer.clipboard_set("\n".join(PackedStringArray(addresses)))

func _copy_url(url: String) -> void:
	DisplayServer.clipboard_set(url)
	if phase_label != null:
		phase_label.text = "LOBBY · ADRESSE KOPIERT"

func _clean_text(value: String) -> String:
	return GAME_RULES.clean_text(value)

func _levenshtein(a: String, b: String) -> int:
	return GAME_RULES.levenshtein(a, b)
