extends Node
## Native Handy-Client für den lokalen Host.
## Der Client spricht dasselbe schlanke WebSocket-Protokoll wie der Host,
## verwendet aber keinerlei Browser- oder HTTP-Abhängigkeit.

signal connected(payload: Dictionary)
signal disconnected(reason: String)
signal connection_state_changed(state: String, detail: String)
signal message_received(kind: String, payload: Dictionary)
signal discovery_room_found(payload: Dictionary)
signal discovery_room_expired(room_key: String)

const WS_PORT := 8081
const DISCOVERY_PORT := 41234
const DISCOVERY_TTL_MS := 4500
const CONNECT_TIMEOUT_MS := 9000
const MAX_CONNECT_RETRIES := 2
const PING_INTERVAL_MS := 5000
const PONG_TIMEOUT_MS := 16000
const MAX_CLIENT_PACKET_BYTES := 262144
const MAX_CLIENT_PACKETS_PER_FRAME := 64

var peer := WebSocketPeer.new()
var discovery := PacketPeerUDP.new()
var discovery_active := false
var _discovery_rooms: Dictionary = {}
var host_address := ""
var host_port := WS_PORT
var fallback_addresses: Array[String] = []
var room_code := ""
var player_name := ""
var player_id := ""
var session_token := ""
var avatar_index := 0
var avatar_tint := 0
var avatar_expression := 0
var gate_id := ""
var _connecting := false
var _announced_open := false
var _awaiting_login := false
var _connect_started_at := 0
var _retry_count := 0
var _last_ping_at := 0
var _last_pong_at := 0
var _last_state := "idle"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var profile := ConfigFile.new()
	if profile.load("user://mindfox_profile.cfg") == OK:
		player_id = str(profile.get_value("identity", "player_id", ""))
		session_token = str(profile.get_value("identity", "session_token", ""))
		player_name = str(profile.get_value("profile", "player_name", ""))
		avatar_index = clampi(int(profile.get_value("profile", "avatar_index", 0)), 0, 7)
		avatar_tint = clampi(int(profile.get_value("profile", "avatar_tint", 0)), 0, 4)
		avatar_expression = clampi(int(profile.get_value("profile", "avatar_expression", 0)), 0, 3)
		host_address = str(profile.get_value("last_connection", "host", ""))
		host_port = int(profile.get_value("last_connection", "port", WS_PORT))
		room_code = str(profile.get_value("last_connection", "room", ""))

