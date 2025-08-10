extends Node3D

@export var objective_deer_count: int = 5
@export var total_time: int = 300
@onready var score_label: Label = $"/root/Main/UI/Control/HuntLabel"
@onready var timer_label: Label = $"/root/Main/UI/Control/TimerLabel"
@onready var timer: Timer = $Timer
@onready var win_message_label: Label = $"/root/Main/UI/Control/WinMessage"
@onready var intro_message_label: Label = $"/root/Main/UI/Control/IntroMessage"

var deer_captured: int = 0
var time_left: int = 0
var game_ended: bool = false
var total_time_elapsed: int = 0

func _ready():
	win_message_label.visible = false
	time_left = total_time
	timer.timeout.connect(_on_timer_tick)
	timer.wait_time = 1
	timer.start()
	update_score_label()
	update_timer_label()
	intro_message_label.visible = true
	await get_tree().create_timer(10.0).timeout
	intro_message_label.visible = false

func _on_timer_tick():
	if game_ended:
		return
	
	time_left -= 1
	total_time_elapsed += 1
	Global.time_taken = total_time_elapsed
	update_timer_label()
	
	if time_left <= 0:
		end_game(false)

func update_score_label():
	score_label.text = "Deer Caught: %d / %d" % [deer_captured, objective_deer_count]

func update_timer_label():
	timer_label.text = "Time Left: %d:%02d" % [time_left / 60, time_left % 60]

func on_deer_captured():
	if game_ended:
		return

	deer_captured += 1
	update_score_label()

	if deer_captured >= objective_deer_count:
		end_game(true)

func end_game(won: bool):
	game_ended = true
	timer.stop()

	if won:
		win_message_label.visible = true
		await get_tree().create_timer(5.0).timeout

		get_tree().change_scene_to_file("res://scenes/victory.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
