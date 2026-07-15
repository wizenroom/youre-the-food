shader_type canvas_item;

// Wave texture overlay over gameplay only (this CanvasLayer sits under UI).
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D wave_tex : source_color, filter_linear, repeat_enable;

uniform float strength : hint_range(0.0, 1.0) = 0.45;
uniform float warp : hint_range(0.0, 0.03) = 0.006;
uniform float speed : hint_range(0.0, 2.0) = 0.22;
uniform float scale : hint_range(0.2, 8.0) = 1.35;
uniform float opacity : hint_range(0.0, 1.0) = 0.28;
uniform vec4 tint : source_color = vec4(0.55, 0.85, 0.95, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * speed;

	// scroll two layers so the painted texture doesn't look locked
	vec2 uv_a = uv * scale + vec2(t * 0.07, t * -0.045);
	vec2 uv_b = uv * scale * 1.35 + vec2(t * -0.05, t * 0.06);

	vec3 wave_a = texture(wave_tex, uv_a).rgb;
	vec3 wave_b = texture(wave_tex, uv_b).rgb;
	vec3 wave = mix(wave_a, wave_b, 0.45);

	// luminance drives both warp and highlight ridges
	float lum = dot(wave, vec3(0.299, 0.587, 0.114));
	float ridge = smoothstep(0.42, 0.82, lum);
	float trough = smoothstep(0.55, 0.18, lum);

	// approximate a normal from neighboring samples for soft refraction
	float px = 0.004;
	float lx = texture(wave_tex, uv_a + vec2(px, 0.0)).r
			- texture(wave_tex, uv_a - vec2(px, 0.0)).r;
	float ly = texture(wave_tex, uv_a + vec2(0.0, px)).r
			- texture(wave_tex, uv_a - vec2(0.0, px)).r;
	vec2 offset = vec2(lx, ly) * warp * strength;

	vec3 scene = texture(screen_texture, uv + offset).rgb;

	vec3 color = scene;
	// cool blue-green caustic lift on crests, slight darken in troughs
	color += tint.rgb * ridge * 0.22 * strength * opacity;
	color -= vec3(trough * 0.08 * strength * opacity);
	// faint texture wash so the painted ripples read clearly
	color = mix(color, color * mix(vec3(1.0), wave * 1.15, 0.18 * opacity * strength), 1.0);

	COLOR = vec4(color, 1.0);
}
