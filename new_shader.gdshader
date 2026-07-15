shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float radius : hint_range(0.0, 1.5) = 0.75;
uniform float softness : hint_range(0.001, 1.0) = 0.3;
uniform float strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;

    float d = length(uv);

    float vignette = smoothstep(radius, radius + softness, d);

    COLOR = vec4(vignette_color.rgb, vignette * strength);
}