extends Area3D

## Marker volume where the player is allowed to drop inventory items.


func _ready() -> void:
	add_to_group("item_droppable_area")
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0

	var shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape != null:
		# Keep the shape for point-in-box tests; don't participate in physics.
		shape.disabled = true
