shader_type canvas_item;

uniform float threshold = 0.5;
uniform float growth = 0.0;
uniform float trans = 0.1;

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
	float inner = step(current_threshold + 0.08, a);

	float outline = outer - inner;
	
	vec3 rgb = mix(vec3(0.15,0.20,0.16), vec3(0.2, 0.32, 0.22), inner);

	COLOR = vec4(rgb, outer * trans);
}