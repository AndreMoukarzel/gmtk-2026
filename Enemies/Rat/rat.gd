extends "res://Enemies/Wolf/enemy.gd"


func get_closest_target() -> Array:
	var my_pos: Vector3 = self.global_position
	var player_dist: float = my_pos.distance_squared_to(Player.global_position)
	
	return [my_pos.direction_to(Player.global_position), player_dist]
