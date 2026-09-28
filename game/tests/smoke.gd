extends SceneTree
## Headless smoke test. Run from the repository root with:
##   bin/Godot_v4.7.2-stable_win64_console.exe --headless --path game -s res://tests/smoke.gd
## Exit code 0 means the main scene instantiates and its script runs.

func _init() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		push_error("main.tscn failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null or scene.get_script() == null:
		push_error("main scene did not instantiate with its script")
		quit(1)
		return
	print("smoke: main scene instantiated (%s)" % scene.get("VERSION"))
	scene.free()
	quit(0)
