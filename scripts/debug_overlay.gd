extends CanvasLayer
class_name DebugOverlay

## debug_overlay.gd — Overlay diagnostik performa FPS & Draw Call (F3)

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Margin/VBox/Label

var is_visible: bool = false
var active_preset_name: String = "Medium"

func _ready() -> void:
	panel.visible = is_visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		is_visible = not is_visible
		panel.visible = is_visible

func _process(_delta: float) -> void:
	if not panel.visible:
		return

	var fps: float = Engine.get_frames_per_second()
	var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)

	label.text = """[KOTA BRUTALIS DIAGNOSTICS]
FPS: %d (%.2f ms)
Draw Calls: %d
Objects: %d
Primitives: %d
Quality Preset: %s
[1/2/3] Ganti Preset | [F] Free Cam | [F2] Screenshot | [P] Photo Mode""" % [
		fps,
		1000.0 / max(fps, 1.0),
		draw_calls,
		objects,
		primitives,
		active_preset_name
	]

func set_preset_name(p_name: String) -> void:
	active_preset_name = p_name
