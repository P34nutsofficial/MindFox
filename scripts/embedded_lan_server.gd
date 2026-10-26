extends Node
## Autarker LAN-Dienst für Android-Host und native Controller.
## HTTP läuft auf 8080, WebSocket bewusst auf 8081, damit die Protokolle
## ohne externe Node-Installation und ohne fragile HTTP-Upgrade-Magie getrennt bleiben.

const HTTP_PORT := 8080
const WS_PORT := 8081
const DISCOVERY_PORT := 41234
const MAX_REQUEST_BYTES := 8192
const MAX_WS_CLIENTS := 16
const MAX_WS_MESSAGE_BYTES := 32768
const MAX_WS_PACKETS_PER_FRAME := 48
const MAX_WS_OUTBOUND_BYTES := 262144
const WS_IDLE_TIMEOUT_MS := 20000
const WS_RATE_WINDOW_MS := 10000
const WS_MAX_MESSAGES_PER_WINDOW := 160

var http_server := TCPServer.new()
var ws_server := TCPServer.new()
var http_clients: Array = []
var ws_clients: Array = []
var room_code := "----"
var websocket_port := WS_PORT
var snapshot: Array = []
var snapshot_payloads: Array = []
var started := false
var gate_active := false
var gate_kind := ""
var gate_id := ""
var gate_ready: Dictionary = {}
var gate_names: Dictionary = {}
var gate_started_at := 0
var gate_timeout_ms := 25000
var mdns := PacketPeerUDP.new()
var mdns_ip := "127.0.0.1"
var configured_host_ips: Array[String] = []
var discovery := PacketPeerUDP.new()
var discovery_ready := false
var discovery_elapsed := 0.0
var discovery_player_count := 0
var discovery_host_name := "Bluff-Host"
var discovery_category := "Bizarres Halbwissen & Kuriose Gesetze"
var session_tokens: Dictionary = {}

signal gate_completed(kind: String)
signal client_event(event: Dictionary)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Godot verwendet "*" plattformübergreifend für alle Interfaces. Auf
	# Android kann ein explizites "0.0.0.0" lokal funktionieren, aber eingehende
	# WLAN-Verbindungen trotzdem nicht zuverlässig annehmen.
	var http_error := http_server.listen(HTTP_PORT, "*")
	var ws_error := ws_server.listen(websocket_port, "*")
	if ws_error != OK:
		websocket_port = WS_PORT + 1
		ws_error = ws_server.listen(websocket_port, "*")
	mdns.bind(5353, "0.0.0.0")
	discovery.set_broadcast_enabled(true)
	discovery_ready = discovery.bind(DISCOVERY_PORT, "0.0.0.0") == OK
	for interface in IP.get_local_interfaces():
		var interface_name := str(interface.get("name", ""))
		if interface_name.is_empty() or interface_name.begins_with("lo"):
			continue
		if mdns.join_multicast_group("224.0.0.251", interface_name) == OK:
			break
	# Für Handy-zu-Handy ist der WebSocket-Listener entscheidend; ein
	# belegter HTTP-Port darf den nativen Beitritt nicht blockieren.
	started = ws_error == OK
	if started:
		print("[mindfox] embedded LAN ready on HTTP %d / WebSocket %d" % [HTTP_PORT, websocket_port])
	else:
		push_warning("Eingebetteter LAN-Dienst konnte nicht starten: HTTP=%s WS=%s" % [http_error, ws_error])

func _exit_tree() -> void:
	http_server.stop()
	ws_server.stop()
	discovery.close()
	for item in ws_clients:
		var peer: WebSocketPeer = item.peer
		peer.close()

func _process(delta: float) -> void:
	_poll_http()
	_poll_websockets()
	_poll_mdns()
	discovery_elapsed += delta
	if discovery_elapsed >= 1.5:
		discovery_elapsed = 0.0
		_emit_discovery_beacon()
	# Das Gate öffnet sich niemals automatisch. Ein Host-Override wird
	# ausschließlich über die ausdrücklich bestätigte Admin-Aktion ausgelöst.

func set_room(code: String) -> void:
	room_code = code
	_broadcast("ROOM_STATE", {"playerCount": 0, "phase": "LOBBY", "round": 0, "roomCode": room_code, "showMode": "showrunner_mix"})

func set_mdns_ip(address: String) -> void:
	mdns_ip = address

