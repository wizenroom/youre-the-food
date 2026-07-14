shader_type canvas_item;

uniform float threshold = 0.5;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float transparency = round(color.a);

	COLOR = vec4(1.0, 0.0, 0.0, transparency);
}