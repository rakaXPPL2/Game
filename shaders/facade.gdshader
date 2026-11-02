shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 wall_color : source_color = vec3(0.55, 0.51, 0.45);
uniform vec3 glass_color : source_color = vec3(0.04, 0.06, 0.09);
uniform vec3 lit_color : source_color = vec3(1.0, 0.70, 0.35);
uniform vec2 cell_size = vec2(3.6, 4.0);            // sel jendela (m): lebar, tinggi lantai
uniform float window_fill : hint_range(0.1, 0.95) = 0.58;
uniform float lit_chance : hint_range(0.0, 1.0) = 0.12;
uniform float emission_energy = 2.8;
uniform float band_every = 8.0;                     // tiap N lantai ada pita beton tanpa jendela
uniform float fade_start = 120.0;                   // anti-moire: jendela memudar menurut jarak
uniform float fade_end = 850.0;

varying vec3 v_pos;
varying vec3 v_nrm;
varying vec4 v_inst;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_inst = INSTANCE_CUSTOM;
}

void fragment() {
	float side = 1.0 - step(0.5, abs(v_nrm.y));                 // 1 = dinding vertikal, 0 = atap/lantai
	float faces_x = step(abs(v_nrm.z), abs(v_nrm.x));           // 1 jika dinding menghadap sumbu X
	float h = mix(v_pos.x, v_pos.z, faces_x);                   // koordinat horizontal fasad dunia
	vec2 cell = vec2(h, v_pos.y) / cell_size;
	vec2 id = floor(cell);
	vec2 f = abs(fract(cell) - 0.5);

	// Grid jendela & pita beton struktural
	float win = step(f.x, window_fill * 0.5) * step(f.y, window_fill * 0.5);
	float band = step(band_every - 1.0, mod(id.y, band_every));
	win *= (1.0 - band) * side;

	// Penentuan jendela yang menyala (lit)
	float face_seed = dot(floor(v_nrm * 1.5 + 0.5), vec3(1.0, 7.0, 13.0));
	float r = hash21(id + vec2(face_seed + v_inst.z * 31.0, v_inst.z * 17.0));
	float lit = step(r, lit_chance * (0.6 + v_inst.y)) * win;

	// Anti-moire fade dengan jarak pandang kamera
	float dist = length(VERTEX);
	float fade = smoothstep(fade_start, fade_end, dist);
	float win_vis = win * (1.0 - 0.8 * fade);

	// Tekstur beton brutalis + noda cuaca vertikal
	vec3 base = wall_color * (0.85 + 0.3 * v_inst.x);
	float streak = hash21(vec2(floor(h / 1.5), 3.0 + v_inst.z));
	base *= 0.88 + 0.12 * streak;

	ALBEDO = mix(base, glass_color, win_vis);
	ROUGHNESS = mix(0.92, 0.25, win_vis);
	SPECULAR = mix(0.2, 0.55, win_vis);
	EMISSION = lit_color * emission_energy * lit * (1.0 - fade);
}
