@tool
extends Node3D
class_name CloudCanopy

## cloud_canopy.gd — Sistem berkas cahaya atmosferis (God Rays)

@export var ray_color: Color = Color(1.0, 0.90, 0.74, 1.0)
@export var ray_energy: float = 2.4
@export var volumetric_energy: float = 4.8

func _ready() -> void:
	_setup_god_rays()

func _setup_god_rays() -> void:
	for c in get_children():
		c.queue_free()

	# Berkas cahaya diagonal 1: Menembus ke arah kanan-tengah kota (sesuai ref x 52-72%, y 25-55%)
	var ray1 := SpotLight3D.new()
	ray1.name = "GodRay_Primary"
	add_child(ray1)
	ray1.position = Vector3(-120.0, 850.0, -180.0)
	ray1.look_at(Vector3(260.0, 60.0, -850.0), Vector3.UP)
	ray1.spot_angle = 32.0
	ray1.spot_attenuation = 1.4
	ray1.spot_range = 2600.0
	ray1.light_color = ray_color
	ray1.light_energy = ray_energy
	ray1.light_volumetric_fog_energy = volumetric_energy
	ray1.shadow_enabled = false

	# Berkas cahaya diagonal 2: Menembus ke arah lembah menara tengah
	var ray2 := SpotLight3D.new()
	ray2.name = "GodRay_Secondary"
	add_child(ray2)
	ray2.position = Vector3(-240.0, 820.0, -320.0)
	ray2.look_at(Vector3(60.0, 80.0, -1200.0), Vector3.UP)
	ray2.spot_angle = 24.0
	ray2.spot_attenuation = 1.8
	ray2.spot_range = 2800.0
	ray2.light_color = ray_color * 0.85
	ray2.light_energy = ray_energy * 0.75
	ray2.light_volumetric_fog_energy = volumetric_energy * 0.85
	ray2.shadow_enabled = false
