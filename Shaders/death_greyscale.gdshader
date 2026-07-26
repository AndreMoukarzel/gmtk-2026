shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = textureLod(screen_texture, SCREEN_UV, 0.0);
	float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(color.rgb, vec3(grey), intensity), color.a);
}
