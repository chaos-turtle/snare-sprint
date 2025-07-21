extends Node3D

@export var tree_mesh: Mesh
@export var tree_material: Material
@export var collider_radius := 0.5
@export var collider_height := 3.0

func _ready():
	var tree_nodes := get_tree_nodes()
	var positions: Array[Vector3] = []

	for tree in tree_nodes:
		positions.append(tree.global_transform.origin)
		tree.queue_free()

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = positions.size()
	mm.mesh = tree_mesh

	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.multimesh = mm
	mm_instance.material_override = tree_material
	add_child(mm_instance)

	for i in positions.size():
		var pos = positions[i]
		var rot = randf() * TAU
		var scale = Vector3(2.5, 2.5, 2.5)
		var basis = Basis(Vector3.UP, rot).scaled(scale)
		var transform = Transform3D(basis, pos)
		mm.set_instance_transform(i, transform)

		var body := StaticBody3D.new()
		body.transform = Transform3D.IDENTITY.translated(pos)
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = collider_radius
		capsule.height = collider_height
		shape.shape = capsule
		body.add_child(shape)
		add_child(body)

func get_tree_nodes() -> Array:
	var tree_nodes: Array = []
	for child in get_tree().get_root().get_children():
		find_tree_instances(child, tree_nodes)
	return tree_nodes

func find_tree_instances(node: Node, result: Array):
	if node is Node3D and "Tree" in node.name:
		result.append(node)
	for child in node.get_children():
		find_tree_instances(child, result)
