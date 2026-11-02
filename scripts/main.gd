extends Node3D

## main.gd — Scene controller untuk blockout & setup tata cahaya

@onready var sun: DirectionalLight3D = $Sun
@onready var ref_cam: Marker3D = $RefCam
@onready var camera_3d: Camera3D = $RefCam/Camera3D

func _ready() -> void:
	if sun:
		sun.rotation_degrees = Vector3(-32.0, 195.0, 0.0)
		sun.light_energy = 2.0
		sun.light_volumetric_fog_energy = 1.6
	
	if camera_3d:
		camera_3d.rotation_degrees = Vector3(-3.0, 0.0, 0.0)
		camera_3d.fov = 62.0
		camera_3d.far = 8000.0
