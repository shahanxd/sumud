shader_type canvas_item;
// Flat sea with slow moving light bands. Cheap and calm.

uniform vec4 deep_color : source_color = vec4(0.10, 0.20, 0.29, 1.0);
uniform vec4 glint_color : source_color = vec4(0.90, 0.78, 0.60, 1.0);

void fragment() {
	float rows = UV.y * 40.0;
	float w1 = sin(UV.x * 90.0 + TIME * 0.9 + rows * 1.7);
	float w2 = sin(UV.x * 37.0 - TIME * 0.5 + rows * 0.8);
	float glint = smoothstep(0.86, 1.0, w1 * 0.5 + 0.5) * smoothstep(0.3, 1.0, w2 * 0.5 + 0.5);
	float fade = 1.0 - smoothstep(0.0, 0.7, UV.y);
	COLOR = mix(deep_color, glint_color, glint * fade * 0.55);
}
