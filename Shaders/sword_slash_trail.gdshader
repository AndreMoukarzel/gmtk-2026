shader_type spatial;

render_mode unshaded, cull_disabled, blend_add, depth_draw_never, depth_test_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 20.0) = 8.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float core_width : hint_range(0.01, 0.5) = 0.18;


void fragment() {
	float along = UV.x;
	float across = abs(UV.y * 2.0 - 1.0);

	float soft_edge = 1.0 - smoothstep(0.35, 1.0, across);
	float core = 1.0 - smoothstep(0.0, core_width, across);
	float head_boost = smoothstep(0.0, 0.15, along) * (1.0 - smoothstep(0.75, 1.0, along));
	float trail_soft = mix(0.35, 1.0, head_boost);

	vec3 color = mix(glow_color.rgb, core_color.rgb, core);
	float alpha = soft_edge * trail_soft * fade;

	ALBEDO = color;
	EMISSION = color * emission_strength * alpha;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
