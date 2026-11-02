shader_type sky;

uniform vec3 sky_top_color : source_color = vec3(0.18, 0.20, 0.24);      // awan badai gelap pekat atas
uniform vec3 sky_mid_color : source_color = vec3(0.32, 0.34, 0.38);      // lapisan awan tengah
uniform vec3 sky_horizon_color : source_color = vec3(0.65, 0.64, 0.60);  // haze cakrawala hangat pudar
uniform vec3 cloud_dark_color : source_color = vec3(0.12, 0.13, 0.16);   // gumpalan tebal gelap
uniform vec3 sun_break_color : source_color = vec3(0.92, 0.86, 0.74);    // celah cahaya hangat
uniform float cloud_speed = 0.01;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = rot * p * 2.04 + vec2(11.3, 7.1);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = clamp(dir.y, 0.0, 1.0);
	
	// Awan FBM
	vec2 uv = (dir.xz / max(dir.y + 0.10, 0.04)) * 0.3;
	uv += vec2(TIME * cloud_speed * 0.5, TIME * cloud_speed * 0.2);
	
	float n1 = fbm(uv);
	float n2 = fbm(uv * 2.2 + vec2(5.2, -2.1));
	float cloud = smoothstep(0.2, 0.8, n1 * 0.6 + n2 * 0.4);

	// Transisi cepat: cakrawala -> mid -> badai gelap pekat di atas
	vec3 sky_base = mix(sky_horizon_color, sky_mid_color, smoothstep(0.01, 0.14, h));
	sky_base = mix(sky_base, sky_top_color, smoothstep(0.12, 0.32, h));
	
	// Campur gumpalan awan badai gelap pekat
	vec3 stormy = mix(sky_base, cloud_dark_color, cloud * smoothstep(0.04, 0.25, h) * 0.75);
	
	// Arah matahari
	vec3 sun_dir = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(-0.4, 0.55, -0.73));
	float sun_dot = max(dot(dir, sun_dir), 0.0);
	
	// Celah terang terisolasi di sekitar matahari
	float sun_glow = pow(sun_dot, 8.0) * 0.45 + pow(sun_dot, 32.0) * 0.6;
	float sun_cut = (1.0 - cloud * 0.8) * smoothstep(0.04, 0.35, h);
	
	vec3 final_color = stormy + sun_break_color * sun_glow * sun_cut;

	if (dir.y < 0.0) {
		float gh = clamp(-dir.y * 6.0, 0.0, 1.0);
		COLOR = mix(sky_horizon_color, vec3(0.08, 0.09, 0.11), gh);
	} else {
		COLOR = final_color;
	}
}
