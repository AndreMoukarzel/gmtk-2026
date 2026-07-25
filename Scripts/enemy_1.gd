extends CharacterBody3D

@export_category("Vida")
@export var max_health: float = 100.0

@export_category("Knockback")
@export var knockback_strength: float = 5.0
@export var knockback_deceleration: float = 12.0

@export_category("Movimento")
@export var hop_speed: float = 3.0
@export var hop_height: float = 3.5
@export var gravity: float = 12.0
@export var min_wait_time: float = 0.5
@export var max_wait_time: float = 1.5

@export_category("Morte")
@export var death_fade_duration: float = 0.5

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var hitbox: Area3D = $Hitbox
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var health: float
var is_dead: bool = false

var can_hop: bool = false
var is_hopping: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	health = max_health
	hitbox.area_entered.connect(_on_hitbox_area_entered)

	# Começa o ciclo de saltinhos.
	start_waiting()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravidade.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Terminou o salto quando tocou o chão.
		if is_hopping and velocity.y <= 0.0:
			is_hopping = false
			velocity.x = 0.0
			velocity.z = 0.0

			start_waiting()

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


func start_waiting() -> void:
	if is_dead or can_hop:
		return

	can_hop = true

	var wait_time := randf_range(
		min_wait_time,
		max_wait_time
	)

	await get_tree().create_timer(wait_time).timeout

	can_hop = false

	if is_dead or not is_on_floor():
		return

	hop_randomly()


func hop_randomly() -> void:
	if is_dead or is_hopping:
		return

	# Escolhe um ângulo aleatório em 360 graus.
	var random_angle := randf_range(0.0, TAU)

	var direction := Vector3(
		cos(random_angle),
		0.0,
		sin(random_angle)
	).normalized()

	velocity.x = direction.x * hop_speed
	velocity.z = direction.z * hop_speed
	velocity.y = hop_height

	is_hopping = true


func _on_hitbox_area_entered(area: Area3D) -> void:
	if is_dead:
		return

	if not area.is_in_group("bullet"):
		return

	var damage: float = 10.0

	if "damage" in area:
		damage = area.damage

	take_damage(damage, area.global_position)

	area.queue_free()


func take_damage(damage: float, bullet_position: Vector3) -> void:
	if is_dead:
		return

	health -= damage

	apply_knockback(bullet_position)

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
	collision_shape.set_deferred("disabled", true)

	var material := mesh.get_active_material(0)

	if material != null:
		material = material.duplicate()
		mesh.set_surface_override_material(0, material)

		if material is StandardMaterial3D:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

			var tween := create_tween()

			tween.tween_property(
				material,
				"albedo_color:a",
				0.0,
				death_fade_duration
			)

			await tween.finished

	queue_free()
