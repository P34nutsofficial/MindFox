extends Control

var _effects: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
const FLIGHT_SECONDS := 0.62
const EFFECT_SECONDS := 3.2
const SPARK_COLORS := [Color("fff2a6"), Color("ffcf52"), Color("ff844e"), Color("ff62b7"), Color("8cf7ff"), Color("ffffff"), Color("b89bff")]

func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func launch(attacker_name: String, avatar_texture: Texture2D) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x < 20.0 or viewport_size.y < 20.0:
		return
	var target := viewport_size * Vector2(_rng.randf_range(0.39, 0.61), _rng.randf_range(0.34, 0.52))
	var start := viewport_size * Vector2(_rng.randf_range(0.72, 0.90), _rng.randf_range(0.72, 0.88))
	var sparks: Array[Dictionary] = []
	for index in range(112):
		var angle: float
		var speed: float
		if index < 82:
			angle = _rng.randf_range(-PI * 0.94, -PI * 0.06)
			speed = _rng.randf_range(210.0, 620.0)
		else:
			angle = _rng.randf_range(0.0, TAU)
			speed = _rng.randf_range(120.0, 390.0)
		var color: Color = SPARK_COLORS[_rng.randi_range(0, SPARK_COLORS.size() - 1)]
		sparks.append({
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"delay": _rng.randf_range(0.0, 0.13),
			"life": _rng.randf_range(0.72, 1.48),
			"size": _rng.randf_range(2.0, 5.2),
			"color": color
		})
	if _effects.size() >= 18:
		_effects.pop_front()
	_effects.append({
		"elapsed": 0.0,
		"start": start,
		"target": target,
		"name": attacker_name.left(18),
		"texture": avatar_texture,
		"sparks": sparks
	})
	queue_redraw()

func _process(delta: float) -> void:
	if _effects.is_empty():
		return
	for index in range(_effects.size() - 1, -1, -1):
		var effect: Dictionary = _effects[index]
		effect.elapsed = float(effect.get("elapsed", 0.0)) + delta
		if float(effect.elapsed) >= EFFECT_SECONDS:
			_effects.remove_at(index)
	queue_redraw()

func _draw() -> void:
	if _effects.is_empty():
		return
	var view_size := size
	for effect_index in range(_effects.size()):
		var effect: Dictionary = _effects[effect_index]
		var elapsed := float(effect.get("elapsed", 0.0))
		var start: Vector2 = effect.get("start", Vector2.ZERO)
		var target: Vector2 = effect.get("target", view_size * 0.5)
		var marker_pos := Vector2(14.0 + float(effect_index % 5) * 74.0, 168.0 + float(effect_index / 5) * 72.0)
		_draw_attacker_marker(marker_pos, str(effect.get("name", "Spieler")), effect.get("texture"), elapsed)
		if elapsed < FLIGHT_SECONDS:
			var progress := clampf(elapsed / FLIGHT_SECONDS, 0.0, 1.0)
			var eased := progress * progress * (3.0 - 2.0 * progress)
			var rocket_pos := start.lerp(target, eased)
			var direction := (target - start).normalized()
			_draw_rocket(rocket_pos, direction, 1.0 - progress * 0.35)
		else:
			var burst_age := elapsed - FLIGHT_SECONDS
			if burst_age < 0.34:
				var flash_alpha := clampf(1.0 - burst_age / 0.34, 0.0, 1.0)
				draw_circle(target, 105.0 * (1.0 + burst_age * 1.8), Color(1.0, 0.76, 0.27, flash_alpha * 0.17))
				draw_circle(target, 50.0 * (1.0 + burst_age * 1.2), Color(1.0, 0.93, 0.62, flash_alpha * 0.50))
			var sparks: Array = effect.get("sparks", [])
			for spark in sparks:
				var spark_age := burst_age - float(spark.get("delay", 0.0))
				var life := float(spark.get("life", 1.0))
				if spark_age < 0.0 or spark_age >= life:
					continue
				var velocity: Vector2 = spark.get("velocity", Vector2.ZERO)
				var pos := target + velocity * spark_age + Vector2(0.0, 285.0 * spark_age * spark_age)
				var tail_pos := pos - velocity.normalized() * minf(22.0, velocity.length() * 0.045)
				var fade := 1.0 - spark_age / life
				var source_color: Color = spark.get("color", Color.WHITE)
				var spark_color := Color(source_color.r, source_color.g, source_color.b, fade)
				draw_line(tail_pos, pos, Color(source_color.r, source_color.g, source_color.b, fade * 0.64), 2.8, true)
				draw_circle(pos, float(spark.get("size", 3.0)) * (0.55 + fade * 0.6), spark_color)

func _draw_attacker_marker(origin: Vector2, attacker_name: String, avatar_texture: Variant, elapsed: float) -> void:
	var pulse := 0.72 + 0.28 * sin(elapsed * 13.0)
	var rect := Rect2(origin, Vector2(66.0, 66.0))
	draw_rect(Rect2(origin - Vector2(5.0, 5.0), Vector2(76.0, 76.0)), Color(1.0, 0.78, 0.20, 0.16 * pulse), true)
	draw_rect(rect, Color("10172e"), true)
	if avatar_texture is Texture2D:
		draw_texture_rect(avatar_texture, Rect2(origin + Vector2(5.0, 5.0), Vector2(56.0, 56.0)), false, Color(1.0, 1.0, 1.0, pulse))
	draw_rect(rect, Color(1.0, 0.81, 0.25, pulse), false, 3.0, true)
	var font := get_theme_default_font()
	if font != null:
		draw_string(font, origin + Vector2(0.0, 82.0), "RAKETE · " + attacker_name.left(7).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 66.0, 9, Color(1.0, 0.91, 0.59, pulse))

func _draw_rocket(position: Vector2, direction: Vector2, alpha: float) -> void:
	var side := Vector2(-direction.y, direction.x)
	draw_line(position - direction * 78.0, position - direction * 15.0, Color(1.0, 0.48, 0.10, 0.62 * alpha), 13.0, true)
	draw_line(position - direction * 82.0, position - direction * 18.0, Color(1.0, 0.91, 0.50, 0.90 * alpha), 5.0, true)
	var body := PackedVector2Array([
		position + direction * 19.0,
		position + direction * 4.0 + side * 8.0,
		position - direction * 16.0 + side * 6.0,
		position - direction * 16.0 - side * 6.0,
		position + direction * 4.0 - side * 8.0
	])
	draw_colored_polygon(body, Color(0.96, 0.96, 1.0, alpha))
	draw_colored_polygon(PackedVector2Array([position - direction * 11.0 + side * 6.0, position - direction * 28.0 + side * 15.0, position - direction * 20.0]), Color(1.0, 0.38, 0.16, alpha))
	draw_colored_polygon(PackedVector2Array([position - direction * 11.0 - side * 6.0, position - direction * 28.0 - side * 15.0, position - direction * 20.0]), Color(1.0, 0.38, 0.16, alpha))
	draw_circle(position + direction * 4.0, 3.2, Color(0.25, 0.85, 1.0, alpha))
