@tool
extends Node3D
class_name HeroTower

## hero_tower.gd — Generator menara monolit brutalis bertingkat prosedural

enum CrownStyle { FLAT, ANTENNA, TANK, COMPLEX }
enum SignSide { FRONT, LEFT, RIGHT, NONE }

@export var footprint: Vector2 = Vector2(100.0, 100.0):
	set(v):
		footprint = v
		_request_rebuild()

@export var total_height: float = 450.0:
	set(v):
		total_height = v
		_request_rebuild()

## Setback per tier: Vector3(lebar_frac, dalam_frac, tinggi_frac)
@export var tier_fractions: Array[Vector3] = [
	Vector3(1.0, 1.0, 0.45),
	Vector3(0.85, 0.88, 0.35),
	Vector3(0.70, 0.72, 0.20)
]:
	set(v):
		tier_fractions = v
		_request_rebuild()

@export var ledges_count: int = 0:
	set(v):
		ledges_count = v
		_request_rebuild()

@export var ledge_side: SignSide = SignSide.LEFT:
	set(v):
		ledge_side = v
		_request_rebuild()

@export var crown: CrownStyle = CrownStyle.ANTENNA:
	set(v):
		crown = v
		_request_rebuild()

@export var facade_material: Material:
	set(v):
		facade_material = v
		_request_rebuild()

@export var dark_band_material: Material:
	set(v):
		dark_band_material = v
		_request_rebuild()

@export var neon_text: String = "":
	set(v):
		neon_text = v
		_request_rebuild()

@export var neon_color: Color = Color(0.24, 1.0, 0.78, 1.0):
	set(v):
		neon_color = v
		_request_rebuild()

@export var neon_side: SignSide = SignSide.FRONT:
	set(v):
		neon_side = v
		_request_rebuild()

@export var neon_y_ratio: float = 0.45:
	set(v):
		neon_y_ratio = v
		_request_rebuild()

@export var seed_id: int = 101:
	set(v):
		seed_id = v
		_request_rebuild()

const NeonSignScript = preload("res://scripts/neon_sign.gd")

var _aviation_light: MeshInstance3D

func _ready() -> void:
	if not facade_material:
		facade_material = load("res://environment/facade_tower.tres")
	rebuild()

func _request_rebuild() -> void:
	if is_inside_tree():
		rebuild()

func rebuild() -> void:
	for c in get_children():
		c.queue_free()

	if not facade_material:
		facade_material = load("res://environment/facade_tower.tres")
	
	var cur_y: float = 0.0
	var prev_w: float = footprint.x
	var prev_d: float = footprint.y

	# 1. Bangun tingkatan tier (Setback)
	for i in range(tier_fractions.size()):
		var frac: Vector3 = tier_fractions[i]
		var tier_h: float = total_height * frac.z
		var tier_w: float = footprint.x * frac.x
		var tier_d: float = footprint.y * frac.y

		# Pita mekanikal gelap pemisah antar tier
		if i > 0:
			var band: MeshInstance3D = MeshInstance3D.new()
			var band_box: BoxMesh = BoxMesh.new()
			band_box.size = Vector3(tier_w * 1.02, 6.0, tier_d * 1.02)
			band.mesh = band_box
			band.position = Vector3(0.0, cur_y + 3.0, 0.0)
			if dark_band_material:
				band.material_override = dark_band_material
			add_child(band)
			cur_y += 6.0

		# Balok utama tier
		var body: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(tier_w, tier_h, tier_d)
		body.mesh = box
		body.position = Vector3(0.0, cur_y + tier_h * 0.5, 0.0)
		body.material_override = facade_material
		add_child(body)

		# Rusuk vertikal (pilasters) di sudut-sudut tier bawah
		if i == 0:
			_add_pilasters(tier_w, tier_h, tier_d, cur_y)

		prev_w = tier_w
		prev_d = tier_d
		cur_y += tier_h

	# 2. Lengan menjorok (cantilevered ledges)
	if ledges_count > 0:
		_build_ledges(prev_w, prev_d, cur_y)

	# 3. Mahkota atas, tangki, dan antena
	_build_crown(prev_w, prev_d, cur_y)

	# 4. Papan neon vertikal
	if not neon_text.is_empty() and neon_side != SignSide.NONE:
		_build_neon(prev_w, prev_d)

func _add_pilasters(w: float, h: float, d: float, base_y: float) -> void:
	var rib_w: float = 3.5
	var rib_d: float = 3.5
	var corners: Array[Vector2] = [
		Vector2(w * 0.5, d * 0.5),
		Vector2(-w * 0.5, d * 0.5),
		Vector2(w * 0.5, -d * 0.5),
		Vector2(-w * 0.5, -d * 0.5)
	]
	var rib_mesh: BoxMesh = BoxMesh.new()
	rib_mesh.size = Vector3(rib_w, h, rib_d)

	for c in corners:
		var rib: MeshInstance3D = MeshInstance3D.new()
		rib.mesh = rib_mesh
		rib.position = Vector3(c.x, base_y + h * 0.5, c.y)
		rib.material_override = facade_material
		add_child(rib)