func set_host_ip_candidates(addresses: Array[String]) -> void:
	configured_host_ips.clear()
	for address in addresses:
		var candidate := str(address).strip_edges()
		if candidate.count(".") == 3 and not candidate.begins_with("127.") and not candidate.begins_with("169.254.") and not configured_host_ips.has(candidate):
			configured_host_ips.append(candidate)

func set_discovery_metadata(host_name: String, category: String) -> void:
	discovery_host_name = host_name.strip_edges().left(24) if not host_name.strip_edges().is_empty() else "Bluff-Host"
	discovery_category = category

func set_player_count(count: int) -> void:
	discovery_player_count = maxi(0, count)

func _emit_discovery_beacon() -> void:
	if not started or not discovery_ready or room_code == "----" or room_code.is_empty():
		return
	var host_ips: Array[String] = configured_host_ips.duplicate()
	for candidate in _local_ipv4_addresses():
		if not host_ips.has(candidate):
			host_ips.append(candidate)
	if host_ips.is_empty() and not mdns_ip.is_empty():
		host_ips.append(mdns_ip)
	var beacon := {"type": "MINDFOX_ROOM_BEACON", "serverReady": started, "roomCode": room_code, "hostName": discovery_host_name, "playerCount": discovery_player_count, "maxPlayers": 8, "port": websocket_port, "hostIp": host_ips[0] if not host_ips.is_empty() else mdns_ip, "hostIps": host_ips, "category": discovery_category, "sentAt": Time.get_ticks_msec()}
	var packet := JSON.stringify(beacon).to_utf8_buffer()
	var destinations: Array[String] = ["255.255.255.255"]
	for host_ip in host_ips:
		var octets := host_ip.split(".")
		if octets.size() == 4:
			destinations.append("%s.%s.%s.255" % [octets[0], octets[1], octets[2]])
	for destination in destinations:
		if destinations.find(destination) != destinations.rfind(destination):
			continue
		discovery.set_dest_address(destination, DISCOVERY_PORT)
		discovery.put_packet(packet)

func _local_ipv4_addresses() -> Array[String]:
	var addresses: Array[String] = []
	for interface in IP.get_local_interfaces():
		var interface_name := str(interface.get("name", "")).to_lower()
		var is_virtual := interface_name.begins_with("lo") or interface_name.contains("docker") or interface_name.contains("veth") or interface_name.contains("tun") or interface_name.contains("vpn") or interface_name.contains("wireguard") or interface_name.begins_with("wg") or interface_name.contains("tailscale") or interface_name.contains("rmnet") or interface_name.contains("ccmni") or interface_name.contains("wwan") or interface_name.contains("dummy")
		if is_virtual:
			continue
		for address in interface.get("addresses", []):
			var candidate := str(address)
			if candidate.count(".") == 3 and not candidate.begins_with("127.") and not candidate.begins_with("169.254.") and not addresses.has(candidate):
				addresses.append(candidate)
	return addresses

func _poll_mdns() -> void:
	while mdns.get_available_packet_count() > 0:
		mdns.get_packet()
		var octets := mdns_ip.split(".")
		if octets.size() != 4:
			continue
		var response := PackedByteArray([0, 0, 0x84, 0, 0, 0, 0, 1, 0, 0, 0, 0])
		response.append_array(PackedByteArray([5]))
		response.append_array("bluff".to_utf8_buffer())
		response.append_array(PackedByteArray([5]))
		response.append_array("local".to_utf8_buffer())
		response.append(0)
		response.append_array(PackedByteArray([0, 1, 0, 1, 0, 0, 0, 120, 0, 4]))
		for octet in octets:
			response.append(clampi(int(octet), 0, 255))
		mdns.set_dest_address(mdns.get_packet_ip(), mdns.get_packet_port())
		mdns.put_packet(response)

func begin_ready_gate(kind: String) -> void:
	gate_active = true
	gate_kind = kind
	gate_id = Crypto.new().generate_random_bytes(16).hex_encode()
	gate_started_at = Time.get_ticks_msec()
	gate_ready.clear()
	gate_names.clear()
	gate_ready["host"] = false
	gate_names["host"] = "Du · Host"
	for item in ws_clients:
		var player_id := str(item.player_id)
		if player_id.is_empty():
			continue
		gate_ready[player_id] = false
		gate_names[player_id] = str(item.get("player_name", "Gast"))
	_publish_gate()

