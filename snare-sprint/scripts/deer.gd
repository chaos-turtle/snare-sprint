extends CharacterBody3D

@onready var animation_player = $AnimationPlayer
@onready var detection_area = $DetectionArea

enum DeerState { IDLE, WALKING, RUNNING, CAUGHT }
var current_state = DeerState.IDLE
var player_reference = null

@export var walk_speed = 3.0
@export var run_speed = 8.0
@export var detection_range = 10.0
@export var flee_distance = 20.0
@export var turn_smoothing = 5.0

var state_timer = 0.0
var idle_duration = randf_range(2.0, 5.0)
var walk_duration = randf_range(3.0, 6.0)
var walk_direction = Vector3.ZERO
var flee_direction = Vector3.ZERO
var is_player_nearby = false

signal deer_caught
var is_caught = false

func _ready():
	for anim_name in animation_player.get_animation_list():
		var animation = animation_player.get_animation(anim_name)
		animation.loop_mode = Animation.LOOP_LINEAR
	player_reference = get_tree().get_first_node_in_group("player")
	setup_detection_area()
	change_state(DeerState.IDLE)

func setup_detection_area():
	if not detection_area:
		detection_area = Area3D.new()
		add_child(detection_area)
		
		var collision_shape = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = detection_range
		collision_shape.shape = sphere_shape
		detection_area.add_child(collision_shape)

	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)

func _physics_process(delta):
	if is_caught:
		return
		
	state_timer += delta
	
	if player_reference:
		check_player_proximity()

	match current_state:
		DeerState.IDLE:
			handle_idle_state(delta)
		DeerState.WALKING:
			handle_walking_state(delta)
		DeerState.RUNNING:
			handle_running_state(delta)
		DeerState.CAUGHT:
			handle_caught_state(delta)

	move_and_slide()

func check_player_proximity():
	if is_caught:
		return
		
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	if distance_to_player <= detection_range and not is_player_nearby:
		is_player_nearby = true
		start_fleeing()
	elif distance_to_player > detection_range and is_player_nearby:
		is_player_nearby = false

func handle_idle_state(delta):
	velocity = Vector3.ZERO
	if state_timer >= idle_duration and not is_player_nearby:
		change_state(DeerState.WALKING)

func handle_walking_state(delta):
	if walk_direction == Vector3.ZERO:
		walk_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

	velocity.x = walk_direction.x * walk_speed
	velocity.z = walk_direction.z * walk_speed

	if velocity.length() > 0.1:
		look_at(global_position + velocity.normalized(), Vector3.UP)

	if state_timer >= walk_duration and not is_player_nearby:
		change_state(DeerState.IDLE)

func handle_running_state(delta):
	if player_reference:
		var desired_flee_direction = (global_position - player_reference.global_position).normalized()
		desired_flee_direction.y = 0

		flee_direction = flee_direction.slerp(desired_flee_direction, turn_smoothing * delta)
		flee_direction = flee_direction.normalized()

		velocity.x = flee_direction.x * run_speed
		velocity.z = flee_direction.z * run_speed

		look_at(global_position + flee_direction, Vector3.UP)

		if animation_player.current_animation != "Run" or not animation_player.is_playing():
			play_animation("Run")

	if player_reference and global_position.distance_to(player_reference.global_position) >= flee_distance:
		is_player_nearby = false
		change_state(DeerState.IDLE)

func start_fleeing():
	if is_caught:
		return
	change_state(DeerState.RUNNING)

func change_state(new_state: DeerState):
	current_state = new_state
	state_timer = 0.0

	match new_state:
		DeerState.IDLE:
			idle_duration = randf_range(3.0, 6.0)
			var anim_index = randi() % 2
			var anim_name = "LookAround_%03d" % anim_index
			play_animation(anim_name)
		DeerState.WALKING:
			walk_duration = randf_range(4.0, 7.0)
			walk_direction = Vector3.ZERO
			play_animation("Run")
		DeerState.RUNNING:
			play_animation("Run")
		DeerState.CAUGHT:
			velocity = Vector3.ZERO
			play_animation("Idle")

func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.stop()
		animation_player.play(anim_name)

func _on_detection_area_entered(body):
	if body.is_in_group("player") and not is_caught:
		is_player_nearby = true
		start_fleeing()

func _on_detection_area_exited(body):
	if body.is_in_group("player") and not is_caught:
		is_player_nearby = false

func catch_deer():
	if is_caught:
		return
	is_caught = true
	change_state(DeerState.CAUGHT)
	deer_caught.emit()
	show_caught_effect()

	await get_tree().create_timer(1.0).timeout
	queue_free()

func show_caught_effect():
	# Add sound?
	pass

func handle_caught_state(delta):
	pass
