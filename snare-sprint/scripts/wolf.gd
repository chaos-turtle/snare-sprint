extends CharacterBody3D

class_name Wolf

enum WolfState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK
}

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var detection_area: Area3D
var attack_area: Area3D
var patrol_timer: Timer
var obstacle_raycast: RayCast3D

@export var idle_speed: float = 0.0
@export var walk_speed: float = 2.5
@export var run_speed: float = 6.0
@export var detection_range: float = 10.0
@export var attack_range: float = 1.5
@export var patrol_radius: float = 15.0
@export var chase_time: float = 8.0
@export var patrol_wait_time: float = 3.0
@export var obstacle_avoidance_distance: float = 2.0
@export var turn_speed: float = 3.0

var current_state: WolfState = WolfState.IDLE
var player: Node3D
var home_position: Vector3
var patrol_target: Vector3
var chase_timer: float = 0.0
var current_direction: Vector3 = Vector3.FORWARD
var target_direction: Vector3 = Vector3.FORWARD
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	home_position = global_position

	create_nodes()
	setup_detection_area()
	setup_attack_area()
	setup_obstacle_raycast()

	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)

	patrol_timer.wait_time = patrol_wait_time
	patrol_timer.start()

	change_state(WolfState.IDLE)

func create_nodes():
	detection_area = Area3D.new()
	detection_area.name = "DetectionArea"
	add_child(detection_area)

	attack_area = Area3D.new()
	attack_area.name = "AttackArea"
	add_child(attack_area)

	patrol_timer = Timer.new()
	patrol_timer.name = "PatrolTimer"
	add_child(patrol_timer)

	obstacle_raycast = RayCast3D.new()
	obstacle_raycast.name = "ObstacleRaycast"
	add_child(obstacle_raycast)

func setup_detection_area():
	var detection_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = detection_range
	detection_shape.shape = sphere_shape
	detection_area.add_child(detection_shape)

func setup_attack_area():
	var attack_shape = CollisionShape3D.new()
	var attack_sphere = SphereShape3D.new()
	attack_sphere.radius = attack_range
	attack_shape.shape = attack_sphere
	attack_area.add_child(attack_shape)

func setup_obstacle_raycast():
	obstacle_raycast.target_position = current_direction * obstacle_avoidance_distance
	obstacle_raycast.enabled = true

func _physics_process(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity * delta
	rotation.x = 0
	rotation.z = 0
	update_state(delta)
	handle_movement(delta)
	move_and_slide()

func handle_movement(delta):
	obstacle_raycast.target_position = current_direction * obstacle_avoidance_distance
	obstacle_raycast.force_raycast_update()

	if obstacle_raycast.is_colliding():
		var normal = obstacle_raycast.get_collision_normal()
		var avoidance_direction = current_direction.cross(Vector3.UP).normalized()
		if normal.dot(avoidance_direction) < 0:
			avoidance_direction = -avoidance_direction
		target_direction = avoidance_direction
	else:
		target_direction = get_intended_direction()

	if target_direction.length() > 0.1:
		current_direction = current_direction.slerp(target_direction.normalized(), turn_speed * delta).normalized()
		var target_rot = atan2(current_direction.x, current_direction.z) + PI
		rotation.y = lerp_angle(rotation.y, target_rot, turn_speed * delta)

func get_intended_direction() -> Vector3:
	match current_state:
		WolfState.IDLE:
			return Vector3.ZERO
		WolfState.PATROL:
			return get_patrol_direction()
		WolfState.CHASE:
			return get_chase_direction()
		WolfState.ATTACK:
			return Vector3.ZERO
		_:
			return Vector3.ZERO

func get_patrol_direction() -> Vector3:
	var distance = global_position.distance_to(patrol_target)
	if distance < 2.0:
		change_state(WolfState.IDLE)
		return Vector3.ZERO
	return (patrol_target - global_position).normalized()

func get_chase_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	return (player.global_position - global_position).normalized()

func update_state(delta):
	match current_state:
		WolfState.IDLE:
			update_idle_state()
		WolfState.PATROL:
			update_patrol_state()
		WolfState.CHASE:
			update_chase_state(delta)
		WolfState.ATTACK:
			update_attack_state()

func update_idle_state():
	velocity.x = 0
	velocity.z = 0
	if player and can_see_player():
		change_state(WolfState.CHASE)

func update_patrol_state():
	var speed = walk_speed
	velocity.x = current_direction.x * speed
	velocity.z = current_direction.z * speed
	if player and can_see_player():
		change_state(WolfState.CHASE)

func update_chase_state(delta):
	if not player:
		change_state(WolfState.IDLE)
		return
	chase_timer -= delta
	if chase_timer <= 0:
		change_state(WolfState.PATROL)
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range * 1.5:
		change_state(WolfState.PATROL)
		return

	var speed = run_speed
	velocity.x = current_direction.x * speed
	velocity.z = current_direction.z * speed

func update_attack_state():
	velocity.x = 0
	velocity.z = 0
	if player:
		var dir = (player.global_position - global_position).normalized()
		var look_target = global_position + dir
		look_at(look_target, Vector3.UP)

func change_state(new_state: WolfState):
	match current_state:
		WolfState.CHASE:
			chase_timer = 0.0
	current_state = new_state

	match new_state:
		WolfState.IDLE:
			animation_player.play("Wolf_Skeleton|Wolf_Idle_")
		WolfState.PATROL:
			animation_player.play("Wolf_Skeleton|Wolf_Walk_")
			set_new_patrol_target()
		WolfState.CHASE:
			animation_player.play("Wolf_Skeleton|Wolf_Run_")
			chase_timer = chase_time
		WolfState.ATTACK:
			pass

func set_new_patrol_target():
	var angle = randf() * TAU
	var distance = randf_range(5.0, patrol_radius)
	patrol_target = home_position + Vector3(
		cos(angle) * distance,
		0,
		sin(angle) * distance
	)

func can_see_player() -> bool:
	if not player:
		return false
	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range:
		return false

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		player.global_position + Vector3.UP
	)
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player

func _on_detection_area_entered(body):
	if body.has_method("is_player") or body.is_in_group("player"):
		player = body
		if current_state == WolfState.IDLE or current_state == WolfState.PATROL:
			change_state(WolfState.CHASE)

func _on_detection_area_exited(body):
	if body == player:
		pass

func _on_attack_area_entered(body):
	if body == player:
		change_state(WolfState.ATTACK)
		trigger_game_over()

func _on_patrol_timer_timeout():
	if current_state == WolfState.IDLE:
		change_state(WolfState.PATROL)
	patrol_timer.start()

func trigger_game_over():
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
