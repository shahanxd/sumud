extends Bot
## Checks the audio layer headless: every generated file loads as an AudioStreamWAV with
## the right channels and rate, loop files carry the loop flag, and every Sound method
## runs under the Dummy driver. Works with Sound as an autoload or instanced here. Run:
##   godot --headless --path game res://tests/test_audio.tscn -- --bot
## Pushed errors show in the process output (check.sh greps for ERROR). To have the test
## count them itself, also pass Godot's --log-file <path> and --errlog=<same path>.

## name: [channels, loop]. Mirrors assets/audio/README.md.
const FILES := {
	"strike_bang": [2, false], "ringing": [1, false], "rumble_loop": [2, true],
	"drone_hum_loop": [2, true], "wind_loop": [2, true], "sea_loop": [2, true],
	"birds_leave": [2, false], "roof_breath_loop": [2, true], "candle_out": [1, false],
	"footstep_sand_1": [1, false], "footstep_sand_2": [1, false], "footstep_sand_3": [1, false], "footstep_sand_4": [1, false],
	"footstep_concrete_1": [1, false], "footstep_concrete_2": [1, false], "footstep_concrete_3": [1, false], "footstep_concrete_4": [1, false],
	"cloth_rustle": [1, false], "paper_page": [1, false],
	"stitch_1": [1, false], "stitch_2": [1, false], "stitch_3": [1, false],
	"door_wood": [1, false], "grab": [1, false], "drop_heavy": [1, false], "kite_flap": [1, false],
}


func run() -> void:
	name_tag = "audio"
	var sound: Node = get_node_or_null("/root/Sound")
	if sound == null:
		sound = preload("res://scripts/core/sound.gd").new()
		sound.name = "Sound"
		get_parent().add_child(sound)

	# Buses.
	var all_buses := true
	for b in ["voices", "ambience", "effects", "rumble", "strike"]:
		var i := AudioServer.get_bus_index(b)
		all_buses = all_buses and i >= 0 and AudioServer.get_bus_send(i) == &"Master" and sound.buses.get(b, -1) == i
	check(all_buses, "the five buses exist, route to Master and are remembered")

	# Files.
	var formats := {}
	for name in FILES:
		var stream = load("res://assets/audio/%s.wav" % name)
		var wav := stream as AudioStreamWAV
		var want_stereo: bool = FILES[name][0] == 2
		var ok := wav != null and wav.stereo == want_stereo and wav.mix_rate == 48000 and wav.get_length() > 0.05
		check(ok, "%s.wav is an AudioStreamWAV, %s, 48000 Hz" % [name, "stereo" if want_stereo else "mono"])
		if wav != null:
			formats[wav.format] = formats.get(wav.format, 0) + 1
			if FILES[name][1]:
				var frames := int(round(wav.get_length() * wav.mix_rate))
				check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and wav.loop_begin == 0 and wav.loop_end == frames - 1,
					"%s.wav loops forward over (0, %d]" % [name, frames - 1])
	print("  info imported formats (0 8-bit, 1 16-bit, 2 IMA ADPCM, 3 QOA): ", formats)

	# One-shots.
	var p: AudioStreamPlayer = sound.play("stitch_1", "effects", -6.0, 0.05)
	check(p is AudioStreamPlayer and p.is_inside_tree() and p.stream != null and p.playing and p.bus == &"effects", "play() returns a playing one-shot on its bus")
	check(absf(p.pitch_scale - 1.0) <= 0.05 and p.pitch_scale != 1.0, "play() jitters the pitch within the range (%.3f)" % p.pitch_scale)
	# Weakrefs: a lambda that captures a node freed under it pushes an error when called.
	var wp: WeakRef = weakref(p)
	var freed := await until(func(): return wp.get_ref() == null, 120)
	check(freed, "a one-shot frees itself when finished")
	var p2: AudioStreamPlayer2D = sound.play_at("grab", Vector2(320, 40), "effects", -3.0)
	check(p2 is AudioStreamPlayer2D and p2.position == Vector2(320, 40) and p2.playing, "play_at() returns a positioned player")
	var p3: AudioStreamPlayer = sound.play("stitch_2", "no_such_bus")
	check(p3.bus == &"Master", "an unknown bus falls back to Master")

	# Loops.
	var l: AudioStreamPlayer = sound.loop("wind_loop", "ambience", -3.0, 0.1)
	var again: AudioStreamPlayer = sound.loop("wind_loop")
	check(l is AudioStreamPlayer and l.playing and l.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and again == l, "loop() starts a looping player once")
	await frames(12)
	check(is_equal_approx(l.volume_db, -3.0), "loop() fades in to its volume (%.1f)" % l.volume_db)
	sound.loop("sea_loop", "ambience", 0.0, 0.0)
	check(sound.running_loops().size() == 2, "two loops run side by side")
	sound.stop_loop("wind_loop", 0.1)
	var wl: WeakRef = weakref(l)
	var gone := await until(func(): return wl.get_ref() == null, 60)
	check(gone and sound.running_loops() == ["sea_loop"], "stop_loop() fades out and frees the player")
	sound.stop_all_loops(0.05)
	await frames(10)
	check(sound.running_loops().is_empty(), "stop_all_loops() empties the list")

	# Buses, ducking.
	var rumble := AudioServer.get_bus_index("rumble")
	var ambience := AudioServer.get_bus_index("ambience")
	var voices := AudioServer.get_bus_index("voices")
	sound.set_bus_db("rumble", -6.0)
	check(is_equal_approx(AudioServer.get_bus_volume_db(rumble), -6.0), "set_bus_db() sets the bus")
	var except: Array[String] = ["voices"]
	sound.duck(except, -80.0, 0.05)
	await frames(10)
	check(is_equal_approx(AudioServer.get_bus_volume_db(ambience), -80.0) and is_equal_approx(AudioServer.get_bus_volume_db(rumble), -80.0) and is_zero_approx(AudioServer.get_bus_volume_db(voices)), "duck() silences every bus but the one named")
	sound.unduck(0.05)
	await frames(10)
	check(is_zero_approx(AudioServer.get_bus_volume_db(ambience)) and is_equal_approx(AudioServer.get_bus_volume_db(rumble), -6.0), "unduck() restores the levels it found")
	sound.set_bus_db("rumble", 0.0)

	# Footsteps.
	var s1: AudioStreamPlayer = sound.step("sand")
	var s2: AudioStreamPlayer = sound.step("sand")
	check(s1 is AudioStreamPlayer and s1.playing and s2 == null, "step() plays a variant and rate-limits the next")
	await frames(10)
	var s3: AudioStreamPlayer = sound.step("concrete")
	check(s3 != null and String(s3.stream.resource_path).contains("footstep_concrete_"), "step(\"concrete\") picks a concrete variant after the interval")
	# Let the last players finish; quitting mid-playback reports their playbacks as leaked.
	var ws: WeakRef = weakref(s3)
	await until(func(): return ws.get_ref() == null, 120)

	# Errors, when the log is at hand.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--errlog="):
			var log := FileAccess.get_file_as_string(arg.substr(9))
			var bad := 0
			for line in log.split("\n"):
				if line.begins_with("ERROR") or line.begins_with("WARNING") or line.begins_with("SCRIPT ERROR"):
					bad += 1
			check(bad == 0, "no error or warning was pushed (%d in the log)" % bad)
	done()
