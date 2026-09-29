extends Node
## Autoload "Notebook". Layla's notebook: the journal, the save summary and the list of
## remembered acts that becomes kites in the final sky. One JSON file per slot.
## Every entry has a day, a key, and a line in English and Arabic.

signal entry_written(entry: Dictionary)

const DEFAULT_PATH := "user://notebook.json"

var path := DEFAULT_PATH
var entries: Array = []
var current_day := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--notebook="):
			path = arg.substr(11)
	load_file()


func begin_day(day: int) -> void:
	current_day = day


## Writes one line. `key` names the act ("kite_fetched_bread"), so a second write with
## the same key on the same day replaces the first instead of doubling it.
func write(key: String, line_en: String, line_ar: String = "", extra: Dictionary = {}) -> Dictionary:
	var entry := {
		"day": current_day,
		"key": key,
		"en": line_en,
		"ar": line_ar,
	}
	for k in extra:
		entry[k] = extra[k]
	for i in entries.size():
		if entries[i].get("day") == current_day and entries[i].get("key") == key:
			entries[i] = entry
			save_file()
			entry_written.emit(entry)
			return entry
	entries.append(entry)
	save_file()
	entry_written.emit(entry)
	return entry


func has(key: String, day: int = -1) -> bool:
	for e in entries:
		if e.get("key") == key and (day < 0 or e.get("day") == day):
			return true
	return false


func day_entries(day: int) -> Array:
	var out: Array = []
	for e in entries:
		if e.get("day") == day:
			out.append(e)
	return out


## The acts of care the ending turns into kites: every entry flagged "act".
func remembered_acts() -> Array:
	var out: Array = []
	for e in entries:
		if e.get("act", false):
			out.append(e)
	return out


func clear() -> void:
	entries = []
	save_file()


func save_file() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("notebook: cannot write " + path)
		return
	file.store_string(JSON.stringify({"version": 1, "entries": entries}, "\t"))


func load_file() -> void:
	if not FileAccess.file_exists(path):
		entries = []
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		entries = []
		return
	var data = JSON.parse_string(file.get_as_text())
	entries = []
	if typeof(data) == TYPE_DICTIONARY:
		for e in data.get("entries", []):
			# JSON hands numbers back as floats; the day is an int everywhere else.
			if e is Dictionary and e.has("day"):
				e["day"] = int(e["day"])
			entries.append(e)
