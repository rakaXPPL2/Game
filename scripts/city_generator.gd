@tool
extends Node3D
class_name CityGenerator

## city_generator.gd — Generator kota padat MultiMesh ber-chunk dengan LOD

@export var seed_value: int = 20260:
	set(v):
		seed_value = v
		if Engine.is_editor_hint():
			generate()

@export var area_x_min: float = -1600.0
@export var area_x_max: float = 1600.0
@export var area_z_min: float = -3000.0
@export var area_z_max: float = 200.0
@export var chunk_size: float = 256.0

@export var block_min_size: float = 70.0
@export var block_max_size: float = 110.0
@export var street_width: float = 16.0
@export var avenue_width: float = 32.0

@export var sprawl_material: Material
@export var mid_tower_material: Material
@export var horizon_material: Material

# Tombol generate di editor untuk Godot 4.4+
@export_tool_button("Regenerate City")
var generate_action = generate

# Daftar footprint menara hero yang harus dihindari (posisi xz, radius)
var hero_obstacles: Array[Vector3] = [
	Vector3(-118.0, -80.0, 90.0),   # H_FG_Left
	Vector3(118.0, -100.0, 85.0),   # H_FG_Right
	Vector3(-235.0, -500.0, 110.0), # H_Mid_Left
	Vector3(-68.0, -800.0, 60.0),   # H_Slim_Center
	Vector3(120.0, -400.0, 65.0),   # H_Glass_Black
	Vector3(360.0, -650.0, 90.0),   # H_Mid_Right
	Vector3(-420.0, -1300.0, 85.0), # H_Far_1
	Vector3(-180.0, -1600.0, 75.0), # H_Far_2
	Vector3(40.0, -1800.0, 80.0),   # H_Far_3
	Vector3(260.0, -1500.0, 80.0),  # H_Far_4
	Vector3(-310.0, -1950.0, 90.0), # H_Far_5
]

var _unit_box: BoxMesh

func _ready() -> void:
	if not sprawl_material:
		sprawl_material = load("res://environment/facade_sprawl.tres")
	if not mid_tower_material:
		mid_tower_material = load("res://environment/facade_tower.tres")
	if not horizon_material:
		horizon_material = load("res://environment/facade_far.tres")
	generate()