func mark_host_ready() -> void:
	if not gate_active:
		return
	gate_ready["host"] = true
	_publish_gate()
	_check_gate_complete()

func skip_gate() -> void:
	if not gate_active:
		return
	for player_id in gate_ready.keys():
		gate_ready[player_id] = true
	_publish_gate()
	_check_gate_complete()

func _publish_gate() -> void:
	var ready_list: Array = []
	var players_list: Array = []
	for player_id in gate_ready.keys():
		players_list.append({"id": str(player_id), "name": str(gate_names.get(player_id, "Gast")), "ready": bool(gate_ready[player_id])})
		if bool(gate_ready[player_id]):
			ready_list.append(str(player_id))
	_broadcast("GATE_UPDATE", {"gate": gate_kind, "gateId": gate_id, "ready": ready_list, "players": players_list, "readyCount": ready_list.size(), "total": gate_ready.size(), "waitingMs": maxi(0, Time.get_ticks_msec() - gate_started_at), "skipAvailable": Time.get_ticks_msec() - gate_started_at >= gate_timeout_ms})

func _check_gate_complete() -> void:
	if not gate_active or gate_ready.is_empty():
		return
	for ready in gate_ready.values():
		if not bool(ready):
			return
	gate_active = false
	var completed := gate_kind
	gate_kind = ""
	gate_completed.emit(completed)
	_broadcast("GATE_COMPLETE", {"gate": completed})

func publish(messages: Array) -> void:
	# messages ist eine Liste von Dictionaries mit type und payload.
	snapshot = messages.duplicate(true)
	for message in messages:
		_broadcast(str(message.get("type", "")), message.get("payload", {}))

func _poll_http() -> void:
	while http_server.is_connection_available():
		var peer := http_server.take_connection()
		peer.set_no_delay(true)
		http_clients.append({"peer": peer, "buffer": PackedByteArray()})
	for item in http_clients.duplicate():
		var peer: StreamPeerTCP = item.peer
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			http_clients.erase(item)
			continue
		var available := peer.get_available_bytes()
		if available <= 0:
			continue
		var result: Array = peer.get_partial_data(mini(available, MAX_REQUEST_BYTES))
		if result.size() < 2 or result[0] != OK:
			http_clients.erase(item)
			continue
		item.buffer.append_array(result[1])
		if item.buffer.size() > MAX_REQUEST_BYTES:
			_send_http(peer, 413, "text/plain; charset=utf-8", "Anfrage zu groß")
			http_clients.erase(item)
			continue
		var request: String = item.buffer.get_string_from_utf8()
		if not request.contains("\r\n\r\n"):
			continue
		var first_line: String = request.split("\r\n", false)[0]
		var parts: PackedStringArray = first_line.split(" ", false)
		var path: String = "/" if parts.size() < 2 else str(parts[1]).split("?", false)[0]
		if path == "/":
			_send_redirect(peer, "/client")
			http_clients.erase(item)
			continue
		elif path == "/client" or path == "/client/":
			path = "/client/index.html"
		_serve_path(peer, path)
		http_clients.erase(item)

func _send_redirect(peer: StreamPeerTCP, location: String) -> void:
	var header := "HTTP/1.1 302 Found\r\nLocation: %s\r\nCache-Control: no-store\r\nContent-Length: 0\r\nConnection: close\r\n\r\n" % location
	peer.put_data(header.to_utf8_buffer())
	peer.disconnect_from_host()

func _serve_path(peer: StreamPeerTCP, path: String) -> void:
	if path.contains("..") or not path.begins_with("/"):
		_send_http(peer, 400, "text/plain; charset=utf-8", "Ungültiger Pfad")
		return
	var resource := "res://web" + path
	if not FileAccess.file_exists(resource):
		_send_http(peer, 404, "text/plain; charset=utf-8", "Nicht gefunden")
		return
	var body := FileAccess.get_file_as_bytes(resource)
	_send_http_bytes(peer, 200, _mime(path), body)

func _mime(path: String) -> String:
	var ext := path.get_extension().to_lower()
	match ext:
		"html": return "text/html; charset=utf-8"
		"css": return "text/css; charset=utf-8"
		"js": return "text/javascript; charset=utf-8"
		"json": return "application/json; charset=utf-8"
		"png": return "image/png"
		"jpg", "jpeg": return "image/jpeg"
		"mp4": return "video/mp4"
		_: return "application/octet-stream"

