shader_type spatial;

render_mode unshaded;

uniform vec3 base_color : source_color = vec3(0.02, 0.35, 0.08);
uniform vec3 glow_color : source_color = vec3(0.15, 1.0, 0.35);

uniform float glow_strength : hint_range(0.0, 8.0) = 2.5;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 1.5;
uniform float wave_amount : hint_range(1.0, 20.0) = 6.0;


void fragment() {
	// Pulsação suave de brilho
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

	// Faixas de energia subindo pela mesh
	float wave = sin(
		UV.y * wave_amount
		- TIME * wave_speed
	) * 0.5 + 0.5;

	// Deixa as faixas mais definidas
	wave = smoothstep(0.55, 0.9, wave);

	vec3 color = mix(
		base_color,
		glow_color,
		pulse * 0.45 + wave * 0.55
	);

	ALBEDO = color;
	EMISSION = glow_color * (pulse + wave) * glow_strength;
}