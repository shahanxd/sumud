shader_type canvas_item;
// The print: a screen-space pass that makes the frame read as printed, not rendered.
// Film grain that lives in the mid-tones, a soft vignette, a hair of tone curve, a tint
// from the day's palette, and a dither so gradients never band. Kept below the scripture
// cards, which stay clean.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain = 0.05;
uniform float vignette = 0.30;
uniform float saturation = 1.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float lift = -0.015;
uniform float gain = 1.06;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// Ink misregistration: a still, low-frequency wobble of about a pixel, so vector edges
	// stop being perfectly straight and the frame reads as printed.
	vec2 wob = vec2(sin(SCREEN_UV.y * 61.0 + SCREEN_UV.x * 13.0 + 1.7), cos(SCREEN_UV.x * 53.0 - SCREEN_UV.y * 17.0)) * (0.8 / vec2(1920.0, 1080.0));
	vec3 col = texture(screen_tex, SCREEN_UV + wob).rgb;
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(g), col, saturation);
	col = clamp(col * gain + lift, 0.0, 1.0);
	col *= tint.rgb;
	vec2 q = SCREEN_UV - vec2(0.5);
	col *= 1.0 - vignette * dot(q, q) * 2.4;
	vec2 px = SCREEN_UV * vec2(1920.0, 1080.0);
	float n = hash(px + vec2(fract(TIME * 7.13) * 91.0, fract(TIME * 3.71) * 57.0)) - 0.5;
	float mids = 1.0 - abs(g * 2.0 - 1.0);
	col += n * grain * (0.35 + 0.65 * mids);
	col += (hash(px) - 0.5) * (1.5 / 255.0);
	COLOR = vec4(col, 1.0);
}
