shader_type canvas_item;
// The sea: a flat plane with slow moving glints, a brighter path under the sun, swell lines
// that thin toward the horizon, and a haze fade into the sky along its top edge. The
// vertical position comes from the polygon's own coordinates (top_y to bottom_y), set by
// sea.gd, so it does not depend on UVs.

uniform vec4 deep_color : source_color = vec4(0.10, 0.20, 0.29, 1.0);
uniform vec4 glint_color : source_color = vec4(0.90, 0.78, 0.60, 1.0);
uniform vec4 haze_color : source_color = vec4(0.9, 0.8, 0.7, 1.0);
uniform float sun_x = 0.76;
uniform float glint_strength = 0.55;
uniform float saturation = 1.0;
uniform float top_y = 700.0;
uniform float bottom_y = 884.0;
uniform float left_x = -3000.0;
uniform float right_x = 9000.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float v = clamp((local_pos.y - top_y) / max(bottom_y - top_y, 1.0), 0.0, 1.0);
	float u = (local_pos.x - left_x) / max(right_x - left_x, 1.0);
	// Perspective: rows get denser toward the horizon.
	float depth = pow(v, 0.6);
	float rows = depth * 46.0;
	// Glitter: three incommensurate sines whose product peaks rarely, so the light breaks
	// into short sparkles instead of bands; denser toward the horizon and under the sun.
	// Stretched sideways (the water's glitter is wider than it is tall) and denser under the sun.
	float a = sin(u * 700.0 + rows * 11.0 + TIME * 1.1);
	float b = sin(u * 430.0 - rows * 7.0 - TIME * 0.7);
	float c = sin(u * 950.0 + rows * 23.0 + TIME * 0.4);
	float glint = smoothstep(0.90, 1.0, a * b * c);
	float fade = 1.0 - smoothstep(0.0, 0.8, v);
	// The sun's path on the water, in screen space so it sits under the sky's sun.
	float path = exp(-pow((SCREEN_UV.x - sun_x) * 4.0, 2.0)) * (1.0 - smoothstep(0.0, 0.95, v));
	float path_wide = exp(-pow((SCREEN_UV.x - sun_x) * 1.6, 2.0));
	glint *= 0.25 + 0.75 * path_wide;
	// Swell lines: only some rows carry one, each broken along its length, so the water
	// does not read as ruled paper.
	float row_phase = depth * 90.0 - TIME * 0.35;
	float row_id = floor(row_phase / 6.2832);
	float row_on = step(0.62, fract(sin(row_id * 12.9898) * 43758.5453));
	float row_break = 0.5 + 0.5 * sin(u * 140.0 + row_id * 3.1);
	float swell = smoothstep(0.986, 1.0, sin(row_phase + sin(u * 300.0 + depth * 9.0) * 0.25)) * row_on * row_break * smoothstep(0.03, 0.4, v) * 0.06;
	// Foam at the waterline.
	float foam = smoothstep(0.965, 1.0, v) * (0.35 + 0.25 * sin(u * 900.0 + TIME * 1.3));
	vec3 col = mix(deep_color.rgb, glint_color.rgb, clamp(glint * fade * glint_strength + path * glint * 1.2 + path * 0.16 * glint_strength + swell + foam * 0.5, 0.0, 1.0));
	// The water reflects the sky: the horizon colour bleeds down and fades toward the shore.
	col = mix(col, haze_color.rgb, (1.0 - v) * (1.0 - v) * 0.38);
	col = mix(haze_color.rgb, col, smoothstep(0.0, 0.12, v) * 0.85 + 0.15);
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(g), col, saturation);
	COLOR = vec4(col, 1.0);
}
