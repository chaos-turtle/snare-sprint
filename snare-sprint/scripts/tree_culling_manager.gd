extends Node

@export var enable_distance: float = 128.0
@export var disable_distance: float = 135.0

func _process(_delta):
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return

	var cam_pos = camera.global_transform.origin

	for tree in get_tree().get_nodes_in_group("trees"):
		if not tree is Node3D:
			continue

		var dist = cam_pos.distance_to(tree.global_transform.origin)

		if dist <= enable_distance and !tree.visible:
			tree.visible = true
			_set_tree_collisions_enabled(tree, true)

		elif dist > disable_distance and tree.visible:
			tree.visible = false
			_set_tree_collisions_enabled(tree, false)
			

func _set_tree_collisions_enabled(tree: Node3D, enabled: bool) -> void:
	for shape in tree.get_children():
		if shape is CollisionShape3D:
			shape.disabled = !enabled
		elif shape is Node:
			_set_tree_collisions_enabled(shape, enabled)
