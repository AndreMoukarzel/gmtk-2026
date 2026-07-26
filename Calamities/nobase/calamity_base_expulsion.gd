class_name CalamityBaseExpulsion
extends Node3D


const CALAMITY_ID: String = "calamity_base_expulsion"


@export_category("References")
@export var calamity_controller: CalamityController
@export var player: CharacterBody3D
@export var player_collision: CollisionShape3D
@export var base_area: Area3D
@export var outside_base_point: Marker3D

@export_category("Effect")
@export_range(0.1, 300.0, 0.1) var effect_duration: float = 10.0
@export_range(0.1, 5.0, 0.1) var propulsion_duration: float = 0.7
@export_range(0.0, 10.0, 0.1) var propulsion_height: float = 2.5


var effect_active: bool = false
var is_propelling_player: bool = false
var active_instance_id: int = -1


func _ready() -> void:
	if calamity_controller == null:
		push_error(
			"CalamityBaseExpulsion: CalamityController não configurado."
		)
		return

	if player == null:
		push_error(
			"CalamityBaseExpulsion: Player não configurado."
		)
		return

	if player_collision == null:
		push_error(
			"CalamityBaseExpulsion: Player Collision não configurado."
		)
		return

	if base_area == null:
		push_error(
			"CalamityBaseExpulsion: Base Area não configurada."
		)
		return

	if outside_base_point == null:
		push_error(
			"CalamityBaseExpulsion: Outside Base Point não configurado."
		)
		return

	calamity_controller.calamity_started.connect(
		_on_calamity_started
	)

	base_area.body_entered.connect(
		_on_base_area_body_entered
	)


func _on_calamity_started(
	instance_id: int,
	calamity: CalamityData
) -> void:
	if calamity == null:
		return

	if calamity.calamity_id != CALAMITY_ID:
		return

	start_expulsion_effect(instance_id)


func start_expulsion_effect(instance_id: int) -> void:
	effect_active = true
	active_instance_id = instance_id

	await get_tree().physics_frame

	if base_area.overlaps_body(player):
		propel_player_outside()

	await get_tree().create_timer(effect_duration, false).timeout

	if active_instance_id != instance_id:
		return

	effect_active = false
	active_instance_id = -1

	print("Calamidade de expulsão finalizada.")


func _on_base_area_body_entered(body: Node3D) -> void:
	if not effect_active:
		return

	if body != player:
		return

	if is_propelling_player:
		return

	call_deferred("propel_player_outside")


func propel_player_outside() -> void:
	if not effect_active:
		return

	if is_propelling_player:
		return

	if not is_instance_valid(player):
		return

	is_propelling_player = true

	player.velocity = Vector3.ZERO
	player.set_physics_process(false)

	# Desativa a colisão para atravessar as paredes.
	player_collision.set_deferred("disabled", true)

	var start_position: Vector3 = player.global_position
	var target_position: Vector3 = outside_base_point.global_position

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		func(progress: float) -> void:
			var position := start_position.lerp(
				target_position,
				progress
			)

			# Cria um arco durante a propulsão.
			position.y += sin(progress * PI) * propulsion_height

			player.global_position = position,
		0.0,
		1.0,
		propulsion_duration
	)

	await tween.finished

	player.global_position = target_position
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()

	player_collision.set_deferred("disabled", false)
	player.set_physics_process(true)

	is_propelling_player = false

	print("Player arremessado para fora da base.")
