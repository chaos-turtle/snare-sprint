extends RigidBody3D

@export var max_scale: float = 0.5
@export var growth_rate: float = 2
@export var catch_radius: float = 1.0

@onready var mesh = $mesh
@onready var collision_shape = $CollisionShape3D
@onready var catch_area = $CatchArea

var caught_deer = []
var has_landed = false

func _ready():
	setup_catch_area()
	await get_tree().create_timer(5.0).timeout
	if is_inside_tree():
		queue_free()

func setup_catch_area():
	if not catch_area:
		catch_area = Area3D.new()
		catch_area.name = "CatchArea"
		add_child(catch_area)
		
		var catch_collision = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = catch_radius
		catch_collision.shape = sphere_shape
		catch_area.add_child(catch_collision)
	
	catch_area.body_entered.connect(_on_catch_area_entered)
	catch_area.body_exited.connect(_on_catch_area_exited)

func _physics_process(delta):
	if mesh.scale.x < max_scale:
		var new_scale = mesh.scale + Vector3.ONE * growth_rate * delta
		new_scale.x = min(new_scale.x, max_scale)
		new_scale.y = min(new_scale.y, max_scale)
		new_scale.z = min(new_scale.z, max_scale)
		mesh.scale = new_scale
		collision_shape.scale = new_scale
		
		if catch_area:
			var catch_collision = catch_area.get_child(0) as CollisionShape3D
			if catch_collision and catch_collision.shape is SphereShape3D:
				var sphere = catch_collision.shape as SphereShape3D
				sphere.radius = catch_radius * new_scale.x
	
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = global_position + Vector3.DOWN * 0.1
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.is_in_group("ground"):
		if not has_landed:
			_on_net_landed()
		has_landed = true

func _on_net_landed():
	catch_nearby_deer()

func catch_nearby_deer():
	var bodies_in_area = catch_area.get_overlapping_bodies()
	
	for body in bodies_in_area:
		if body.has_method("catch_deer") and body not in caught_deer:
			body.catch_deer()
			caught_deer.append(body)
			print("Caught deer!")

func _on_catch_area_entered(body):
	if has_landed and body.has_method("catch_deer") and body not in caught_deer:
		body.catch_deer()
		caught_deer.append(body)
		print("Deer walked into landed net!")

func _on_catch_area_exited(body):
	if body in caught_deer:
		caught_deer.erase(body)