func _send_http(peer: StreamPeerTCP, status: int, content_type: String, text: String) -> void:
	_send_http_bytes(peer, status, content_type, text.to_utf8_buffer())

func _send_http_bytes(peer: StreamPeerTCP, status: int, content_type: String, body: PackedByteArray) -> void:
	var reason := "OK" if status == 200 else ("Not Found" if status == 404 else "Bad Request")
	var header := "HTTP/1.1 %d %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n" % [status, reason, content_type, body.size()]
	peer.put_data(header.to_utf8_buffer())
	peer.put_data(body)
	peer.disconnect_from_host()

func _poll_websockets() -> void:
	while ws_server.is_connection_available():
		var stream := ws_server.take_connection()
		var peer := WebSocketPeer.new()
		peer.set_inbound_buffer_size(MAX_WS_MESSAGE_BYTES)
		peer.set_outbound_buffer_size(MAX_WS_OUTBOUND_BYTES)
		peer.set_max_queued_packets(MAX_WS_PACKETS_PER_FRAME * 2)
		var error := peer.accept_stream(stream)
		if error == OK and ws_clients.size() < MAX_WS_CLIENTS:
				ws_clients.append({"peer": peer, "sent": false, "authenticated": false, "superseded": false, "close_after_send": false, "player_id": "", "last_activity_ms": Time.get_ticks_msec(), "rate_window_ms": Time.get_ticks_msec(), "rate_count": 0})
		else:
			peer.close()
	for item in ws_clients.duplicate():
		var peer: WebSocketPeer = item.peer
		peer.poll()
		if peer.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			if bool(item.get("authenticated", false)) and not bool(item.get("superseded", false)) and not str(item.player_id).is_empty():
				client_event.emit({"type": "DISCONNECT", "playerId": str(item.player_id)})
			ws_clients.erase(item)
			continue
		if peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
			continue
		if bool(item.get("close_after_send", false)):
			if peer.get_current_outbound_buffered_amount() <= 0:
				peer.close()
			continue
		if not bool(item.get("sent", false)):
			var requested := peer.get_requested_url()
			var requested_room := _room_from_requested_url(requested)
			if requested_room != room_code:
				peer.close()
				continue
			item.sent = true
			item.player_id = "guest_%d_%d" % [Time.get_ticks_msec(), randi() % 1000000]
			item.player_name = "Gast"
		var now := Time.get_ticks_msec()
		if now - int(item.get("last_activity_ms", now)) > WS_IDLE_TIMEOUT_MS:
			peer.close()
			continue
		var packets_processed := 0
		while peer.get_available_packet_count() > 0 and packets_processed < MAX_WS_PACKETS_PER_FRAME:
			var packet := peer.get_packet()
			packets_processed += 1
			if packet.size() > MAX_WS_MESSAGE_BYTES:
				peer.close()
				break
			var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
			if not parsed is Dictionary:
				peer.close()
				break
			item.last_activity_ms = now
			item.rate_count = int(item.get("rate_count", 0)) + 1
			if now - int(item.get("rate_window_ms", now)) >= WS_RATE_WINDOW_MS:
				item.rate_window_ms = now
				item.rate_count = 1
			elif int(item.rate_count) > WS_MAX_MESSAGES_PER_WINDOW:
				peer.close()
				break
			_handle_message(item, parsed)

func _room_from_requested_url(requested_url: String) -> String:
	if not requested_url.contains("?"):
		return ""
	var query := requested_url.get_slice("?", 1)
	for pair in query.split("&"):
		if str(pair).begins_with("room="):
			return str(pair).trim_prefix("room=").uri_decode().strip_edges().to_upper()
	return ""

