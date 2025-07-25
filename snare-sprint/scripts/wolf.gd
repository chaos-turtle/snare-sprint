extends CharacterBody3D

@export var move_speed_idle := 2.0
@export var move_speed_chase := 6.0
@export var detection_radius := 20.0
@export var lose_interest_time := 3.0

@onready var nav_agent := $NavigationAgent3D
@onready var anim_tree := $AnimationTree
@onready var player := get_node("Player")  # Adjust path
@onready var detection_area := $PlayerDetector
@onready var lose_timer := $LoseTimer  # Optional Timer node

enum State { IDLE, WANDER, CHASE }
var state := State.IDLE

var last_known_player_pos := Vector3.ZERO
var lose_timer_active := false

func _ready():
	nav_agent.max_speed = move_speed_idle
	anim_tree.active = true
	detection_area.connect("body_entered", _on_player_entered)
	detection_area.connect("body_exited", _on_player_exited)
	_start_wander()

func _physics_process(delta):
	match state:
		State.WANDER:
			_wander_logic()
		State.CHASE:
			_chase_logic()

	_move_along_path(delta)

func _start_wander():
	state = State.WANDER
	nav_agent.max_speed = move_speed_idle
	anim_tree.set("parameters/conditions/is_walking", true)
	anim_tree.set("parameters/conditions/is_running", false)
	_set_random_wander_target()

func _set_random_wander_target():
	var rand_pos = global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	nav_agent.set_target_position(rand_pos)

func _wander_logic():
	if nav_agent.is_navigation_finished():
		_set_random_wander_target()

func _chase_logic():
	if not is_instance_valid(player):
		return

	last_known_player_pos = player.global_position
	nav_agent.set_target_position(last_known_player_pos)

func _move_along_path(delta):
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next = nav_agent.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * nav_agent.max_speed
	move_and_slide()

# --- Detection signals ---
func _on_player_entered(body):
	if body.name == "Player":
		state = State.CHASE
		nav_agent.max_speed = move_speed_chase
		anim_tree.set("parameters/conditions/is_running", true)
		anim_tree.set("parameters/conditions/is_walking", false)
		if lose_timer:
			lose_timer.stop()

func _on_player_exited(body):
	if body.name == "Player" and lose_timer:
		lose_timer.start(lose_interest_time)

func _on_LoseTimer_timeout():
	# Player has been gone too long
	_start_wander()

# --- Collision with Player ---
func _on_body_entered(body):
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scripts/game_over_screen.gd")
