extends Node
## Autoload "Sound". Every sound the game plays goes through here: one-shots, positioned
## one-shots, looping ambience with fades, the five buses, ducking for the Quran full stop
## and footsteps. Streams are cached. Safe under the Dummy driver (headless): players are
## still created and freed, nothing is pushed. Also works instanced by a test as a child
## named "Sound". Files live in assets/audio; see the README there.

const BUSES: Array[String] = ["voices", "ambience", "effects", "rumble", "strike"]
const AUDIO_DIR := "res://assets/audio/"
const SILENT_DB := -80.0
const STEP_INTERVAL_MS := 120

## Bus name to index, filled in _ready.
var buses: Dictionary = {}

var _streams: Dictionary = {}
var _loops: Dictionary = {}
var _ducked: Dictionary = {}
var _duck_tween: Tween
var _last_step_ms := -1000
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for b in BUSES:
		var i := AudioServer.get_bus_index(b)
		if i < 0:
			i = AudioServer.bus_count
			AudioServer.add_bus(i)
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
		buses[b] = i


## One-shot on a bus. Returns the player; it frees itself when finished.
## `pitch_jitter` randomises pitch_scale by plus or minus that fraction.
func play(name: String, bus: String = "effects", volume_db: float = 0.0, pitch_jitter: float = 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	_start(p, name, bus, volume_db, pitch_jitter)
	return p


## One-shot at a world position (AudioStreamPlayer2D).
func play_at(name: String, position: Vector2, bus: String = "effects", volume_db: float = 0.0, pitch_jitter: float = 0.0) -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	p.position = position
	_start(p, name, bus, volume_db, pitch_jitter)
	return p


## Starts a looping player for `name` if one is not already running, fading in.
func loop(name: String, bus: String = "ambience", volume_db: float = 0.0, fade_in: float = 1.0) -> AudioStreamPlayer:
	if _loops.has(name) and is_instance_valid(_loops[name]):
		return _loops[name]
	var stream := _stream(name)
	if stream is AudioStreamWAV and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		# The generator flags its loops in the file; this is the fallback for a file that
		# arrives without the flag.
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	var p := AudioStreamPlayer.new()
	p.name = "loop_" + name
	p.stream = stream
	p.bus = _bus_name(bus)
	p.volume_db = SILENT_DB if fade_in > 0.0 else volume_db
	add_child(p)
	_loops[name] = p
	if stream != null:
		p.play()
	if fade_in > 0.0:
		p.create_tween().tween_property(p, "volume_db", volume_db, fade_in)
	return p


## Fades a running loop out and frees it. A new loop() with the same name starts fresh.
func stop_loop(name: String, fade_out: float = 1.0) -> void:
	if not _loops.has(name):
		return
	var p: AudioStreamPlayer = _loops[name]
	_loops.erase(name)
	if not is_instance_valid(p):
		return
	if fade_out <= 0.0:
		p.queue_free()
		return
	var tw := p.create_tween()
	tw.tween_property(p, "volume_db", SILENT_DB, fade_out)
	tw.tween_callback(p.queue_free)


func stop_all_loops(fade_out: float = 1.0) -> void:
	for name in _loops.keys():
		stop_loop(name, fade_out)


## Names of the loops currently running.
func running_loops() -> Array:
	var out: Array = []
	for name in _loops:
		if is_instance_valid(_loops[name]):
			out.append(name)
	return out


func set_bus_db(bus: String, db: float) -> void:
	var i := _bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, db)


## Lowers every bus except `except_buses` to `to_db` over `seconds`. For the Quran full
## stop: duck([], -80.0, 0.5) silences everything; unduck() restores what it found.
func duck(except_buses: Array[String], to_db: float, seconds: float) -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween().set_parallel(true)
	for b in BUSES:
		if b in except_buses:
			continue
		var i := _bus_index(b)
		if i < 0:
			continue
		if not _ducked.has(b):
			_ducked[b] = AudioServer.get_bus_volume_db(i)
		_ramp_bus(_duck_tween, i, to_db, seconds)


## Restores the levels duck() found.
func unduck(seconds: float = 1.0) -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween().set_parallel(true)
	for b in _ducked:
		var i := _bus_index(b)
		if i >= 0:
			_ramp_bus(_duck_tween, i, _ducked[b], seconds)
	_ducked.clear()


## A footstep on "sand" or "concrete": one of four variants with a little pitch jitter,
## at most one every 0.12 s. Returns the player, or null when rate-limited.
func step(surface: String) -> AudioStreamPlayer:
	var now := Time.get_ticks_msec()
	if now - _last_step_ms < STEP_INTERVAL_MS:
		return null
	_last_step_ms = now
	return play("footstep_%s_%d" % [surface, _rng.randi_range(1, 4)], "effects", -2.0, 0.06)


func _start(p: Node, name: String, bus: String, volume_db: float, pitch_jitter: float) -> void:
	var stream := _stream(name)
	p.stream = stream
	p.bus = _bus_name(bus)
	p.volume_db = volume_db
	if pitch_jitter > 0.0:
		p.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	p.finished.connect(p.queue_free)
	add_child(p)
	if stream == null:
		p.queue_free()
		return
	p.play()
	# The Dummy driver may never report finished; free on the clock as well. Bound, not
	# captured: a lambda holding a freed player would push an error when it fired.
	var life := stream.get_length() / maxf(p.pitch_scale, 0.1) + 0.5
	get_tree().create_timer(life).timeout.connect(_expire.bind(p))


func _expire(p) -> void:
	if is_instance_valid(p):
		p.queue_free()


func _ramp_bus(tw: Tween, index: int, to_db: float, seconds: float) -> void:
	if seconds <= 0.0:
		AudioServer.set_bus_volume_db(index, to_db)
		return
	var from := AudioServer.get_bus_volume_db(index)
	tw.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(index, v), from, to_db, seconds)


func _bus_index(bus: String) -> int:
	if buses.has(bus) and AudioServer.get_bus_name(buses[bus]) == bus:
		return buses[bus]
	return AudioServer.get_bus_index(bus)


func _bus_name(bus: String) -> String:
	return bus if _bus_index(bus) >= 0 else "Master"


func _stream(name: String) -> AudioStream:
	if _streams.has(name):
		return _streams[name]
	var path := AUDIO_DIR + name + ".wav"
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	else:
		push_warning("sound: missing " + path)
	_streams[name] = stream
	return stream