func _handle_message(item: Dictionary, message: Dictionary) -> void:
	var peer: WebSocketPeer = item.peer
	var kind := str(message.get("type", ""))
	if kind.is_empty() or kind.length() > 32 or str(message.get("roomId", "")).strip_edges().to_upper() != room_code:
		peer.close()
		return
	var payload_value: Variant = message.get("payload", {})
	if not payload_value is Dictionary:
		peer.close()
		return
	var payload: Dictionary = payload_value
	if kind == "CONNECT_REQ":
		if bool(item.get("authenticated", false)) or not bool(item.get("sent", false)):
			peer.close()
			return
		var requested_id := str(payload.get("playerId", "")).strip_edges()
		if not requested_id.is_empty() and (requested_id.length() > 64 or not requested_id.begins_with("guest_") or requested_id.to_lower().contains("..")):
			_send_peer(peer, "CONNECT_RESP", {"status": "ERROR", "reason": "INVALID_PLAYER_ID"})
			item.close_after_send = true
			return
		if not requested_id.is_empty():
			item.player_id = requested_id
		var requested_token := str(payload.get("sessionToken", ""))
		var issued_token := str(session_tokens.get(item.player_id, ""))
		if not issued_token.is_empty() and not Crypto.new().constant_time_compare(issued_token.to_utf8_buffer(), requested_token.to_utf8_buffer()):
			_send_peer(peer, "CONNECT_RESP", {"status": "ERROR", "reason": "SESSION_INVALID"})
			item.close_after_send = true
			return
		for previous_item in ws_clients:
			if previous_item == item or not bool(previous_item.get("authenticated", false)) or str(previous_item.get("player_id", "")) != item.player_id:
				continue
			previous_item.superseded = true
			var previous_peer: WebSocketPeer = previous_item.peer
			previous_peer.close()
		if issued_token.is_empty():
			issued_token = Crypto.new().generate_random_bytes(32).hex_encode()
			session_tokens[item.player_id] = issued_token
		item.authenticated = true
		item.player_name = str(payload.get("playerName", "Gast")).strip_edges().left(18)
		_send_peer(peer, "CONNECT_RESP", {"status": "OK", "playerId": item.player_id, "sessionToken": issued_token, "gameState": {"phase": "LOBBY", "roomCode": room_code}})
		client_event.emit({"type": "CONNECT", "playerId": item.player_id, "playerName": item.player_name, "avatarIndex": int(payload.get("avatarIndex", 0)), "avatarTint": int(payload.get("avatarTint", 0)), "avatarExpression": int(payload.get("avatarExpression", 0))})
		if gate_active:
			gate_ready[item.player_id] = false
			gate_names[item.player_id] = item.player_name
			_publish_gate()
		return
	if not bool(item.get("authenticated", false)):
		peer.close()
		return
	if kind == "PLAYER_ROCKET_REQ" or kind == "AVATAR_CHANGE_REQ" or kind == "SUBMIT_LIE_REQ" or kind == "SUBMIT_VOTE_REQ":
		client_event.emit({"type": kind, "playerId": item.player_id, "payload": payload})
	elif kind == "CHALLENGE_CAUGHT":
		client_event.emit({"type": kind, "playerId": item.player_id, "payload": {}})
	elif kind == "READY_GATE_REQ":
		if not gate_active or str(payload.get("gateId", "")) != gate_id:
			if gate_active:
				_publish_gate()
			return
		gate_ready[item.player_id] = true
		_publish_gate()
		_check_gate_complete()
		client_event.emit({"type": kind, "playerId": item.player_id, "payload": payload})
	elif kind == "EMOJI_PING":
		client_event.emit({"type": kind, "playerId": item.player_id, "payload": payload})
	elif kind == "PING":
		_send_peer(peer, "PONG", {})

func _send_peer(peer: WebSocketPeer, kind: String, payload: Dictionary) -> bool:
	if peer.get_ready_state() != WebSocketPeer.STATE_OPEN or peer.get_current_outbound_buffered_amount() > MAX_WS_OUTBOUND_BYTES:
		peer.close()
		return false
	return peer.send_text(JSON.stringify({"type": kind, "roomId": room_code, "senderId": "host", "payload": payload})) == OK

func send_to_player(player_id: String, kind: String, payload: Dictionary) -> void:
	for item in ws_clients:
		if bool(item.get("authenticated", false)) and str(item.player_id) == player_id:
			var peer: WebSocketPeer = item.peer
			if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
				_send_peer(peer, kind, payload)

func send_player_count(count: int) -> void:
	_broadcast("ROOM_STATE", {"playerCount": count, "phase": "LOBBY", "round": 0, "roomCode": room_code, "showMode": "showrunner_mix"})

func broadcast_event(kind: String, payload: Dictionary) -> void:
	_broadcast(kind, payload)

func _broadcast(kind: String, payload: Dictionary) -> void:
	for item in ws_clients:
		var peer: WebSocketPeer = item.peer
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN and bool(item.get("authenticated", false)):
			_send_peer(peer, kind, payload)
