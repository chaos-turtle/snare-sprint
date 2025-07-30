extends RigidBody3D

@export var max_scale: float = 0.5
@export var growth_rate: float = 2
@export var capture_radius: float = 1.0

@onready var mesh = $mesh
@onready var collision_shape = $CollisionShape3D
@onready var capture_area = $CatchArea

var has_captured = false
var captured_deer = null

func _ready():
	setup_capture_area()
	
	await get_tree().create_timer(3.5).timeout
	if is_inside_tree():
		queue_free()

func setup_capture_area():
	if not capture_area:
		capture_area = Area3D.new()
		add_child(capture_area)
		
		var collision_shape_3d = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = capture_radius
		collision_shape_3d.shape = sphere_shape
		capture_area.add_child(collision_shape_3d)
	
	capture_area.body_entered.connect(_on_capture_area_entered)

func _physics_process(delta):
	if mesh.scale.x < max_scale:
		var new_scale = mesh.scale + Vector3.ONE * growth_rate * delta
		new_scale.x = min(new_scale.x, max_scale)
		new_scale.y = min(new_scale.y, max_scale)
		new_scale.z = min(new_scale.z, max_scale)
		mesh.scale = new_scale
		collision_shape.scale = new_scale

		if capture_area:
			var capture_collision = capture_area.get_child(0) as CollisionShape3D
			if capture_collision:
				capture_collision.scale = new_scale

	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = global_position + Vector3.DOWN * 0.1

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result and result.collider.is_in_group("ground"):
		handle_ground_hit()

func handle_ground_hit():
	"""Handle when the net hits the ground"""
	if has_captured and captured_deer:
		await get_tree().create_timer(1.5).timeout
		if captured_deer and is_instance_valid(captured_deer):
			if captured_deer.has_method("start_fade_out"):
				captured_deer.start_fade_out()
			else:
				captured_deer.queue_free()

		await get_tree().create_timer(0.5).timeout
		queue_free()
	else:
		queue_free()

func _on_capture_area_entered(body):
	if body.has_method("get_captured") and not has_captured:
		has_captured = true
		captured_deer = body
		body.get_captured()
		linear_velocity *= 0.1
		angular_velocity *= 0.1
