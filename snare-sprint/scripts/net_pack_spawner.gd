extends Node3D

@export var net_pack_scene: PackedScene
@export var respawn_interval: float = 20.0

var spawn_points: Array[Node3D] = []
var occupied_spots: Dictionary = {}

func _ready():
	for child in get_children():
		if child is Node3D:
			spawn_points.append(child)

	_spawn_initial_packs()

	spawn_timer()

func _spawn_initial_packs():
	var num_to_spawn = randi() % spawn_points.size() + 1
	var indices = spawn_points.size()
	var chosen = []

	while chosen.size() < num_to_spawn:
		var idx = randi() % indices
		if idx not in chosen:
			chosen.append(idx)

	for i in chosen:
		spawn_pack(i)

func spawn_pack(index: int):
	if occupied_spots.get(index, false):
		return

	var spawn_point = spawn_points[index]
	var net_instance = net_pack_scene.instantiate()
	spawn_point.add_child(net_instance)
	occupied_spots[index] = true

	net_instance.picked_up.connect(func():
		occupied_spots[index] = false
	)

func spawn_timer():
	var timer = Timer.new()
	timer.wait_time = respawn_interval
	timer.autostart = true
	timer.timeout.connect(_on_respawn_timeout)
	add_child(timer)

func _on_respawn_timeout():
	var free_indices = []
	for i in spawn_points.size():
		if not occupied_spots.get(i, false):
			free_indices.append(i)

	if free_indices.size() > 0:
		var index = free_indices[randi() % free_indices.size()]
		spawn_pack(index)
