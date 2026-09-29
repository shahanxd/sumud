shader_type canvas_item;
// The sky: a vertical gradient, one sun or moon with its glow, a haze band over the horizon,
// stars when the palette asks for them, and a touch of dither so nothing bands.
// Every uniform is set from data/palette.json by Look.

uniform vec4 top_color : source_color = vec4(0.40, 0.48, 0.66, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.98, 0.80, 0.52, 1.0);
uniform float horizon = 0.70;
uniform vec2 sun_pos = vec2(0.76, 0.42);
uniform vec4 sun_color : source_color = vec4(1.0, 0.94, 0.78, 1.0);
uniform float sun_size = 0.03;
uniform float sun_glow = 0.30;
uniform vec4 haze_color : source_color = vec4(0.9, 0.8, 0.7, 0.5);
uniform float haze_height = 0.10;
uniform float stars = 0.0;
uniform float saturation = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float t = clamp(UV.y / horizon, 0.0, 1.0);
	t = t * t * (3.0 - 2.0 * t);
	vec3 col = mix(top_color.rgb, horizon_color.rgb, t);

	// Haze resting on the horizon.
	float below = 1.0 - smoothstep(horizon - haze_height * 0.2, horizon + 0.02, UV.y);
	float above = smoothstep(horizon - haze_height * 3.0, horizon - haze_height * 0.6, UV.y);
	col = mix(col, haze_color.rgb, above * below * haze_color.a);

	// Sun or moon, aspect corrected so it stays round. Its height is a fraction of the sky
	// above the horizon, so it rides with the horizon as the camera moves.
	vec2 sp = vec2(sun_pos.x, sun_pos.y * horizon);
	vec2 d = (UV - sp) * vec2(1.7778, 1.0);
	float r = length(d);
	float disc = 1.0 - smoothstep(sun_size * 0.9, sun_size, r);
	float glow = exp(-(r * r) / (sun_glow * sun_glow * 0.18)) * 0.55;
	float halo = exp(-r / sun_glow) * 0.30;
	float sun_mix = clamp(disc + (glow + halo) * sun_color.a, 0.0, 1.0);
	col = mix(col, sun_color.rgb, sun_mix);

	// Stars, only high in the sky, each with its own slow twinkle.
	if (stars > 0.001) {
		vec2 grid = vec2(240.0, 135.0);
		vec2 cell = floor(UV * grid);
		float s = hash(cell);
		vec2 centre = (vec2(hash(cell + 1.7), hash(cell + 9.1)) - 0.5) * 0.6;
		vec2 off = (fract(UV * grid) - 0.5 - centre) * vec2(1.7778, 1.0);
		float point = 1.0 - smoothstep(0.05, 0.16, length(off));
		float star = step(1.0 - 0.10 * stars, s) * point * (1.0 - t) * (1.0 - t);
		float tw = 0.55 + 0.45 * sin(TIME * (1.0 + s * 2.0) + s * 60.0);
		col += vec3(star * tw * (0.5 + 0.5 * s));
	}

	float g = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(g), col, saturation);
	col += (hash(UV * vec2(1920.0, 1080.0) + fract(TIME)) - 0.5) * (2.0 / 255.0);
	COLOR = vec4(col, 1.0);
}
