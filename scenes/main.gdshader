shader_type canvas_item;

uniform float color_r : hint_range(0.0, 1.0, 0.1);
uniform float color_g : hint_range(0.0, 1.0, 0.1);
uniform float color_b : hint_range(0.0, 1.0, 0.1);


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = vec4(color_r,color_g,color_b,0.2);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
