extends CharacterBody3D

@export var move_speed_idle := 2.0
@export var move_speed_chase := 6.0
@export var detection_radius := 20.0
@export var lose_interest_time := 3.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var player: Node3D = get_node("../Player")
@onready var detection_area: Area3D = $PlayerDetector
@onready var lose_timer: Timer = $LoseTimer

enum State { IDLE, WANDER, CHASE }
var state: State = State.IDLE

func _ready():
	nav_agent.max_speed = move_speed_idle
	anim_tree.active = true

	detection_area.connect("body_entered", _on_player_entered)
	detection_area.connect("body_exited", _on_player_exited)
	lose_timer.timeout.connect(_on_lose_timer_timeout)

	_start_wander()

func _physics_process(delta):
	match state:
		State.WANDER:
			_wander_logic()
		State.CHASE:
			_chase_logic()

	_move_along_path(delta)

# --- Wandering Logic ---
func _start_wander():
	state = State.WANDER
	nav_agent.max_speed = move_speed_idle
	_set_random_wander_target()
	set_walk()

func _set_random_wander_target():
	var random_offset = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
	var target = global_position + random_offset
	nav_agent.set_target_position(target)

func _wander_logic():
	if nav_agent.is_navigation_finished():
		_set_random_wander_target()

# --- Chasing Logic ---
func _chase_logic():
	if not is_instance_valid(player):
		return
	nav_agent.set_target_position(player.global_position)

# --- Move Function ---
func _move_along_path(delta):
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity = direction * nav_agent.max_speed
	move_and_slide()

# --- Animation Control ---
func set_idle():
	anim_tree.set("parameters/conditions/is_walking", false)
	anim_tree.set("parameters/conditions/is_running", false)

func set_walk():
	anim_tree.set("parameters/conditions/is_walking", true)
	anim_tree.set("parameters/conditions/is_running", false)

func set_run():
	anim_tree.set("parameters/conditions/is_walking", true)
	anim_tree.set("parameters/conditions/is_running", true)

# --- Detection Events ---
func _on_player_entered(body):
	if body.name == "Player":
		state = State.CHASE
		nav_agent.max_speed = move_speed_chase
		set_run()
		lose_timer.stop()

func _on_player_exited(body):
	if body.name == "Player":
		lose_timer.start(lose_interest_time)

func _on_lose_timer_timeout():
	_start_wander()

# --- Collision with Player: Game Over ---
func _on_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
