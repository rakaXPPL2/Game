extends Node
class_name PhotoMode

## photo_mode.gd — Mode foto sinematik (P): menyembunyikan UI & mengaktifkan kamera bebas

signal photo_mode_toggled(active: bool)

@export var player_node: Node3D
@export var debug_overlay: CanvasLayer

var is_active: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("photo_mode"):
		is_active = not is_active
		if debug_overlay:
			debug_overlay.visible = not is_active
		photo_mode_toggled.emit(is_active)
		print("[PhotoMode] Mode Foto: ", "AKTIF" if is_active else "NONAKTIF")
