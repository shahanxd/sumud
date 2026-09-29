extends CanvasLayer
## Autoload "Cards". A verse or hadith as a full stop: the beat has already put the camera
## on a non-human subject; this layer dims the frame a little, sets the Arabic clean and
## large, the translation under it and the reference under that, silences every bus, and
## holds until the player continues. Text comes only from data/scripture.csv, which is
## copied from the verified research by script and never typed.

const DATA_PATH := "res://data/scripture.csv"
const QURAN_FONT := "res://assets/fonts/amiri/AmiriQuran.ttf"
const HADITH_FONT := "res://assets/fonts/amiri/Amiri-Regular.ttf"

var entries: Dictionary = {}
var showing := false

var _dim: ColorRect
var _box: VBoxContainer
var _ar: Label
var _en: Label
var _ref: Label


func _ready() -> void:
	layer = 70
	_load()
	_build()


func _load() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var header := file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3 or row[0].is_empty():
			continue
		var entry := {}
		for i in mini(header.size(), row.size()):
			entry[header[i]] = row[i]
		entries[row[0]] = entry


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.02, 0.03, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.add_child(centre)
	_box = VBoxContainer.new()
	_box.custom_minimum_size = Vector2(1400, 0)
	_box.add_theme_constant_override("separation", 26)
	centre.add_child(_box)

	_ar = Label.new()
	_ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ar.text_direction = Control.TEXT_DIRECTION_RTL
	_ar.language = "ar"
	_ar.autowrap_mode = TextServer.AUTOWRAP_WORD
	_ar.add_theme_font_size_override("font_size", 64)
	_ar.add_theme_color_override("font_color", Color(0.97, 0.94, 0.88))
	_box.add_child(_ar)

	_en = Label.new()
	_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_en.autowrap_mode = TextServer.AUTOWRAP_WORD
	_en.add_theme_font_size_override("font_size", 30)
	_en.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8))
	_box.add_child(_en)

	_ref = Label.new()
	_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ref.add_theme_font_size_override("font_size", 22)
	_ref.add_theme_color_override("font_color", Color(0.8, 0.6, 0.45))
	_box.add_child(_ref)

	_dim.modulate.a = 0.0
	_dim.visible = false


func has(key: String) -> bool:
	return entries.has(key)


func arabic(key: String) -> String:
	return String((entries.get(key, {}) as Dictionary).get("ar", ""))


func english(key: String) -> String:
	return String((entries.get(key, {}) as Dictionary).get("en", ""))


func reference(key: String) -> String:
	var e: Dictionary = entries.get(key, {})
	var grade := String(e.get("grade", ""))
	var ref := String(e.get("reference", ""))
	if grade.is_empty() or grade == "Quran":
		return ref
	return ref + " · " + grade


## Shows the card and holds. Awaitable. The caller has already framed a non-human subject.
func show_card(key: String) -> void:
	var e: Dictionary = entries.get(key, {})
	if e.is_empty():
		push_warning("cards: no entry " + key)
		return
	while showing or Say.busy:
		await get_tree().process_frame
	showing = true
	# Nothing plays under the words: every bus to silence, restored only after the card.
	Sound.duck([], Sound.SILENT_DB, 0.4)
	var quran := String(e.get("grade", "")) == "Quran"
	var font = load(QURAN_FONT if quran else HADITH_FONT)
	if font:
		_ar.add_theme_font_override("font", font)
	_ar.text = String(e.get("ar", ""))
	_en.text = String(e.get("en", ""))
	_ref.text = reference(key)
	_dim.visible = true
	var bot := Day.bot_mode
	var tw := create_tween()
	tw.tween_property(_dim, "modulate:a", 1.0, 0.1 if bot else 0.9)
	await tw.finished
	var min_frames := 18 if bot else 240
	var max_frames := 90 if bot else 60 * 120
	for i in max_frames:
		await get_tree().physics_frame
		if i >= min_frames and Input.is_action_just_pressed("interact"):
			break
	var out := create_tween()
	out.tween_property(_dim, "modulate:a", 0.0, 0.1 if bot else 0.7)
	await out.finished
	_dim.visible = false
	Sound.unduck(1.5)
	showing = false
