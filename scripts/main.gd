extends Node3D

## main.gd — Scene controller utama & manajemen kamera

@onready var sun: DirectionalLight3D = $Sun
@onready var ref_cam_marker: Marker3D = $RefCam
@onready var ref_camera: Camera3D = $RefCam/Camera3D
@onready var player: CharacterBody3D = $Player
@onready var quality_presets: Node = $QualityPresets
@onready var debug_overlay: CanvasLayer = $DebugOverlay
@onready var photo_mode: Node = $PhotoMode

func _ready() -> void:
	if sun:
		sun.rotation_degrees = Vector3(-32.0, 195.0, 0.0)
		sun.light_energy = 2.2
		sun.light_volumetric_fog_energy = 2.4

	if ref_camera:
		ref_camera.rotation_degrees = Vector3(-3.0, 0.0, 0.0)
		ref_camera.fov = 62.0
		ref_camera.far = 8000.0

	# Sambungkan signal preset ke debug overlay
	if quality_presets and debug_overlay and quality_presets.has_signal("preset_changed") and debug_overlay.has_method("set_preset_name"):
		quality_presets.connect("preset_changed", Callable(debug_overlay, "set_preset_name"))

	# Cek apakah dipanggil dari automated screenshot runner
	var is_screenshot_mode: bool = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			is_screenshot_mode = true
			break

	if is_screenshot_mode:
		ref_camera.current = true
		if player:
			player.set_physics_process(false)
	else:
		if player:
			var p_cam: Camera3D = player.get_node_or_null("Head/Camera3D")
			if p_cam:
				ref_camera.current = false
				p_cam.current = true
				player.position = Vector3(-45.0, 220.5, -68.0)
				print("[Main] Mode Interaktif aktif: Pemain berada di balkon.")
