shader_type canvas_item;

uniform float threshold = 0.5;
uniform float growth = 0.0;
uniform float trans = 0.1;

uniform float outline_size = 0.08;
uniform float vein_threshold = 0.7;
uniform float noise_scale = 0.5;
uniform float warp_strength = 1.5;
uniform float noise_speed = 1.0;

uniform vec3 outline_color = vec3(0.15, 0.20, 0.16);
uniform vec3 inside_color_1 = vec3(0.20, 0.32, 0.22);
uniform vec3 inside_color_2 = vec3(1.0, 1.0, 1.0);


vec2 random(vec2 uv){
	uv = vec2(
		dot(uv, vec2(127.1,311.7)),
		dot(uv, vec2(269.5,183.3))
	);
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);

	vec2 blur = smoothstep(0.0, 1.0, uv_fract);

	return mix(
		mix(
			dot(random(uv_index), uv_fract),
			dot(random(uv_index + vec2(1.0,0.0)), uv_fract - vec2(1.0,0.0)),
			blur.x
		),
		mix(
			dot(random(uv_index + vec2(0.0,1.0)), uv_fract - vec2(0.0,1.0)),
			dot(random(uv_index + vec2(1.0,1.0)), uv_fract - vec2(1.0,1.0)),
			blur.x
		),
		blur.y
	) + 0.5;
}


vec2 warp(vec2 uv) {
	float x = noise(uv + vec2(10.0, 20.0));
	float y = noise(uv + vec2(30.0, 40.0));

	return vec2(x, y) - 0.5;
}


void fragment() {
	vec2 p = TEXTURE_PIXEL_SIZE;

	float a = 0.0;

	a += texture(TEXTURE, UV + vec2(-p.x, -p.y)).a * 1.0;
	a += texture(TEXTURE, UV + vec2( 0.0, -p.y)).a * 2.0;
	a += texture(TEXTURE, UV + vec2( p.x, -p.y)).a * 1.0;

	a += texture(TEXTURE, UV + vec2(-p.x,  0.0)).a * 2.0;
	a += texture(TEXTURE, UV).a                    * 4.0;
	a += texture(TEXTURE, UV + vec2( p.x,  0.0)).a * 2.0;

	a += texture(TEXTURE, UV + vec2(-p.x,  p.y)).a * 1.0;
	a += texture(TEXTURE, UV + vec2( 0.0,  p.y)).a * 2.0;
	a += texture(TEXTURE, UV + vec2( p.x,  p.y)).a * 1.0;

	a /= 16.0;


	float current_threshold = max(0.0, threshold - growth);

	float outer = step(current_threshold, a);
	float inner = step(current_threshold + outline_size, a);


	vec2 noise_uv = UV / TEXTURE_PIXEL_SIZE * noise_scale;

	vec2 distortion = warp(noise_uv + TIME * 0.05);
	noise_uv += distortion * warp_strength;

	float n = noise(noise_uv + TIME * noise_speed);

	// Make center become 0, edges become 1
	n = abs(n * 2.0 - 1.0);

	// Create two-color patches
	n = step(vein_threshold, n);


	vec3 inside = mix(inside_color_1, inside_color_2, n);

	vec3 rgb = mix(outline_color, inside, inner);


	COLOR = vec4(rgb, outer * trans);
}