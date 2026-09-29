extends Node
## Autoload "Settings". The few options the prototype honours, saved to user://settings.json.
## own_pace pauses every timed beat until the player acts; photosensitive_safe softens the
## strike flash. Command line: --own-pace, --photosensitive.

const PATH := "user://settings.json"

var own_pace := false
var photosensitive_safe := false


func _ready() -> void:
	load_file()
	var args := OS.get_cmdline_user_args()
	if args.has("--own-pace"):
		own_pace = true
	if args.has("--photosensitive"):
		photosensitive_safe = true
	Fx.photosensitive_safe = photosensitive_safe


func save_file() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"own_pace": own_pace, "photosensitive_safe": photosensitive_safe}, "\t"))


func load_file() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		own_pace = bool(data.get("own_pace", false))
		photosensitive_safe = bool(data.get("photosensitive_safe", false))
