extends Area3D

@export var ammo_amount: int = 3

signal picked_up

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		body.add_ammo(ammo_amount)
		emit_signal("picked_up")
		queue_free()
