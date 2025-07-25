extends Control

@onready var play_button: Button = $PlayButton
@onready var quit_button: Button = $QuitButton
@onready var lose_sound: AudioStreamPlayer = $LoseSound

func _ready() -> void:
	lose_sound.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