func _process(delta: float) -> void:
	_poll_discovery()
	if peer.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		peer.poll()
		if Time.get_ticks_msec() - _connect_started_at > CONNECT_TIMEOUT_MS:
			_retry_or_fail("Zeitüberschreitung. Prüfe Host-IP und WLAN.")
		return
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		peer.poll()
		if not _announced_open:
			_announced_open = true
			_connecting = true
			_awaiting_login = true
			_last_ping_at = Time.get_ticks_msec()
			_last_pong_at = _last_ping_at
			_set_state("connecting", "Netzwerk steht – melde dich beim Host an …")
			_send("CONNECT_REQ", {"playerId": player_id, "sessionToken": session_token, "playerName": player_name, "avatarIndex": avatar_index, "avatarTint": avatar_tint, "avatarExpression": avatar_expression})
		if _awaiting_login and Time.get_ticks_msec() - _connect_started_at > CONNECT_TIMEOUT_MS:
			_retry_or_fail("Der Host antwortet nicht auf die Login-Anfrage. Prüfe Raumcode, Host-IP und WLAN.")
			return
		var now := Time.get_ticks_msec()
		if now - _last_ping_at >= PING_INTERVAL_MS:
			_send("PING", {})
			_last_ping_at = now
		if now - _last_pong_at > PONG_TIMEOUT_MS:
			_retry_or_fail("Der Host antwortet nicht mehr auf den Verbindungs-Heartbeat.")
			return
		var packets_processed := 0
		while peer.get_available_packet_count() > 0 and packets_processed < MAX_CLIENT_PACKETS_PER_FRAME:
			var packet := peer.get_packet()
			packets_processed += 1
			if packet.size() > MAX_CLIENT_PACKET_BYTES:
				_retry_or_fail("Der Host hat ein ungültig großes Netzwerkpaket gesendet.")
				return
			var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
			if parsed is Dictionary:
				_handle_message(parsed)
		return
	if _connecting and peer.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		_retry_or_fail("Host nicht erreichbar. Prüfe, ob beide Handys im selben WLAN/Hotspot sind und die angezeigte Host-IP stimmt.")
	elif _announced_open and peer.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		_announced_open = false
		_set_state("disconnected", "Verbindung zum Host verloren.")
		disconnected.emit("Verbindung zum Host verloren. Prüfe WLAN und Host-Handy.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_set_state("paused", "App pausiert – Verbindung wird beim Zurückkehren geprüft.")
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if not host_address.is_empty() and not room_code.is_empty() and not player_name.is_empty() and peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
			_set_state("connecting", "App ist zurück – stelle Verbindung wieder her …")
			connect_to_host(host_address, room_code, player_name, avatar_index, avatar_tint, avatar_expression, host_port, fallback_addresses)

func send_ping() -> void:
	if peer != null and peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send("PING", {})

func connect_to_host(address: String, code: String, name: String, selected_avatar: int = 0, tint: int = 0, expression: int = 0, port: int = WS_PORT, fallback_hosts: Array[String] = [], retry_attempt: int = 0) -> void:
	disconnect_from_host()
	_retry_count = clampi(retry_attempt, 0, MAX_CONNECT_RETRIES)
	host_address = _clean_address(address)
	host_port = clampi(port, 1, 65535)
	fallback_addresses = fallback_hosts.duplicate()
	room_code = code.strip_edges().to_upper()
	player_name = name.strip_edges().left(18)
	avatar_index = clampi(selected_avatar, 0, 7)
	avatar_tint = clampi(tint, 0, 4)
	avatar_expression = clampi(expression, 0, 3)
	_save_profile()
	if host_address.is_empty() or room_code.is_empty() or player_name.is_empty():
		_fail("Bitte Host-IP, Raumcode und deinen Namen ausfüllen.")
		return
	if player_id.is_empty():
		player_id = "guest_%s_%s" % [str(Time.get_ticks_msec()), str(randi() % 1000)]
	_save_profile()
	peer = WebSocketPeer.new()
	peer.set_inbound_buffer_size(MAX_CLIENT_PACKET_BYTES)
	peer.set_outbound_buffer_size(65536)
	peer.set_max_queued_packets(MAX_CLIENT_PACKETS_PER_FRAME * 2)
	var url := "ws://%s:%d/ws?room=%s" % [host_address, host_port, room_code]
	var error := peer.connect_to_url(url)
	if error != OK:
		_retry_or_fail("Verbindungsversuch konnte nicht gestartet werden (%s)." % error)
		return
	_connecting = true
	_announced_open = false
	_connect_started_at = Time.get_ticks_msec()
	_set_state("connecting", "Verbinde mit %s …" % host_address)

func disconnect_from_host() -> void:
	_connecting = false
	_announced_open = false
	_awaiting_login = false
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN or peer.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		peer.close()

func send_ready() -> void:
	_send("READY_GATE_REQ", {"playerName": player_name, "gateId": gate_id})

func send_avatar_change(avatar_index: int) -> void:
	_send("AVATAR_CHANGE_REQ", {"avatarIndex": clampi(avatar_index, 0, 7)})

func send_player_rocket(target_id: String) -> void:
	_send("PLAYER_ROCKET_REQ", {"targetId": target_id})

func send_lie(question_id: String, text: String) -> bool:
	return _send("SUBMIT_LIE_REQ", {"questionId": question_id, "lieText": text})

func send_vote(option_id: String, confidence: int, question_id: String = "") -> bool:
	return _send("SUBMIT_VOTE_REQ", {"selectedOptionId": option_id, "confidence": confidence, "questionId": question_id})

func send_emoji(emoji: String) -> void:
	_send("EMOJI_PING", {"emoji": emoji})

func send_challenge_caught() -> void:
	_send("CHALLENGE_CAUGHT", {})

func start_discovery() -> void:
	if discovery_active:
		return
	discovery = PacketPeerUDP.new()
	var error := discovery.bind(DISCOVERY_PORT, "0.0.0.0")
	if error == OK:
		discovery_active = true
		_set_state("discovery", "Suche automatisch nach Bluff-Räumen im WLAN …")
	else:
		_set_state("error", "Automatische WLAN-Suche konnte nicht gestartet werden (%s). Bitte WLAN aktivieren oder IP und Code manuell eingeben." % error)

func stop_discovery() -> void:
	discovery_active = false
	_discovery_rooms.clear()
	if discovery != null:
		discovery.close()

func _poll_discovery() -> void:
	if not discovery_active or discovery == null:
		return
	var now := Time.get_ticks_msec()
	for room_key in _discovery_rooms.keys():
		if now - int(_discovery_rooms[room_key]) > DISCOVERY_TTL_MS:
			_discovery_rooms.erase(room_key)
			discovery_room_expired.emit(str(room_key))
	while discovery.get_available_packet_count() > 0:
		var packet := discovery.get_packet()
		var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
		if parsed is Dictionary and str(parsed.get("type", "")) == "MINDFOX_ROOM_BEACON":
			var payload: Dictionary = parsed.duplicate(true)
			var advertised_ip := str(payload.get("hostIp", ""))
			var sender_ip := str(discovery.get_packet_ip())
			# Die IP im Beacon kann auf Android durch eine falsche Interface-Auswahl
			# veraltet sein. Die UDP-Absender-IP ist im lokalen WLAN die verlässlichste
			# Adresse für den anschließenden WebSocket-Beitritt.
			if not sender_ip.is_empty() and sender_ip != "0.0.0.0":
				payload["hostIp"] = sender_ip
			else:
				payload["hostIp"] = advertised_ip
			payload["advertisedHostIp"] = advertised_ip
			var host_candidates: Array[String] = []
			for candidate in [sender_ip] + Array(payload.get("hostIps", [])) + [advertised_ip]:
				var candidate_text := str(candidate).strip_edges()
				if not candidate_text.is_empty() and candidate_text != "0.0.0.0" and _is_same_local_subnet(candidate_text) and not host_candidates.has(candidate_text):
					host_candidates.append(candidate_text)
			if host_candidates.is_empty():
				# Falls Android keine lokale IPv4-Adresse meldet, behalten wir den
				# UDP-Absender als letzten Fallback.
				if not sender_ip.is_empty() and sender_ip != "0.0.0.0":
					host_candidates.append(sender_ip)
			payload["hostCandidates"] = host_candidates
			var key := "%s:%s" % [str(payload.get("hostIp", "")), str(payload.get("roomCode", ""))]
			_discovery_rooms[key] = Time.get_ticks_msec()
			discovery_room_found.emit(payload)

func get_player_id() -> String:
	return player_id

func get_last_host() -> String:
	return host_address

func get_last_room_code() -> String:
	return room_code

func get_last_port() -> int:
	return host_port

func get_player_name() -> String:
	return player_name

func get_avatar_index() -> int:
	return avatar_index

func get_avatar_tint() -> int:
	return avatar_tint

func get_avatar_expression() -> int:
	return avatar_expression

func _send(kind: String, payload: Dictionary) -> bool:
	if peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	return peer.send_text(JSON.stringify({"type": kind, "roomId": room_code, "senderId": player_id, "payload": payload})) == OK

func _handle_message(message: Dictionary) -> void:
	var kind := str(message.get("type", ""))
	if str(message.get("roomId", "")).strip_edges().to_upper() != room_code or str(message.get("senderId", "")) != "host":
		return
	var payload_value: Variant = message.get("payload", {})
	if not payload_value is Dictionary:
		return
	var payload: Dictionary = payload_value
	if kind == "GATE_UPDATE":
		gate_id = str(payload.get("gateId", ""))
	if kind == "PONG":
		_last_pong_at = Time.get_ticks_msec()
		return
	if kind == "CONNECT_RESP":
		if str(payload.get("status", "OK")) != "OK":
			var reason := str(payload.get("reason", "UNKNOWN"))
			match reason:
				"WRONG_ROOM": _fail("Der Raumcode gehört nicht zu diesem Host.")
				"ROOM_FULL": _fail("Die Lobby ist voll. Maximal 8 Spieler können beitreten.")
				"SESSION_INVALID": _fail("Diese Spielersitzung wurde abgelehnt. Trenne dich vom alten Gerät oder trete der Lobby erneut bei.")
				_: _fail("Der Host konnte den Beitritt nicht bestätigen (%s)." % reason)
			return
		_awaiting_login = false
		_connecting = false
		_retry_count = 0
		player_id = str(payload.get("playerId", player_id))
		session_token = str(payload.get("sessionToken", session_token))
		_save_profile()
		_last_ping_at = Time.get_ticks_msec()
		_last_pong_at = _last_ping_at
		_set_state("connected", "Sitzung sicher beim Host angemeldet.")
		connected.emit(payload)
		message_received.emit(kind, payload)
		return
	message_received.emit(kind, payload)

func _save_profile() -> void:
	var profile := ConfigFile.new()
	profile.set_value("identity", "player_id", player_id)
	profile.set_value("identity", "session_token", session_token)
	profile.set_value("profile", "player_name", player_name)
	profile.set_value("profile", "avatar_index", avatar_index)
	profile.set_value("profile", "avatar_tint", avatar_tint)
	profile.set_value("profile", "avatar_expression", avatar_expression)
	profile.set_value("last_connection", "host", host_address)
	profile.set_value("last_connection", "port", host_port)
	profile.set_value("last_connection", "room", room_code)
	profile.save("user://mindfox_profile.cfg")

func _clean_address(value: String) -> String:
	var result := value.strip_edges().replace("ws://", "").replace("http://", "").replace("https://", "")
	result = result.split("/", false)[0]
	if result.contains(":"):
		result = result.split(":", false)[0]
	return result.strip_edges()

func _is_same_local_subnet(candidate: String) -> bool:
	var candidate_octets := candidate.split(".")
	if candidate_octets.size() != 4:
		return false
	for octet in candidate_octets:
		if not str(octet).is_valid_int() or int(octet) < 0 or int(octet) > 255:
			return false
	var first := int(candidate_octets[0])
	var second := int(candidate_octets[1])
	# Routermasken sind der App nicht zuverlässig zugänglich. Für im Beacon
	# angekündigte private IPv4-IPs erlauben wir daher Verbindungs-Fallbacks;
	# Routing und Firewall des Betriebssystems bleiben weiterhin maßgeblich.
	if first == 10 or (first == 172 and second >= 16 and second <= 31) or (first == 192 and second == 168):
		return true
	var candidate_prefix := "%s.%s.%s." % [candidate_octets[0], candidate_octets[1], candidate_octets[2]]
	for interface in IP.get_local_interfaces():
		for address in interface.get("addresses", []):
			var local_address := str(address)
			var local_octets := local_address.split(".")
			if local_octets.size() == 4 and local_address.begins_with(candidate_prefix) and not local_address.begins_with("127."):
				return true
	return false

func _set_state(state: String, detail: String) -> void:
	if _last_state == state and state != "error":
		return
	_last_state = state
	connection_state_changed.emit(state, detail)

func _fail(reason: String) -> void:
	_connecting = false
	_announced_open = false
	_awaiting_login = false
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN or peer.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		peer.close()
	_set_state("error", reason)
	disconnected.emit(reason)

func _retry_or_fail(reason: String) -> void:
	if not fallback_addresses.is_empty():
		var next_host := str(fallback_addresses.pop_front())
		if not next_host.is_empty() and next_host != host_address:
			_set_state("connecting", "Versuche alternative Host-IP %s …" % next_host)
			connect_to_host(next_host, room_code, player_name, avatar_index, avatar_tint, avatar_expression, host_port, fallback_addresses, _retry_count)
			return
	if _retry_count < MAX_CONNECT_RETRIES:
		var next_attempt := _retry_count + 1
		_set_state("connecting", "Verbindung stockt – neuer Versuch %d/%d mit %s …" % [next_attempt + 1, MAX_CONNECT_RETRIES + 1, host_address])
		connect_to_host(host_address, room_code, player_name, avatar_index, avatar_tint, avatar_expression, host_port, [], next_attempt)
		return
	_fail("%s Router-, Gastnetz- oder Firewall-Isolation kann lokale Verbindungen blockieren." % reason)
