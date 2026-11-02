extends Node
class_name QualityPresets

## quality_presets.gd — Manajer preset grafis (Low / Medium / High)

signal preset_changed(preset_name: String)

enum Preset { LOW, MEDIUM, HIGH }

@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D

var current_preset: Preset = Preset.MEDIUM
var is_preset_locked: bool = false

func _ready() -> void:
	if not is_preset_locked:
		apply_preset(Preset.MEDIUM)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("preset_1"):
		apply_preset(Preset.LOW)
	elif event.is_action_pressed("preset_2"):
		apply_preset(Preset.MEDIUM)
	elif event.is_action_pressed("preset_3"):
		apply_preset(Preset.HIGH)

func apply_preset(preset: Preset) -> void:
	is_preset_locked = true
	current_preset = preset
	var env: Environment = world_environment.environment if world_environment else null

	match preset:
		Preset.LOW:
			print("[QualityPresets] Menerapkan Preset LOW")
			if env:
				env.volumetric_fog_enabled = false
				env.ssao_enabled = false
				env.glow_enabled = true
			if sun_light:
				sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 0)
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/screen_space_aa", 1) # FXAA
			preset_changed.emit("Low")

		Preset.MEDIUM:
			print("[QualityPresets] Menerapkan Preset MEDIUM")
			if env:
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.0008
				env.ssao_enabled = true
				env.ssao_radius = 4.0
				env.glow_enabled = true
			if sun_light:
				sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 1) # MSAA 2x
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/screen_space_aa", 1) # FXAA
			preset_changed.emit("Medium")

		Preset.HIGH:
			print("[QualityPresets] Menerapkan Preset HIGH")
			if env:
				env.volumetric_fog_enabled = true
				env.volumetric_fog_density = 0.0012
				env.ssao_enabled = true
				env.ssao_radius = 6.0
				env.glow_enabled = true
				env.sdfgi_enabled = true
			if sun_light:
				sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", 1)
			ProjectSettings.set_setting("rendering/anti_aliasing/quality/use_taa", true)
			preset_changed.emit("High")
