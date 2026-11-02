@tool
extends Node3D
class_name NeonSign

## neon_sign.gd — Papan neon vertikal prosedural berdaya pendar HDR

@export var sign_text: String = "KARANG":
	set(v):
		sign_text = v
		_rebuild()

@export var sign_color: Color = Color(0.24, 1.0, 0.78, 1.0): # Teal
	set(v):
		sign_color = v
		_rebuild()

@export var is_vertical: bool = true:
	set(v):
		is_vertical = v
		_rebuild()

@export var font_size: int = 120:
	set(v):
		font_size = v
		_rebuild()

@export var hdr_multiplier: float = 4.5:
	set(v):
		hdr_multiplier = v
		_rebuild()

@export var has_light: bool = false:
	set(v):
		has_light = v
		_rebuild()

@export var light_range: float = 60.0:
	set(v):
		light_range = v
		_rebuild()

@export var flicker: bool = true

var label: Label3D
var omni: OmniLight3D
var base_modulate: Color

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	# Bersihkan child lama jika dipanggil berulang
	for c in get_children():
		c.queue_free()

	label = Label3D.new()
	label.name = "Label"
	label.shaded = false
	label.double_sided = true
	label.pixel_size = 0.08
	label.font_size = font_size
	label.outline_size = 4
	label.outline_modulate = Color(0.02, 0.03, 0.04, 0.9)

	var display_text := sign_text
	if is_vertical and not sign_text.contains("\n"):
		var chars: PackedStringArray = []
		for i in range(sign_text.length()):
			chars.append(sign_text.substr(i, 1))
		display_text = "\n".join(chars)

	label.text = display_text
	base_modulate = Color(
		sign_color.r * hdr_multiplier,
		sign_color.g * hdr_multiplier,
		sign_color.b * hdr_multiplier,
		1.0
	)
	label.modulate = base_modulate
	add_child(label)

	if has_light:
		omni = OmniLight3D.new()
		omni.name = "GlowLight"
		omni.light_color = sign_color
		omni.light_energy = 2.2
		omni.omni_range = light_range
		omni.shadow_enabled = false
		add_child(omni)

func _process(_delta: float) -> void:
	if not flicker or not is_instance_valid(label):
		return
	
	# Kerlip mikro realistis
	var t: float = Time.get_ticks_msec() * 0.001
	var noise_val: float = sin(t * 13.7) * cos(t * 7.3)
	var f: float = 1.0
	if noise_val > 0.88:
		f = 0.65
	elif noise_val > 0.96:
		f = 0.25
	
	label.modulate = base_modulate * f
	if is_instance_valid(omni):
		omni.light_energy = 2.2 * f
