shader_type spatial;

render_mode unshaded, blend_add, cull_disabled, depth_draw_opaque;

uniform vec3 outline_color : source_color = vec3(0.35, 0.7, 1.0);
uniform float fresnel_power : hint_range(0.5, 8.0) = 1.4;
uniform float emission_strength : hint_range(0.0, 40.0) = 18.0;
uniform float rim_floor : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);
	fresnel = max(fresnel, rim_floor * (1.0 - ndotv));
	fresnel = clamp(fresnel, 0.0, 1.0);

	ALBEDO = outline_color * fresnel;
	EMISSION = outline_color * fresnel * emission_strength;
}
