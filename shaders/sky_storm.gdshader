shader_type sky;

// ═══════════════════════════════════════════════════════════════
// SKY LOW-POLY BRUTALIST — Banded cloud masses, hard color steps
// Awan dibuat dari FBM tapi di-quantize ke step blocks untuk
// memberi kesan flat-shaded / poster art
// ═══════════════════════════════════════════════════════════════

uniform vec3 sky_top_color : source_color = vec3(0.16, 0.18, 0.22);
uniform vec3 sky_mid_color : source_color = vec3(0.30, 0.32, 0.36);
uniform vec3 sky_horizon_color : source_color = vec3(0.62, 0.61, 0.57);
uniform vec3 cloud_dark_color : source_color = vec3(0.12, 0.13, 0.16);
uniform vec3 sun_break_color : source_color = vec3(0.90, 0.84, 0.70);
uniform float cloud_speed = 0.008;
uniform float posterize_levels = 6.0; // Quantize cloud tones ke N level

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
	for (int i = 0; i < 4; i++) { // 4 octaves (reduced from 5 for flat look)
		v += a * noise(p);
		p = rot * p * 2.04 + vec2(11.3, 7.1);
		a *= 0.5;
	}
	return v;
}

// Quantize / posterize value ke discrete steps
float posterize(float v, float levels) {
	return floor(v * levels) / levels;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = clamp(dir.y, 0.0, 1.0);

	// Awan FBM — lebih besar/kasar untuk low-poly feel
	vec2 uv = (dir.xz / max(dir.y + 0.10, 0.04)) * 0.2; // Coarser UV
	uv += vec2(TIME * cloud_speed * 0.5, TIME * cloud_speed * 0.2);

	float n1 = fbm(uv);
	float n2 = fbm(uv * 1.8 + vec2(5.2, -2.1));
	float cloud = smoothstep(0.2, 0.75, n1 * 0.6 + n2 * 0.4);

	// ── POSTERIZE cloud: hard tone steps ──
	cloud = posterize(cloud, posterize_levels);

	// ── SKY GRADIENT: step-banded, bukan smooth ──
	float band_h = posterize(h, 8.0); // 8 horizon bands
	vec3 sky_base = mix(sky_horizon_color, sky_mid_color, step(0.08, band_h));
	sky_base = mix(sky_base, sky_top_color, step(0.22, band_h));

	// Gumpalan awan gelap — flat toned
	vec3 stormy = mix(sky_base, cloud_dark_color, cloud * step(0.04, h) * 0.72);

	// Arah matahari
	vec3 sun_dir = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(-0.4, 0.55, -0.73));
	float sun_dot = max(dot(dir, sun_dir), 0.0);

	// Sun glow — posterized
	float sun_glow = pow(sun_dot, 8.0) * 0.4 + pow(sun_dot, 24.0) * 0.5;
	sun_glow = posterize(sun_glow, 5.0);
	float sun_cut = (1.0 - cloud * 0.8) * step(0.04, h);

	vec3 final_color = stormy + sun_break_color * sun_glow * sun_cut;

	if (dir.y < 0.0) {
		float gh = clamp(-dir.y * 6.0, 0.0, 1.0);
		COLOR = mix(sky_horizon_color, vec3(0.08, 0.09, 0.11), step(0.3, gh));
	} else {
		COLOR = final_color;
	}
}
