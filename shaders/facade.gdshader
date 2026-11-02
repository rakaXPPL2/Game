shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

// ═══════════════════════════════════════════════════════════════
// FACADE LOW-POLY BRUTALIST — Flat shading, geometric windows
// Desain: Faceted concrete planes, hard shadows, flat color blocks
// Menggunakan dFdx/dFdy(VERTEX) untuk true per-face flat normals
// ═══════════════════════════════════════════════════════════════

uniform vec3 wall_color : source_color = vec3(0.55, 0.51, 0.45);
uniform vec3 wall_dark : source_color = vec3(0.35, 0.33, 0.30);
uniform vec3 glass_color : source_color = vec3(0.06, 0.08, 0.12);
uniform vec3 lit_color : source_color = vec3(1.0, 0.72, 0.32);
uniform vec2 cell_size = vec2(3.6, 4.0);
uniform float window_fill : hint_range(0.1, 0.95) = 0.55;
uniform float lit_chance : hint_range(0.0, 1.0) = 0.12;
uniform float emission_energy = 2.8;
uniform float band_every = 8.0;
uniform float fade_start = 120.0;
uniform float fade_end = 850.0;
// Low-poly panel groove control
uniform float panel_w = 7.0;
uniform float panel_h = 4.0;
uniform float groove_width = 0.018;

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
	// ── TRUE FLAT SHADING: face normal via screen-space derivatives in view-space ──
	vec3 dx = dFdx(VERTEX);
	vec3 dy = dFdy(VERTEX);
	NORMAL = normalize(cross(dx, dy));

	// World-space normal reconstructed from flat view-space NORMAL
	vec3 world_nrm = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// ── Deteksi orientasi permukaan ──
	float side = 1.0 - step(0.5, abs(world_nrm.y));
	float faces_x = step(abs(world_nrm.z), abs(world_nrm.x));
	float h = mix(v_pos.x, v_pos.z, faces_x);
	vec2 cell = vec2(h, v_pos.y) / cell_size;
	vec2 id = floor(cell);
	vec2 f = abs(fract(cell) - 0.5);

	// ── Grid jendela geometris (hard edges — low-poly style) ──
	float win = step(f.x, window_fill * 0.5) * step(f.y, window_fill * 0.5);
	float band = step(band_every - 1.0, mod(id.y, band_every));
	win *= (1.0 - band) * side;

	// ── Panel precast grooves (geometric lines between concrete slabs) ──
	vec2 panel_grid = abs(fract(vec2(h / panel_w, v_pos.y / panel_h)) - 0.5);
	float panel_seam = step(panel_grid.x, groove_width) + step(panel_grid.y, groove_width);
	panel_seam = clamp(panel_seam, 0.0, 1.0) * side;

	// ── Jendela lit (menyala) ──
	float face_seed = dot(floor(world_nrm * 1.5 + 0.5), vec3(1.0, 7.0, 13.0));
	float r = hash21(id + vec2(face_seed + v_inst.z * 31.0, v_inst.z * 17.0));
	float lit = step(r, lit_chance * (0.6 + v_inst.y)) * win;

	// ── Distance fade (anti-moire) ──
	float dist = length(VERTEX);
	float fade = smoothstep(fade_start, fade_end, dist);
	float win_vis = win * (1.0 - 0.8 * fade);

	// ── FLAT COLOR CONCRETE: 2-3 tone palette tanpa tekstur noise ──
	float tone_idx = step(0.33, v_inst.x) + step(0.66, v_inst.x);
	vec3 base = mix(wall_color, wall_dark, tone_idx * 0.35);
	float col_hash = step(0.5, hash21(vec2(floor(h / 2.0), 3.0 + v_inst.z)));
	base *= 0.92 + 0.08 * col_hash;

	// Panel seam — garis gelap tajam (not blurred)
	base = mix(base, base * 0.55, panel_seam * (1.0 - fade * 0.7));

	// Band beton struktural — warna sedikit lebih gelap
	base = mix(base, wall_dark, band * side * 0.4);

	// Atap: warna flat rata abu gelap
	float is_top = step(0.9, world_nrm.y);
	base = mix(base, wall_dark * 0.7, is_top);

	// ── Final output ──
	ALBEDO = mix(base, glass_color, win_vis);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = lit_color * emission_energy * lit * (1.0 - fade);
}
