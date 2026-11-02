extends Node

## screenshot_runner.gd — Autoload
## Membaca --shot=<nama> dan --preset=<low|medium|high> dari command line.
## Menunggu 120 frame lalu simpan screenshot dan quit.

const SHOT_DIR := "res://screenshots/"
const WAIT_FRAMES := 120

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var shot_name: String = ""
	var preset_name: String = "medium"

	for arg in args:
		if arg.begins_with("--shot="):
			shot_name = arg.substr(7)
		elif arg.begins_with("--preset="):
			preset_name = arg.substr(9)

	if shot_name.is_empty():
		return  # mode normal, tidak otomatis screenshot

	# Terapkan preset sesuai argumen jika ada
	var main_node: Node = get_tree().root.get_node_or_null("Main")
	if main_node:
		var qp: Node = main_node.get_node_or_null("QualityPresets")
		if qp and qp.has_method("apply_preset"):
			if preset_name.to_lower() == "low":
				qp.apply_preset(0)
			elif preset_name.to_lower() == "high":
				qp.apply_preset(2)
			else:
				qp.apply_preset(1)

	print("[ScreenshotRunner] Menunggu %d frame sebelum screenshot '%s' (preset: %s)" \
		% [WAIT_FRAMES, shot_name, preset_name])

	for i: int in range(WAIT_FRAMES):
		await get_tree().process_frame

	var dc: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var objs: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var fps: float = Engine.get_frames_per_second()
	print("[ScreenshotRunner] Profil Performa: FPS=%.1f | DrawCalls=%d | Objects=%d" % [fps, dc, objs])

	_take_screenshot(shot_name)
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
		var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
		_save_to_user("shot_%s" % stamp)


func _take_screenshot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var path: String = SHOT_DIR + name + ".png"
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(path))
	print("[ScreenshotRunner] Screenshot disimpan: %s" % path)


func _save_to_user(name: String) -> void:
	var dir: String = "user://shots/"
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = dir + name + ".png"
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[ScreenshotRunner] Screenshot disimpan: %s" % path)
