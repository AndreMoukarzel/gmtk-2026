shader_type spatial;

uniform vec3 grass_light : source_color = vec3(0.18, 0.55, 0.12);
uniform vec3 grass_dark : source_color = vec3(0.035, 0.20, 0.025);
uniform float scale = 3.0;
uniform float roughness_value = 0.9;

varying vec3 world_position;

float random(vec2 position) {
	return fract(
		sin(dot(position, vec2(12.9898, 78.233))) * 43758.5453
	);
}

float noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 local_position = fract(position);

	float a = random(cell);
	float b = random(cell + vec2(1.0, 0.0));
	float c = random(cell + vec2(0.0, 1.0));
	float d = random(cell + vec2(1.0, 1.0));

	vec2 smooth_position =
		local_position * local_position * (3.0 - 2.0 * local_position);

	return mix(
		mix(a, b, smooth_position.x),
		mix(c, d, smooth_position.x),
		smooth_position.y
	);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coordinates = world_position.xz * scale;

	float large_variation = noise(coordinates * 0.25);
	float small_variation = noise(coordinates * 3.0);

	float grass_pattern =
		large_variation * 0.7 +
		small_variation * 0.3;

	ALBEDO = mix(grass_dark, grass_light, grass_pattern);
	ROUGHNESS = roughness_value;
}