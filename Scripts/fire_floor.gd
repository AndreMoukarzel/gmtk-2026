# Fire Floor
extends Area3D

@export var damage_per_tick: float = 10.0
@export var damage_interval: float = 1.0

@onready var damage_timer: Timer = $DamageTimer

var bodies_inside: Array[Node3D] = []


func _ready() -> void:
	damage_timer.timeout.connect(_on_damage_timer_timeout)

	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false


func _on_body_entered(body: Node3D) -> void:
	if body not in bodies_inside:
		bodies_inside.append(body)

	# Apenas inicia o timer. Não causa dano imediatamente.
	if damage_timer.is_stopped():
		damage_timer.start()


func _on_body_exited(body: Node3D) -> void:
	bodies_inside.erase(body)

	if bodies_inside.is_empty():
		damage_timer.stop()


func _on_damage_timer_timeout() -> void:
	for body in bodies_inside.duplicate():
		if not is_instance_valid(body):
			bodies_inside.erase(body)
			continue

		apply_fire_damage(body)

	if bodies_inside.is_empty():
		damage_timer.stop()


func apply_fire_damage(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(
			damage_per_tick,
			Vector3(0, 0, 0),
			DamageTypes.Type.FIRE
		)
