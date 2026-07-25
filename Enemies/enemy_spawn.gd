extends Area3D

@export var ENEMY_SCN: PackedScene


func _ready() -> void:
	spawn_enemies(300)


func spawn_enemies(amount: int) -> void:
	for _i in range(amount):
		var Enemy = ENEMY_SCN.instantiate()
		var random_pos: Vector3 = random_point_in_area(self)
		
		Enemy.Player = $"../Player"
		Enemy.global_position = Vector3(random_pos.x, 0.2, random_pos.z)
		
		$"../Enemies".add_child(Enemy)


func random_point_in_area(area: Area3D) -> Vector3:
	var collision_shape = area.get_node("CollisionShape3D")
	var box := collision_shape.shape as BoxShape3D

	var extents = box.size * 0.5

	var local_point = Vector3(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y),
		randf_range(-extents.z, extents.z)
	)

	return collision_shape.global_transform * local_point
