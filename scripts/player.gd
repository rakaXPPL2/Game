extends CharacterBody3D
class_name PlayerController

## player.gd — Kontroler pemain first-person di balkon + mode kamera bebas noclip

@export var walk_speed: float = 3.5
@export var sprint_speed: float = 7.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0025

var gravity: float = 9.8
var is_flying: bool = false
var fly_speeds: Array[float] = [50.0, 200.0, 800.0]
var fly_speed_index: int = 0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-88.0), deg_to_rad(88.0))

	if event.is_action_pressed("toggle_fly"):
		set_flying(not is_flying)

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Scroll mouse untuk mengatur kecepatan free cam
	if is_flying and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			fly_speed_index = min(fly_speed_index + 1, fly_speeds.size() - 1)
			print("[Player] Kecepatan Free Cam: %d m/s" % fly_speeds[fly_speed_index])
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			fly_speed_index = max(fly_speed_index - 1, 0)
			print("[Player] Kecepatan Free Cam: %d m/s" % fly_speeds[fly_speed_index])

func set_flying(active: bool) -> void:
	is_flying = active
	if is_flying:
		velocity = Vector3.ZERO
		collision_shape.disabled = true
		print("[Player] Mode Free Cam (Noclip): AKTIF (Kecepatan: %d m/s)" % fly_speeds[fly_speed_index])
	else:
		collision_shape.disabled = false
		print("[Player] Mode Jalan Kaki di Balkon: AKTIF")

func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if is_flying:
		# Mode terbang bebas noclip
		var forward: Vector3 = -camera.global_transform.basis.z
		var right: Vector3 = camera.global_transform.basis.x
		var move_dir: Vector3 = (forward * -input_dir.y + right * input_dir.x).normalized()
		
		# Naik / turun
		if Input.is_key_pressed(KEY_E):
			move_dir += Vector3.UP
		elif Input.is_key_pressed(KEY_Q):
			move_dir += Vector3.DOWN
		
		position += move_dir * fly_speeds[fly_speed_index] * delta
	else:
		# Mode jalan kaki di balkon
		if not is_on_floor():
			velocity.y -= gravity * delta

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

		var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
		var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction != Vector3.ZERO:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

		move_and_slide()
