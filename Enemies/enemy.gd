extends CharacterBody3D

@export_category("Targets")
@export var Player: Node3D
@export var Base: Node3D

@export_category("Health")
@export var max_health: float = 100.0

@export_category("Knockback")
@export var knockback_strength: float = 5.0
@export var knockback_deceleration: float = 12.0

@export_category("Movement")
@export var speed: float = 3.0
@export var atk_range: float = 5.0
@export var atk_damage: float = 6.0

@onready var hitbox: Area3D = $Hitbox
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var health: float
var is_dead: bool = false
var is_attacking: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO
var bounce_time := 0.0


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not is_on_floor():
		velocity.y -= 10.0 * delta

	var target_info = get_closest_target()
	var direction = target_info[0]
	var distance = target_info[1]
	
	if direction.length_squared() > 0.001:
		$Wolf.look_at(global_position + direction, Vector3.UP)
	
	if distance <= atk_range:
		attack()
		return
	
	# Bounce pelo juice
	bounce_time += delta
	$Wolf.rotation.x = deg_to_rad(6.0) * sin(bounce_time * 8.0)
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Reduz gradualmente o knockback.
	knockback_velocity.x = move_toward(
		knockback_velocity.x,
		0.0,
		knockback_deceleration * delta
	)

	knockback_velocity.z = move_toward(
		knockback_velocity.z,
		0.0,
		knockback_deceleration * delta
	)

	# Aplica o knockback junto com o movimento normal.
	velocity.x += knockback_velocity.x
	velocity.z += knockback_velocity.z

	move_and_slide()

	# Remove o knockback da velocity para não acumular.
	velocity.x -= knockback_velocity.x
	velocity.z -= knockback_velocity.z


func get_closest_target() -> Array:
	var my_pos: Vector3 = self.global_position
	if Player and Base:
		var player_dist: float = my_pos.distance_squared_to(Player.global_position)
		var base_dist: float = my_pos.distance_squared_to(Base.global_position)
		if player_dist > base_dist:
			return [my_pos.direction_to(Base.global_position), base_dist]
		return [my_pos.direction_to(Player.global_position), player_dist]
	elif Player:
		var player_dist: float = my_pos.distance_squared_to(Player.global_position)
		return [my_pos.direction_to(Player.global_position), player_dist]
	elif Base:
		var base_dist: float = my_pos.distance_squared_to(Base.global_position)
		return [my_pos.direction_to(Base.global_position), base_dist]
	return [Vector3(0, 0, 0), 999999.0]


func take_damage(
		damage: float,
		attack_origin: Vector3 = Vector3(0, 0, 0),
		_damage_type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
	) -> void:
	if is_dead:
		return

	health -= damage

	apply_knockback(attack_origin)

	if health <= 0.0:
		die()


func apply_knockback(bullet_position: Vector3) -> void:
	var knockback_direction := global_position - bullet_position
	knockback_direction.y = 0.0
	knockback_direction = knockback_direction.normalized()

	knockback_velocity.x += knockback_direction.x * knockback_strength
	knockback_velocity.z += knockback_direction.z * knockback_strength


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector3.ZERO
	knockback_velocity = Vector3.ZERO

	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)

	queue_free()


func attack() -> void:
	if is_attacking:
		return
	
	is_attacking = true
	
	$Wolf/AnimationPlayer.play("attack")
	await get_tree().create_timer(0.8).timeout
	var bodies = $Wolf/Attack.get_overlapping_bodies()
	if len(bodies) > 0:
		for body in bodies: # Players found
			if body.has_method("take_damage"):
				body.take_damage(atk_damage, global_position)
	
	await $Wolf/AnimationPlayer.animation_finished
	is_attacking = false


func _on_hitbox_area_entered(area: Area3D) -> void:
	take_damage(area.damage, area.global_position)

	if area.is_in_group("despawn_on_hit"):
		area.queue_free()
