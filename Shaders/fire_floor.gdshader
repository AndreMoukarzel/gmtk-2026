shader_type spatial;

render_mode unshaded, cull_disabled;

uniform vec4 color_bottom : source_color = vec4(0.9, 0.03, 0.0, 1.0);
uniform vec4 color_middle : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform vec4 color_top : source_color = vec4(1.0, 0.9, 0.15, 1.0);

uniform float speed : hint_range(0.0, 10.0) = 2.0;
uniform float scale : hint_range(1.0, 20.0) = 6.0;
uniform float distortion : hint_range(0.0, 1.0) = 0.25;
uniform float emission_strength : hint_range(0.0, 5.0) = 1.5;


float simple_noise(vec2 position) {
	return sin(position.x) * sin(position.y);
}


void fragment() {
	vec2 uv = UV;

	float movement = TIME * speed;

	// Ondulações que sobem.
	float wave_1 = simple_noise(
		vec2(
			uv.x * scale,
			uv.y * scale - movement
		)
	);

	float wave_2 = simple_noise(
		vec2(
			uv.x * scale * 1.7 + movement * 0.4,
			uv.y * scale * 1.4 - movement * 1.3
		)
	);

	float fire_pattern = wave_1 + wave_2 * 0.5;

	// Distorção horizontal.
	float distorted_y = uv.y;
	distorted_y += fire_pattern * distortion;

	distorted_y = clamp(distorted_y, 0.0, 1.0);

	// Gradiente de baixo para cima.
	vec3 fire_color;

	if (distorted_y < 0.5) {
		fire_color = mix(
			color_bottom.rgb,
			color_middle.rgb,
			distorted_y * 2.0
		);
	} else {
		fire_color = mix(
			color_middle.rgb,
			color_top.rgb,
			(distorted_y - 0.5) * 2.0
		);
	}

	// Pontos mais claros dentro do fogo.
	float brightness = fire_pattern * 0.15;
	fire_color += brightness;

	ALBEDO = fire_color;
	EMISSION = fire_color * emission_strength;
}