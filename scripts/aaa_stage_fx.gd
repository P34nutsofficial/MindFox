extends Control
## Leichte AAA-Bühne: echte 3D-SubViewport-Objekte plus prozedurale FX.
## Auf Headless/Desktop ohne 3D-Rendering bleibt ein sicherer Ambient-Fallback aktiv.

const ORB_COLORS := [Color("63e6e2"), Color("b99cff"), Color("ffcc66"), Color("7fe2a8")]
const EMOJI_COLORS := {"🔥": Color("ff8b4d"), "🤡": Color("b99cff"), "🚀": Color("63e6e2"), "💩": Color("c89a63")}

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _blocks: Array[Node3D] = []
var _spotlight: OmniLight3D
var _orbs: Array[Dictionary] = []
var _bursts: Array[Dictionary] = []
var _flying_emojis: Array[Dictionary] = []
var _tilt := Vector2.ZERO
var _smoothed_tilt := Vector2.ZERO
var _ambient_time := 0.0
var _attention := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	for index in range(18):
		_orbs.append({
			"position": Vector2(_rng.randf_range(0.04, 0.96), _rng.randf_range(0.05, 0.95)),
			"speed": _rng.randf_range(0.008, 0.025),
			"size": _rng.randf_range(1.0, 3.5),
			"color": ORB_COLORS[index % ORB_COLORS.size()],
			"phase": _rng.randf_range(0.0, TAU)
		})
	if DisplayServer.get_name() != "headless":
		_build_3d_stage()
	queue_redraw()

func _build_3d_stage() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Ambient3DViewport"
	_viewport.size = Vector2i(720, 1280)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = false
	var container := SubViewportContainer.new()
	container.name = "Ambient3DContainer"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.modulate = Color(1.0, 1.0, 1.0, 0.24)
	container.add_child(_viewport)
	add_child(container)

	_world = Node3D.new()
	_world.name = "NeonQuestionWorld"
	_viewport.add_child(_world)
	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 0.0, 7.4)
	_camera.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	_camera.fov = 48.0
	_world.add_child(_camera)
	_camera.current = true
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.04, 0.11, 0.0)
	env.background_energy_multiplier = 0.18
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("25365b")
	env.ambient_light_energy = 0.7
	environment.environment = env
	_world.add_child(environment)
	_spotlight = OmniLight3D.new()
	_spotlight.light_color = Color("63e6e2")
	_spotlight.light_energy = 3.8
	_spotlight.omni_range = 9.0
	_spotlight.position = Vector3(0.0, 2.6, 2.0)
	_world.add_child(_spotlight)
	for index in range(7):
		var block := _make_question_block(index)
		_world.add_child(block)
		_blocks.append(block)

func _make_question_block(index: int) -> Node3D:
	var block := Node3D.new()
	block.name = "QuestionBlock_%d" % index
	block.position = Vector3(_rng.randf_range(-3.2, 3.2), _rng.randf_range(-4.3, 4.3), _rng.randf_range(-1.1, 1.8))
	block.rotation = Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.8, 0.8), _rng.randf_range(-0.4, 0.4))
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(_rng.randf_range(0.42, 0.9), _rng.randf_range(0.42, 0.9), _rng.randf_range(0.18, 0.42))
	mesh.mesh = cube
	var material := StandardMaterial3D.new()
	material.albedo_color = ORB_COLORS[index % ORB_COLORS.size()].darkened(0.38)
	material.emission_enabled = true
	material.emission = ORB_COLORS[index % ORB_COLORS.size()]
	material.emission_energy_multiplier = 1.8
	material.metallic = 0.22
	material.roughness = 0.28
	mesh.material_override = material
	block.add_child(mesh)
	return block