func _build_ledges(top_w: float, top_d: float, top_y: float) -> void:
	var ledge_mesh: BoxMesh = BoxMesh.new()
	var ledge_len: float = 32.0
	var ledge_thick: float = 5.0
	var ledge_depth: float = top_d * 0.35
	ledge_mesh.size = Vector3(ledge_len, ledge_thick, ledge_depth)

	var y_offsets: Array[float] = [0.82, 0.62, 0.42]
	for idx in range(min(ledges_count, y_offsets.size())):
		var ly: float = total_height * y_offsets[idx]
		var ledge: MeshInstance3D = MeshInstance3D.new()
		ledge.mesh = ledge_mesh
		ledge.material_override = facade_material

		if ledge_side == SignSide.LEFT:
			ledge.position = Vector3(-top_w * 0.5 - ledge_len * 0.45, ly, 0.0)
		elif ledge_side == SignSide.RIGHT:
			ledge.position = Vector3(top_w * 0.5 + ledge_len * 0.45, ly, 0.0)
		elif ledge_side == SignSide.FRONT:
			ledge_mesh.size = Vector3(ledge_depth, ledge_thick, ledge_len)
			ledge.position = Vector3(0.0, ly, top_d * 0.5 + ledge_len * 0.45)
		add_child(ledge)

func _build_crown(w: float, d: float, top_y: float) -> void:
	# Kotak struktur mahkota
	var crown_mesh: BoxMesh = BoxMesh.new()
	crown_mesh.size = Vector3(w * 0.7, 16.0, d * 0.7)
	var crown_inst: MeshInstance3D = MeshInstance3D.new()
	crown_inst.mesh = crown_mesh
	crown_inst.position = Vector3(0.0, top_y + 8.0, 0.0)
	crown_inst.material_override = facade_material
	add_child(crown_inst)

	var peak_y: float = top_y + 16.0

	# Antena tipis
	if crown == CrownStyle.ANTENNA or crown == CrownStyle.COMPLEX:
		var ant_mesh: BoxMesh = BoxMesh.new()
		ant_mesh.size = Vector3(2.0, 50.0, 2.0)
		var ant: MeshInstance3D = MeshInstance3D.new()
		ant.mesh = ant_mesh
		ant.position = Vector3(0.0, peak_y + 25.0, 0.0)
		add_child(ant)
		peak_y += 50.0

	# Lampu aviation merah berkedip di puncak tertinggi
	var light_mesh: BoxMesh = BoxMesh.new()
	light_mesh.size = Vector3(3.0, 3.0, 3.0)
	var red_mat: StandardMaterial3D = StandardMaterial3D.new()
	red_mat.albedo_color = Color(1.0, 0.1, 0.1, 1.0)
	red_mat.emission_enabled = true
	red_mat.emission = Color(1.0, 0.15, 0.15, 1.0)
	red_mat.emission_energy_multiplier = 5.0
	light_mesh.material = red_mat

	_aviation_light = MeshInstance3D.new()
	_aviation_light.name = "AviationLight"
	_aviation_light.mesh = light_mesh
	_aviation_light.position = Vector3(0.0, peak_y + 1.5, 0.0)
	add_child(_aviation_light)

func _build_neon(w: float, d: float) -> void:
	var neon: Node3D = NeonSignScript.new()
	neon.name = "Neon_" + neon_text
	neon.sign_text = neon_text
	neon.sign_color = neon_color
	neon.font_size = 140
	neon.hdr_multiplier = 5.0
	neon.has_light = false

	var ny: float = total_height * neon_y_ratio
	if neon_side == SignSide.FRONT:
		neon.position = Vector3(0.0, ny, d * 0.5 + 1.2)
	elif neon_side == SignSide.LEFT:
		neon.rotation_degrees = Vector3(0.0, -90.0, 0.0)
		neon.position = Vector3(-w * 0.5 - 1.2, ny, 0.0)
	elif neon_side == SignSide.RIGHT:
		neon.rotation_degrees = Vector3(0.0, 90.0, 0.0)
		neon.position = Vector3(w * 0.5 + 1.2, ny, 0.0)
	add_child(neon)

func _process(_delta: float) -> void:
	if not is_instance_valid(_aviation_light):
		return
	# Kedipan lampu aviation merah (periode 1.2 detik, on 0.15 detik)
	var cycle: float = fmod(Time.get_ticks_msec() * 0.001 + float(seed_id), 1.2)
	_aviation_light.visible = cycle < 0.18
