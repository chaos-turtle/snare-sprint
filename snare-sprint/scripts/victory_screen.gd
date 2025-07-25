extends Control

@onready var time_label: Label = $TimeLabel
@onready var play_button: Button = $PlayButton
@onready var quit_button: Button = $QuitButton
@onready var win_sound: AudioStreamPlayer = $WinSound

func _ready() -> void:
	win_sound.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	time_label.text = "Time Taken: " + str(Global.time_taken) + " seconds"
	play_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_restart_pressed()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _on_restart_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
