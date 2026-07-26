extends Area3D

@export var max_health: float = 200.0
@export var damage_per_hit: float = 10.0
var health: float


func _ready() -> void:
	health = max_health


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	print (health)
	if health <= 0.0:
		pass
		


func _on_body_entered(body: Node3D) -> void:
	take_damage(damage_per_hit)

	if body.has_method("die"):
		body.die()
