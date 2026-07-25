shader_type spatial;

render_mode blend_add, depth_draw_opaque, cull_back;

uniform vec4 light_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);

uniform float glow_strength : hint_range(0.0,20.0) = 10.0;

// Fade
uniform float fade_power : hint_range(0.5,5.0) = 2.0;

// Animation
uniform float scroll_speed = 0.3;
uniform float noise_scale = 6.0;
uniform float distortion = 0.25;

//-----------------------------------------------------

float hash(vec2 p){
    p = fract(p * vec2(234.34, 543.21));
    p += dot(p, p + 34.45);
    return fract(p.x * p.y);
}

float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0,0.0));
    float c = hash(i + vec2(0.0,1.0));
    float d = hash(i + vec2(1.0,1.0));

    vec2 u = f*f*(3.0-2.0*f);

    return mix(
        mix(a,b,u.x),
        mix(c,d,u.x),
        u.y
    );
}

varying float local_y;

void vertex() {
    local_y = VERTEX.y;
}

void fragment(){

    // Assuming the cylinder extends from -1 to +1 on Y
	float h = clamp((local_y + 1.0) * 0.5, 0.0, 1.0);

	// Large-scale animated motion
	float boundary =
	    (noise(vec2(UV.x * 2.0, TIME * 0.15)) - 0.5) * 0.12 +
	    (noise(vec2(UV.x * 4.5 + 17.0, TIME * 0.28)) - 0.5) * 0.06;

	// Small ripples
	boundary += sin(UV.x * 18.0 + TIME * 2.5) * 0.015;

	// Apply the animated boundary
	float animated_h = clamp(h + boundary, 0.0, 1.0);

	float gradient = pow(1.0 - animated_h, fade_power);

    // Two scrolling noise layers
    vec2 uv1 = vec2(UV.x * noise_scale,
                    h * noise_scale - TIME * scroll_speed);

    vec2 uv2 = vec2(UV.x * noise_scale * 2.3,
                    h * noise_scale * 1.7 + TIME * scroll_speed * 0.7);

    float n =
        noise(uv1) * 0.65 +
        noise(uv2) * 0.35;

    // Irregular fade gets stronger near the top
	float dissolve = mix(
	    1.0,
	    smoothstep(0.2, 0.8, n),
	    animated_h * distortion
	);

	// Moving wisps
	float wisps = noise(vec2(
	    UV.x * noise_scale * 3.0,
	    h * noise_scale * 2.0 - TIME * scroll_speed * 2.0
	));

	dissolve *= mix(
	    1.0,
	    smoothstep(0.45, 0.75, wisps),
	    animated_h * 0.45
	);

    float alpha = gradient * dissolve;
	
	float pulse = sin(h * 24.0 - TIME * 5.0);
	pulse = pulse * 0.5 + 0.5;

	// Pulses are only visible in the upper half
	alpha += pulse * (1.0 - gradient) * 0.08;
	alpha = clamp(alpha, 0.0, 1.0);

    ALBEDO = light_color.rgb * alpha * 0.4;
    EMISSION = light_color.rgb * alpha * glow_strength;
    ALPHA = alpha;
}