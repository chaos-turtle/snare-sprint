extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	visible = false

func _on_resume_pressed():
	toggle_pause()

func _on_restart_pressed():
	get_tree().paused = false
	
	var terrain3d = get_node_or_null("../Terrain3D")
	if terrain3d:
		var data_directory = terrain3d.get_data_directory()
		var parent = terrain3d.get_parent()
		
		terrain3d.queue_free()

		await get_tree().process_frame
		await get_tree().process_frame

	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()

func toggle_pause():
	visible = !visible
	get_tree().paused = visible
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
