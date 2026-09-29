extends Polygon2D
## Gives the sea shader the polygon's own bounds, so its horizon fade, rows and foam sit
## where the polygon sits, whatever the UVs.


func _ready() -> void:
	var mat := material as ShaderMaterial
	if mat == null or polygon.is_empty():
		return
	var top := INF
	var bottom := -INF
	var left := INF
	var right := -INF
	for p in polygon:
		top = minf(top, p.y)
		bottom = maxf(bottom, p.y)
		left = minf(left, p.x)
		right = maxf(right, p.x)
	# Each sea gets its own material so scenes do not share bounds.
	mat = mat.duplicate()
	material = mat
	mat.set_shader_parameter("top_y", top)
	mat.set_shader_parameter("bottom_y", bottom)
	mat.set_shader_parameter("left_x", left)
	mat.set_shader_parameter("right_x", right)
