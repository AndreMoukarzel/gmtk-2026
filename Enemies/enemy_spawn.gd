extends Area3D


@export_range(1, 300, 1) var MAX_ENEMYS: int = 90
@export var ENEMY_SCN: PackedScene


func spawn_enemies(amount: int) -> void:
	var current_enemies: int = $"../Enemies".get_child_count()
	
	for _i in range(min(amount, MAX_ENEMYS - current_enemies)):
		var Enemy = ENEMY_SCN.instantiate()
		var random_pos: Vector3 = random_point_in_area(self)
		
		Enemy.Player = $"../Player"
		Enemy.Base = $"../Base Hitbox"
		$"../Enemies".add_child(Enemy)
		Enemy.global_position = Vector3(random_pos.x, 1.0, random_pos.z)


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


func _on_calamity_controller_calamity_started(instance_id: int, _calamity: CalamityData) -> void:
	spawn_enemies(50)
