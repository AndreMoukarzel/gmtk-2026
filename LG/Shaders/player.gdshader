shader_type spatial;

render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.1, 0.7, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform float pulse_strength : hint_range(0.0, 0.15) = 0.035;
uniform float color_speed : hint_range(0.0, 5.0) = 1.2;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.35;

void vertex() {
	// Pulsação leve, como uma gelatina
	float pulse = sin(TIME * pulse_speed + VERTEX.y * 3.0);
	
	VERTEX += NORMAL * pulse * pulse_strength;
}

void fragment() {
	// Variação suave de cor ao longo da cápsula
	float wave = sin(
		TIME * color_speed +
		VERTEX.y * 4.0 +
		VERTEX.x * 2.0
	) * 0.5 + 0.5;

	vec3 secondary_color = vec3(
		base_color.b,
		base_color.r,
		base_color.g
	);

	vec3 final_color = mix(
		base_color.rgb,
		secondary_color,
		wave * 0.45
	);

	ALBEDO = final_color;

	// Aparência plástica e brilhante
	ROUGHNESS = 0.25;
	METALLIC = 0.05;
	SPECULAR = 0.65;

	// Brilho sutil
	EMISSION = final_color * emission_strength;
}