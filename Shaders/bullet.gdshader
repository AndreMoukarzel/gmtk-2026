shader_type spatial;

render_mode unshaded, cull_disabled;

// Cores
uniform vec4 dark_color : source_color = vec4(0.25, 0.005, 0.0, 1.0);
uniform vec4 lava_color : source_color = vec4(1.0, 0.08, 0.0, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.85, 0.05, 1.0);

// Aparência
uniform float emission_strength : hint_range(0.0, 10.0) = 4.0;
uniform float lava_scale : hint_range(1.0, 30.0) = 8.0;
uniform float movement_speed : hint_range(0.0, 10.0) = 3.0;
uniform float edge_glow : hint_range(0.0, 5.0) = 1.5;


// Ruído simples e leve
float random(vec2 position) {
	return fract(
		sin(dot(position, vec2(12.9898, 78.233))) * 43758.5453
	);
}


float noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	local_position = local_position * local_position
		* (3.0 - 2.0 * local_position);

	float bottom_left = random(cell);
	float bottom_right = random(cell + vec2(1.0, 0.0));
	float top_left = random(cell + vec2(0.0, 1.0));
	float top_right = random(cell + vec2(1.0, 1.0));

	return mix(
		mix(bottom_left, bottom_right, local_position.x),
		mix(top_left, top_right, local_position.x),
		local_position.y
	);
}


void fragment() {
	vec2 moving_uv = UV * lava_scale;

	// Faz a lava escorrer horizontalmente pelo projétil
	moving_uv.x -= TIME * movement_speed;

	// Duas camadas de ruído para dar aparência orgânica
	float noise_1 = noise(moving_uv);
	float noise_2 = noise(
		moving_uv * 2.0
		+ vec2(TIME * 0.7, -TIME * 0.4)
	);

	float lava_pattern = noise_1 * 0.7 + noise_2 * 0.3;

	// Áreas escuras, vermelhas e amarelas
	vec3 final_color = mix(
		dark_color.rgb,
		lava_color.rgb,
		smoothstep(0.25, 0.60, lava_pattern)
	);

	final_color = mix(
		final_color,
		hot_color.rgb,
		smoothstep(0.62, 0.85, lava_pattern)
	);

	// Brilho nas bordas da mesh
	float fresnel = pow(
		1.0 - max(dot(NORMAL, VIEW), 0.0),
		2.0
	);

	final_color += lava_color.rgb * fresnel * edge_glow;

	ALBEDO = final_color;
	EMISSION = final_color * emission_strength;
}