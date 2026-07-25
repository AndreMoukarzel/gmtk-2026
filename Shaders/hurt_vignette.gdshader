shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.85, 0.05, 0.08, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.5, 3.0) = 1.35;
uniform float inner_radius : hint_range(0.0, 1.5) = 0.25;


void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= 1.15;

	float dist = length(uv);
	float vignette = smoothstep(inner_radius, softness, dist);
	COLOR = vec4(tint.rgb, vignette * intensity * tint.a);
}
