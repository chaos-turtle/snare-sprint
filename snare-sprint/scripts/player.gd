extends CharacterBody3D

const SPEED = 8.0
const SPRINT_SPEED = 10.0
const CROUCH_SPEED = 5
const JUMP_VELOCITY = 4.0

const NORMAL_HEIGHT = 1.8
const CROUCH_HEIGHT = 0.9
const CROUCH_TRANSITION_SPEED = 8.0

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var muzzle := $Neck/Camera3D/Muzzle
@onready var jump_sound := $JumpSound
@onready var collision_shape := $CollisionShape3D
@onready var ammo_label: Label = $"/root/Main/UI/Control/AmmoLabel"
@export var net_scene: PackedScene
@export var cooldown_time: float = 1.5
@export var max_ammo: int = 20

var can_shoot: bool = true
var is_crouching = false
var current_speed = SPEED
var current_ammo: int = 3

func _ready():
	add_to_group("player")
	$CooldownTimer.timeout.connect(_on_cooldown_finished)
	$CooldownTimer.wait_time = cooldown_time
	update_ammo_label()

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
	if not can_shoot or current_ammo <= 0:
		return
	
	can_shoot = false
	$CooldownTimer.start()
	
	var net = net_scene.instantiate() as RigidBody3D
	get_tree().current_scene.add_child(net)
	net.global_transform.origin = muzzle.global_transform.origin
	net.global_transform.basis = muzzle.global_transform.basis
	
	current_ammo -= 1
	update_ammo_label()
	
	await get_tree().process_frame
	var direction = -muzzle.global_transform.basis.z.normalized()
	net.linear_velocity = direction * 40

func _on_cooldown_finished():
	can_shoot = true

func update_ammo_label():
	if ammo_label:
		ammo_label.text = "Ammo: %d" % current_ammo

func add_ammo(amount: int):
	current_ammo = clamp(current_ammo + amount, 0, max_ammo)
	update_ammo_label()

func on_deer_captured():
	var hunt_manager = get_node("/root/Main/HuntManager")
	hunt_manager.on_deer_captured()
