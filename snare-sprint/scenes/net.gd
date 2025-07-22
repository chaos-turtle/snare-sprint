extends RigidBody3D

@export var max_scale: float = 0.4
@export var growth_rate: float = 2

@onready var mesh = $mesh
@onready var collision_shape = $CollisionShape3D

func _ready():
	await get_tree().create_timer(4.0).timeout
	if is_inside_tree():
		queue_free()

func _physics_process(delta):
	if mesh.scale.x < max_scale:
		var new_scale = mesh.scale + Vector3.ONE * growth_rate * delta
		new_scale.x = min(new_scale.x, max_scale)
		new_scale.y = min(new_scale.y, max_scale)
		new_scale.z = min(new_scale.z, max_scale)
		mesh.scale = new_scale
		collision_shape.scale = new_scale

	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = global_position + Vector3.DOWN * 0.1

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result and result.collider.is_in_group("ground"):
		queue_free()
