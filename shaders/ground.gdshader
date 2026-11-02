shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 asphalt_color : source_color = vec3(0.082, 0.09, 0.106); // #15171B
uniform vec3 road_line_color : source_color = vec3(0.45, 0.42, 0.35);
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
	vec2 p = v_world_pos.xz;
	vec2 cell = p / road_grid_size;
	vec2 id = floor(cell);
	vec2 f = abs(fract(cell) - 0.5) * road_grid_size;

	// Deteksi jalur jalan
	float is_road_x = step(f.x, road_width * 0.5);
	float is_road_z = step(f.y, road_width * 0.5);
	float is_road = max(is_road_x, is_road_z);

	// Garis marka jalan tipis
	float line_x = step(abs(f.x), 0.4) * is_road_z;
	float line_z = step(abs(f.y), 0.4) * is_road_x;
	float road_line = max(line_x, line_z);

	// Titik lampu jalan oranye acak di sepanjang persimpangan jalan
	float r = hash21(id);
	float is_light = step(r, light_density) * step(length(f), 3.5) * is_road;

	vec3 col = mix(asphalt_color * 0.8, asphalt_color, is_road);
	col = mix(col, road_line_color, road_line * 0.6);

	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
	EMISSION = street_light_color * 3.5 * is_light;
}
