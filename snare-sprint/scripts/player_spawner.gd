extends Node3D

@export var player_scene: PackedScene

func _ready():
	var points = get_children().filter(func(n): return n is Node3D)
	if points.size() == 0: return

	var idx = randi() % points.size()
	var player = player_scene.instantiate()
	points[idx].add_child(player)
