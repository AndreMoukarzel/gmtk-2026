extends Area3D

signal health_changed(current: float, maximum: float)

@export var max_health: float = 200.0
@export var damage_per_hit: float = 10.0
var health: float


func _ready() -> void:
	add_to_group("base_hitbox")
	health = max_health
	health_changed.emit(health, max_health)


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_trigger_game_over()


func _on_body_entered(body: Node3D) -> void:
	take_damage(damage_per_hit)

	if body.has_method("die"):
		body.die()


func _trigger_game_over() -> void:
	var game_over := get_tree().get_first_node_in_group("game_over_ui")
	if game_over != null and game_over.has_method("trigger"):
		game_over.trigger()
