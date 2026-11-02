shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

// ═══════════════════════════════════════════════════════════════
// GROUND LOW-POLY BRUTALIST — Flat matte asphalt, geometric roads
// Hard-edge road grid, flat color blocks, no smooth gradients
// ═══════════════════════════════════════════════════════════════

uniform vec3 asphalt_color : source_color = vec3(0.10, 0.11, 0.13);
uniform vec3 asphalt_light : source_color = vec3(0.14, 0.15, 0.17);
uniform vec3 road_line_color : source_color = vec3(0.50, 0.48, 0.40);
uniform vec3 street_light_color : source_color = vec3(1.0, 0.65, 0.25);
uniform float road_grid_size = 90.0;
uniform float road_width = 14.0;
uniform float light_density : hint_range(0.01, 0.5) = 0.08;

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// ── Flat shading: override face normal in view-space ──
	vec3 dx = dFdx(VERTEX);
	vec3 dy = dFdy(VERTEX);
	NORMAL = normalize(cross(dx, dy));

	vec2 p = v_world_pos.xz;
	vec2 cell = p / road_grid_size;
	vec2 id = floor(cell);
	vec2 f = abs(fract(cell) - 0.5) * road_grid_size;

	// Deteksi jalur jalan — hard step (no smoothstep)
	float is_road_x = step(f.x, road_width * 0.5);
	float is_road_z = step(f.y, road_width * 0.5);
	float is_road = max(is_road_x, is_road_z);

	// Garis marka jalan — tajam geometris
	float line_x = step(abs(f.x), 0.5) * is_road_z;
	float line_z = step(abs(f.y), 0.5) * is_road_x;
	float road_line = max(line_x, line_z);

	// Block beton trotoar — checkerboard kasar (2-tone flat)
	float block_tone = step(0.5, fract(hash21(id) * 3.0));

	// Lampu jalan — titik oranye acak di persimpangan
	float r = hash21(id);
	float is_light = step(r, light_density) * step(length(f), 4.0) * is_road;

	// Warna flat palette — 2 shade tanpa gradasi smooth
	vec3 ground = mix(asphalt_color, asphalt_light, block_tone * (1.0 - is_road));
	vec3 road_col = mix(asphalt_light, asphalt_color * 1.2, 0.5);
	vec3 col = mix(ground, road_col, is_road);
	col = mix(col, road_line_color, road_line * 0.65);

	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = street_light_color * 3.0 * is_light;
}
