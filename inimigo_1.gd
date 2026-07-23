extends CharacterBody3D

@export var speed: float = 3.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0 # tempo mínimo entre ataques

var player: Node3D
var can_attack: bool = true


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player:
		var direction := (player.global_position - global_position)
		direction.y = 0
		direction = direction.normalized()

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# gira o inimigo pra encarar o jogador
		if direction:
			rotation.y = atan2(direction.x, direction.z)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()


func _on_hit_box_body_entered(body: Node3D) -> void:
	if can_attack and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
