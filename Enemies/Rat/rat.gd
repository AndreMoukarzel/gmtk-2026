extends "res://Enemies/Wolf/enemy.gd"


func get_closest_target() -> Array:
	if not _is_player_targetable():
		if Base:
			var my_pos_base: Vector3 = global_position
			var base_dist: float = my_pos_base.distance_squared_to(Base.global_position)
			return [my_pos_base.direction_to(Base.global_position), base_dist]
		return [Vector3.ZERO, 999999.0]

	var my_pos: Vector3 = global_position
	var player_dist: float = my_pos.distance_squared_to(Player.global_position)

	return [my_pos.direction_to(Player.global_position), player_dist]
