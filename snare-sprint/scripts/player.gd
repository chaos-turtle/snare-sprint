extends CharacterBody3D

const SPEED = 10.0
const SPRINT_SPEED = 13.0
const CROUCH_SPEED = 5
const JUMP_VELOCITY = 4.0

const NORMAL_HEIGHT = 1.8
const CROUCH_HEIGHT = 0.9
const CROUCH_TRANSITION_SPEED = 8.0

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var jump_sound := $JumpSound
@onready var collision_shape := $CollisionShape3D
@export var net_scene: PackedScene

var is_crouching = false
var current_speed = SPEED

func _ready():
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.003)
			camera.rotate_x(-event.relative.y * 0.003)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-50), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	handle_crouch(delta)
	handle_sprint()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		jump_sound.play()
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()

func handle_sprint():
	if Input.is_action_pressed("ui_shift") and not is_crouching:
		current_speed = SPRINT_SPEED
	elif is_crouching:
		current_speed = CROUCH_SPEED
	else:
		current_speed = SPEED

func handle_crouch(delta: float):
	if Input.is_action_just_pressed("ui_ctrl"):
		is_crouching = !is_crouching
	
	var capsule_shape = collision_shape.shape as CapsuleShape3D
	if capsule_shape == null:
		push_error("CollisionShape3D should have a CapsuleShape3D")
		return
	
	var target_height = CROUCH_HEIGHT if is_crouching else NORMAL_HEIGHT
	var current_height = capsule_shape.height
	var new_height = lerp(current_height, target_height, CROUCH_TRANSITION_SPEED * delta)
	
	capsule_shape.height = new_height
	
	var height_difference = new_height - NORMAL_HEIGHT
	neck.position.y = height_difference * 0.5

func _input(event):
	if event.is_action_pressed("fire"):
		shoot_net()

func shoot_net():
	var net = net_scene.instantiate() as RigidBody3D
	var muzzle = $Neck/Camera3D/Muzzle
	get_tree().current_scene.add_child(net)

	net.global_transform.origin = muzzle.global_transform.origin
	net.global_transform.basis = muzzle.global_transform.basis
	
	await get_tree().process_frame

	var direction = -muzzle.global_transform.basis.z.normalized()
	net.linear_velocity = direction * 15