func generate() -> void:
	# Bersihkan node hasil generasi lama
	for c in get_children():
		c.queue_free()

	if not sprawl_material:
		sprawl_material = load("res://environment/facade_sprawl.tres")
	if not mid_tower_material:
		mid_tower_material = load("res://environment/facade_tower.tres")
	if not horizon_material:
		horizon_material = load("res://environment/facade_far.tres")

	_unit_box = BoxMesh.new()
	_unit_box.size = Vector3(1.0, 1.0, 1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.0015
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# Struktur data chunk: Vector2i -> Array[Transform3D] dan Array[Color]
	var sprawl_chunks: Dictionary = {}
	var mid_chunks: Dictionary = {}
	var roof_chunks: Dictionary = {}

	var total_sprawl: int = 0
	var total_mid: int = 0

	# Buat grid blok kota
	var z: float = area_z_min
	var block_idx_z: int = 0

	while z < area_z_max:
		var block_d: float = rng.randf_range(block_min_size, block_max_size)
		var road_d: float = avenue_width if (block_idx_z % 5 == 0) else street_width
		
		var x: float = area_x_min
		var block_idx_x: int = 0
		
		while x < area_x_max:
			var block_w: float = rng.randf_range(block_min_size, block_max_size)
			var road_w: float = avenue_width if (block_idx_x % 5 == 0) else street_width

			var bx: float = x + block_w * 0.5
			var bz: float = z + block_d * 0.5

			# Periksa rintangan menara hero & zona balkon RefCam
			if not _is_blocked(bx, bz):
				# Bagi blok menjadi 2 - 4 lot untuk mencapai kepadatan perkotaan tinggi
				var lots_u: int = 3 if block_w > 90.0 else 2
				var lots_v: int = 3 if block_d > 90.0 else 2

				var lot_w: float = (block_w - 3.0 * float(lots_u - 1)) / float(lots_u)
				var lot_d: float = (block_d - 3.0 * float(lots_v - 1)) / float(lots_v)

				for lu in range(lots_u):
					for lv in range(lots_v):
						var lx: float = x + float(lu) * (lot_w + 3.0) + lot_w * 0.5
						var lz: float = z + float(lv) * (lot_d + 3.0) + lot_d * 0.5

						if _is_blocked(lx, lz):
							continue

						var setback: float = rng.randf_range(1.5, 3.5)
						var bw: float = max(lot_w - setback * 2.0, 10.0)
						var bd: float = max(lot_d - setback * 2.0, 10.0)

						var n_val: float = (noise.get_noise_2d(lx, lz) + 1.0) * 0.5
						var is_mid_tower: bool = (n_val > 0.50 and rng.randf() < 0.09)

						var bh: float = 0.0
						var chunk_key := Vector2i(floori(lx / chunk_size), floori(lz / chunk_size))

						if is_mid_tower:
							bh = lerp(120.0, 260.0, pow(rng.randf(), 1.5))
							# Guard: dekat RefCam tidak boleh melebihi y=200
							var dist_to_cam: float = Vector2(lx, lz).length()
							if dist_to_cam < 300.0:
								bh = min(bh, 130.0)

							var t := Transform3D(Basis.from_scale(Vector3(bw, bh, bd)), Vector3(lx, bh * 0.5, lz))
							var custom_data := Color(rng.randf(), rng.randf(), rng.randf(), 0.0)
							
							_append_instance(mid_chunks, chunk_key, t, custom_data)
							total_mid += 1

							# Detail atap mid-tower (tangki / antena)
							if rng.randf() < 0.7:
								var tw: float = bw * rng.randf_range(0.2, 0.45)
								var th: float = rng.randf_range(8.0, 24.0)
								var tt := Transform3D(Basis.from_scale(Vector3(tw, th, tw)), Vector3(lx, bh + th * 0.5, lz))
								_append_instance(roof_chunks, chunk_key, tt, custom_data)
						else:
							bh = lerp(18.0, 95.0, pow(rng.randf(), 2.2))
							var t := Transform3D(Basis.from_scale(Vector3(bw, bh, bd)), Vector3(lx, bh * 0.5, lz))
							var custom_data := Color(rng.randf(), rng.randf(), rng.randf(), 0.0)
							
							_append_instance(sprawl_chunks, chunk_key, t, custom_data)
							total_sprawl += 1

			x += block_w + road_w
			block_idx_x += 1

		z += block_d + road_d
		block_idx_z += 1

	# 2. Bangun MultiMeshInstance3D untuk tiap chunk Sprawl (Shadow OFF)
	var sprawl_root := Node3D.new()
	sprawl_root.name = "SprawlChunks"
	add_child(sprawl_root)

	for key: Vector2i in sprawl_chunks.keys():
		var data: Dictionary = sprawl_chunks[key]
		var transforms: Array = data["transforms"]
		var colors: Array = data["colors"]
		if transforms.is_empty():
			continue

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Chunk_%d_%d" % [key.x, key.y]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.material_override = sprawl_material

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = _unit_box
		mm.instance_count = transforms.size()

		for i in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i])
			mm.set_instance_custom_data(i, colors[i])

		mmi.multimesh = mm
		sprawl_root.add_child(mmi)

	# 3. Bangun MultiMeshInstance3D untuk Mid-Towers (Shadow ON)
	var mid_root := Node3D.new()
	mid_root.name = "MidTowerChunks"
	add_child(mid_root)

	for key: Vector2i in mid_chunks.keys():
		var data: Dictionary = mid_chunks[key]
		var transforms: Array = data["transforms"]
		var colors: Array = data["colors"]
		if transforms.is_empty():
			continue

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "MidChunk_%d_%d" % [key.x, key.y]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mmi.material_override = mid_tower_material

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = _unit_box
		mm.instance_count = transforms.size()

		for i in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i])
			mm.set_instance_custom_data(i, colors[i])

		mmi.multimesh = mm
		mid_root.add_child(mmi)

	# 4. Detail atap (tangki / antena) dengan visibility range culling
	var roof_root := Node3D.new()
	roof_root.name = "RoofDetails"
	add_child(roof_root)

	for key: Vector2i in roof_chunks.keys():
		var data: Dictionary = roof_chunks[key]
		var transforms: Array = data["transforms"]
		var colors: Array = data["colors"]
		if transforms.is_empty():
			continue

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "RoofChunk_%d_%d" % [key.x, key.y]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = 900.0
		mmi.material_override = mid_tower_material

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = _unit_box
		mm.instance_count = transforms.size()

		for i in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i])
			mm.set_instance_custom_data(i, colors[i])

		mmi.multimesh = mm
		roof_root.add_child(mmi)

	# 5. Cincin Siluet Horizon (~800 menara jauh pada radius 3000 - 6000 m)
	_build_horizon_ring(rng)

	print("[CityGenerator] Kota selesai digenerate: %d sprawl, %d mid-towers" % [total_sprawl, total_mid])

func _build_horizon_ring(rng: RandomNumberGenerator) -> void:
	var count: int = 850
	var horizon_mmi := MultiMeshInstance3D.new()
	horizon_mmi.name = "HorizonRing"
	horizon_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	horizon_mmi.material_override = horizon_material

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _unit_box
	mm.instance_count = count

	for i in range(count):
		# Sudut ±100° dari -Z
		var angle_deg: float = rng.randf_range(-100.0, 100.0)
		var angle_rad: float = deg_to_rad(angle_deg - 90.0) # -Z adalah arah utama
		var radius: float = rng.randf_range(3000.0, 6200.0)

		var hx: float = cos(angle_rad) * radius
		var hz: float = sin(angle_rad) * radius - 200.0

		var hw: float = rng.randf_range(80.0, 220.0)
		var hd: float = rng.randf_range(80.0, 220.0)
		var hh: float = rng.randf_range(160.0, 420.0)

		var t := Transform3D(Basis.from_scale(Vector3(hw, hh, hd)), Vector3(hx, hh * 0.5, hz))
		var custom_data := Color(rng.randf(), 0.0, rng.randf(), 0.0)

		mm.set_instance_transform(i, t)
		mm.set_instance_custom_data(i, custom_data)

	horizon_mmi.multimesh = mm
	add_child(horizon_mmi)

func _is_blocked(x: float, z: float) -> bool:
	# 1. Hindari radius 250m dari RefCam (0,0) di bidang XZ
	if Vector2(x, z).length() < 240.0:
		return true

	# 2. Hindari footprint hero towers (+margin)
	for obs in hero_obstacles:
		var dist_sq: float = (x - obs.x) * (x - obs.x) + (z - obs.y) * (z - obs.y)
		if dist_sq < (obs.z * obs.z):
			return true

	return false

func _append_instance(dict: Dictionary, key: Vector2i, t: Transform3D, c: Color) -> void:
	if not dict.has(key):
		dict[key] = {
			"transforms": [],
			"colors": []
		}
	dict[key]["transforms"].append(t)
	dict[key]["colors"].append(c)
