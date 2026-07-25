shader_type spatial;

render_mode unshaded, cull_disabled;

uniform vec4 color_bottom : source_color = vec4(1.0, 0.05, 0.0, 1.0);
uniform vec4 color_middle : source_color = vec4(1.0, 0.45, 0.0, 1.0);
uniform vec4 color_top : source_color = vec4(1.0, 1.0, 0.25, 1.0);

uniform float animation_speed : hint_range(0.0, 10.0) = 2.5;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.12;
uniform float flame_frequency : hint_range(1.0, 20.0) = 7.0;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.15;
uniform float emission_strength : hint_range(0.0, 5.0) = 1.5;


void fragment() {
	vec2 uv = UV;

	float time = TIME * animation_speed;

	// Ondulações simples subindo pela chama.
	float wave_1 = sin(uv.y * flame_frequency + time);
	float wave_2 = sin(uv.y * flame_frequency * 1.7 - time * 1.3);

	float distortion = (wave_1 + wave_2 * 0.5) * distortion_strength;

	vec2 flame_uv = uv;
	flame_uv.x += distortion * (1.0 - uv.y);

	// Deixa a chama mais estreita no topo.
	float distance_from_center = abs(flame_uv.x - 0.5);
	float flame_width = mix(0.48, 0.05, uv.y);

	float flame_shape = 1.0 - smoothstep(
		flame_width - edge_softness,
		flame_width,
		distance_from_center
	);

	// Movimento irregular na parte superior.
	float top_wave = sin(
		flame_uv.x * 18.0 +
		time * 2.0 +
		sin(time + flame_uv.x * 8.0)
	);

	float flame_height = 0.88 + top_wave * 0.08;
	float height_mask = 1.0 - smoothstep(
		flame_height - edge_softness,
		flame_height,
		flame_uv.y
	);

	float alpha = flame_shape * height_mask;

	// Gradiente de vermelho para amarelo.
	vec3 flame_color;

	if (uv.y < 0.5) {
		flame_color = mix(
			color_bottom.rgb,
			color_middle.rgb,
			uv.y * 2.0
		);
	} else {
		flame_color = mix(
			color_middle.rgb,
			color_top.rgb,
			(uv.y - 0.5) * 2.0
		);
	}

	ALBEDO = flame_color;
	EMISSION = flame_color * emission_strength;
	ALPHA = alpha;
}