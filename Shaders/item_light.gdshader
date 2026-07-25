shader_type spatial;

uniform vec3 glow_color : source_color = vec3(0.1, 1.0, 0.3);
uniform float glow_strength : hint_range(0.0, 10.0) = 3.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

	ALBEDO = glow_color * 0.3;
	EMISSION = glow_color * glow_strength * (0.7 + pulse * 0.3);
}