func _process(delta: float) -> void:
	_ambient_time += delta
	var accelerometer := Input.get_accelerometer()
	var gyroscope := Input.get_gyroscope()
	var sensor := Vector2(accelerometer.x + gyroscope.y * 0.08, accelerometer.y - gyroscope.x * 0.08)
	if sensor.length() > 0.04:
		_tilt = Vector2(clampf(sensor.x / 9.8, -1.0, 1.0), clampf(sensor.y / 9.8, -1.0, 1.0))
	else:
		_tilt = Vector2(sin(_ambient_time * 0.32) * 0.12, cos(_ambient_time * 0.24) * 0.08)
	_smoothed_tilt = _smoothed_tilt.lerp(_tilt, minf(1.0, delta * 4.2))
	_attention = move_toward(_attention, 0.0, delta * 1.8)
	if _world != null:
		_world.rotation.x = _smoothed_tilt.y * 0.08
		_world.rotation.y = _smoothed_tilt.x * 0.12
		for index in range(_blocks.size()):
			var block := _blocks[index]
			block.rotation.x += delta * (0.11 + index * 0.009)
			block.rotation.y += delta * (0.16 + index * 0.013)
			block.position.y += sin(_ambient_time * 0.7 + index) * delta * 0.018
		if _spotlight != null:
			_spotlight.position.x = sin(_ambient_time * 0.42) * 2.4 + _smoothed_tilt.x * 1.4
			_spotlight.position.y = 2.4 + cos(_ambient_time * 0.36) * 0.8 + _smoothed_tilt.y * 1.2
			_spotlight.light_energy = 3.8 + _attention * 2.5
	for burst in _bursts:
		burst.life = float(burst.life) - delta
		burst.radius = float(burst.radius) + delta * 160.0
	for emoji in _flying_emojis:
		emoji.life = float(emoji.life) - delta
		emoji.position = Vector2(emoji.position).lerp(emoji.target, delta * 3.2)
	_bursts = _bursts.filter(func(item: Dictionary) -> bool: return float(item.life) > 0.0)
	_flying_emojis = _flying_emojis.filter(func(item: Dictionary) -> bool: return float(item.life) > 0.0)
	queue_redraw()

func pulse_attention() -> void:
	_attention = 1.0

func emit_burst(position: Vector2, color: Color = Color("ffcc66"), amount: int = 18) -> void:
	for index in range(amount):
		_bursts.append({
			"position": position,
			"velocity": Vector2.from_angle(float(index) / float(maxi(1, amount)) * TAU) * _rng.randf_range(30.0, 100.0),
			"life": _rng.randf_range(0.45, 0.9),
			"radius": _rng.randf_range(1.0, 3.0),
			"color": color
		})
	_attention = 1.0

func launch_emoji(emoji: String) -> void:
	var color: Color = EMOJI_COLORS.get(emoji, Color("63e6e2"))
	_flying_emojis.append({
		"emoji": emoji,
		"position": Vector2(size.x * 0.5, size.y - 70.0),
		"target": Vector2(_rng.randf_range(size.x * 0.12, size.x * 0.88), size.y * 0.22),
		"life": 1.4,
		"color": color,
		"phase": _rng.randf_range(0.0, TAU)
	})
	emit_burst(Vector2(size.x * 0.5, size.y - 70.0), color, 8)

func _draw() -> void:
	var viewport_size := size
	for orb in _orbs:
		var base := Vector2(orb.position.x * viewport_size.x, orb.position.y * viewport_size.y)
		base += _smoothed_tilt * Vector2(22.0, -18.0)
		base.y += sin(_ambient_time * float(orb.speed) * 25.0 + float(orb.phase)) * 8.0
		var color: Color = orb.color
		draw_circle(base, float(orb.size) * 5.0, Color(color, 0.025))
		draw_circle(base, float(orb.size) * 2.2, Color(color, 0.11))
		draw_circle(base, float(orb.size), Color(color, 0.74))
	for burst in _bursts:
		var progress := 1.0 - clampf(float(burst.life) / 0.9, 0.0, 1.0)
		var position: Vector2 = burst.position + burst.velocity * progress
		var color: Color = burst.color
		draw_circle(position, float(burst.radius) * 3.0, Color(color, 0.08 * (1.0 - progress)))
		draw_circle(position, float(burst.radius), Color(color, 0.8 * (1.0 - progress)))
	for emoji in _flying_emojis:
		var color: Color = emoji.color
		var position: Vector2 = emoji.position
		draw_circle(position, 28.0, Color(color, 0.12))
		draw_string(ThemeDB.fallback_font, position + Vector2(-13.0, 11.0), str(emoji.emoji), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	if _attention > 0.0:
		draw_arc(Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5), minf(viewport_size.x, viewport_size.y) * 0.42, 0.0, TAU, 64, Color(1.0, 0.35, 0.45, _attention * 0.08), 16.0)
