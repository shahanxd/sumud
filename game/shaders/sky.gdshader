shader_type canvas_item;
// Vertical sky gradient. Colours are driven by the day phase.

uniform vec4 top_color : source_color = vec4(0.40, 0.48, 0.66, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.98, 0.80, 0.52, 1.0);
uniform float horizon = 0.70;

void fragment() {
	float t = clamp(UV.y / horizon, 0.0, 1.0);
	t = t * t * (3.0 - 2.0 * t);
	COLOR = mix(top_color, horizon_color, t);
}
