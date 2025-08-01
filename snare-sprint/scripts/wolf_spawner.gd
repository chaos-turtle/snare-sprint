extends Node3D

@export var scene_to_spawn: PackedScene
@export var spawn_count: int = 1
@export var respawn: bool = false
@export var respawn_interval: float = 10.0

var spawn_points: Array[Node3D] = []
var occupied: Dictionary = {}

func _ready():
	for child in get_children():
		if child is Node3D:
			spawn_points.append(child)

	spawn_initial()

	if respawn:
		start_respawn_timer()

func spawn_initial():
	var chosen := []
	while chosen.size() < min(spawn_count, spawn_points.size()):
		var idx = randi() % spawn_points.size()
		if idx not in chosen:
			chosen.append(idx)

	for i in chosen:
		spawn_at(i)

func spawn_at(index: int):
	if occupied.get(index, false):
		return

	var spawn_point = spawn_points[index]
	var instance = scene_to_spawn.instantiate()
	spawn_point.add_child(instance)
	occupied[index] = true

	instance.tree_exited.connect(func():
		occupied[index] = false
	)

func start_respawn_timer():
	var timer = Timer.new()
	timer.wait_time = respawn_interval
	timer.autostart = true
	timer.timeout.connect(_on_respawn_timeout)
	add_child(timer)

func _on_respawn_timeout():
	var free := []
	for i in spawn_points.size():
		if not occupied.get(i, false):
			free.append(i)

	if free.size() > 0:
		var index = free[randi() % free.size()]
		spawn_at(index)
