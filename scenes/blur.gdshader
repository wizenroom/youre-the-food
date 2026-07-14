shader_type canvas_item;

// Drop on a fullscreen ColorRect (CanvasLayer). Needs a BackBufferCopy
// sibling above it if the screen looks black.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float blur_size : hint_range(0.0, 12.0) = 3.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE * blur_size;

	vec3 blur = vec3(0.0);
	float total = 0.0;

	// 5x5 soft kernel
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float w = 1.0 / (1.0 + float(abs(x) + abs(y)));
			blur += texture(screen_texture, uv + px * vec2(float(x), float(y))).rgb * w;
			total += w;
		}
	}
	blur /= total;

	vec3 sharp = texture(screen_texture, uv).rgb;
	COLOR = vec4(mix(sharp, blur, strength), 1.0);
}
