extends Node
## Sehr kleine, runtime-generierte Audio-Cues statt großer Sounddateien.
## Im Headless-Test werden die Cues sauber übersprungen.

const SAMPLE_RATE := 44100.0
var _player: AudioStreamPlayer
var _headless := false
var _last_haptic_ms := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_player = AudioStreamPlayer.new()
	_player.bus = "SFX"
	add_child(_player)

func play_cue(cue: String, pitch_scale: float = 1.0) -> void:
	if _headless or _player == null:
		return
	var profile := _profile(cue)
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = float(profile.duration) + 0.08
	_player.stream = stream
	_player.pitch_scale = clampf(pitch_scale, 0.75, 1.35)
	_player.play()
	var playback := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frame_count := int(SAMPLE_RATE * float(profile.duration))
	var frames := PackedVector2Array()
	frames.resize(frame_count)
	for index in range(frame_count):
		var time := float(index) / SAMPLE_RATE
		var envelope := _envelope(time, float(profile.duration), float(profile.attack), float(profile.release))
		var sample := _wave(time, profile, pitch_scale) * envelope * float(profile.gain)
		frames[index] = Vector2(sample, sample)
	playback.push_buffer(frames)

func haptic(milliseconds: int = 12) -> void:
	if _headless:
		return
	var now := Time.get_ticks_msec()
	if now - _last_haptic_ms < 35:
		return
	_last_haptic_ms = now
	Input.vibrate_handheld(milliseconds)

func haptic_pattern(pattern: Array) -> void:
	if _headless:
		return
	for duration in pattern:
		if duration > 0:
			Input.vibrate_handheld(duration)
		await get_tree().create_timer(0.045).timeout

func _profile(cue: String) -> Dictionary:
	match cue:
		"click": return {"duration": 0.075, "attack": 0.004, "release": 0.045, "frequency": 520.0, "frequency_2": 740.0, "gain": 0.22, "wave": "sine"}
		"tick": return {"duration": 0.09, "attack": 0.003, "release": 0.055, "frequency": 850.0, "frequency_2": 1180.0, "gain": 0.18, "wave": "square"}
		"seal": return {"duration": 0.18, "attack": 0.005, "release": 0.12, "frequency": 230.0, "frequency_2": 460.0, "gain": 0.28, "wave": "saw"}
		"whoosh": return {"duration": 0.32, "attack": 0.02, "release": 0.22, "frequency": 160.0, "frequency_2": 720.0, "gain": 0.16, "wave": "noise", "harmonics": 0.18}
		"buzzer": return {"duration": 0.28, "attack": 0.006, "release": 0.18, "frequency": 92.0, "frequency_2": 70.0, "gain": 0.29, "wave": "square", "harmonics": 0.32}
		"tension": return {"duration": 0.16, "attack": 0.01, "release": 0.1, "frequency": 92.0, "frequency_2": 128.0, "gain": 0.08, "wave": "sine", "harmonics": 0.45}
		"reward": return {"duration": 0.42, "attack": 0.008, "release": 0.25, "frequency": 440.0, "frequency_2": 880.0, "gain": 0.22, "wave": "sine", "harmonics": 0.3}
		"fanfare": return {"duration": 0.72, "attack": 0.01, "release": 0.4, "frequency": 330.0, "frequency_2": 990.0, "gain": 0.2, "wave": "sine", "harmonics": 0.42}
		_: return {"duration": 0.08, "attack": 0.004, "release": 0.05, "frequency": 440.0, "frequency_2": 550.0, "gain": 0.16, "wave": "sine"}

func _envelope(time: float, duration: float, attack: float, release: float) -> float:
	if time < attack:
		return time / maxf(0.001, attack)
	if time > duration - release:
		return clampf((duration - time) / maxf(0.001, release), 0.0, 1.0)
	return 1.0

func _wave(time: float, profile: Dictionary, pitch_scale: float) -> float:
	var progress := time / maxf(0.001, float(profile.duration))
	var frequency := lerpf(float(profile.frequency), float(profile.frequency_2), progress) * pitch_scale
	var phase := TAU * frequency * time
	match str(profile.wave):
		"square": return 1.0 if sin(phase) >= 0.0 else -1.0
		"saw": return fmod(phase / TAU, 1.0) * 2.0 - 1.0
		"noise": return sin(phase) * 0.55 + sin(phase * 2.13) * 0.25 + sin(phase * 0.37) * 0.2
		_: return (sin(phase) + sin(phase * 2.0) * float(profile.get("harmonics", 0.0)) + sin(phase * 3.0) * float(profile.get("harmonics", 0.0)) * 0.45) / (1.0 + float(profile.get("harmonics", 0.0)) * 0.7)
