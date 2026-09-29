extends CanvasLayer
## Autoload "Grade". The print pass over the whole frame (shaders/grade.gdshader): grain,
## vignette, tint and dither, with the saturation of the day's palette. It sits above the
## world and the dialogue and below the scripture cards, the notebook and the fades.

const SHADER := preload("res://shaders/grade.gdshader")

var enabled := true:
	set(v):
		enabled = v
		if _rect:
			_rect.visible = v

var _rect: ColorRect
var _mat: ShaderMaterial


func _ready() -> void:
	layer = 65
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect.material = _mat
	add_child(_rect)
	if OS.get_cmdline_user_args().has("--no-grade"):
		enabled = false


## Called by Look whenever the palette moves.
func apply(p: Dictionary) -> void:
	if _mat == null:
		return
	var sat := float(p.get("saturation", 1.0))
	_mat.set_shader_parameter("saturation", clampf(0.55 + 0.45 * sat, 0.0, 1.0))
	var tint: Color = p.get("tint", Color(1, 1, 1))
	_mat.set_shader_parameter("tint", tint)
	_mat.set_shader_parameter("grain", float(p.get("grain", 0.05)))
	_mat.set_shader_parameter("vignette", float(p.get("vignette", 0.30)))
