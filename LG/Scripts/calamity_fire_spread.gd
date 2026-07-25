class_name CalamityFireSpread
extends Node3D

const CALAMITY_ID: String = "calamity_firespread"

@export_category("References")
@export var calamity_controller: CalamityController
@export var fire_floor_scene: PackedScene
@export var spawn_collision: CollisionShape3D

@export_category("Fire Spread")
@export_range(1, 500, 1) var fire_amount: int = 40
@export var minimum_spacing: float = 3.0
@export var spawn_height: float = 0.05
@export var maximum_spawn_attempts: int = 1000

var spawned_fires: Array[Node3D] = []
var occupied_positions: Array[Vector3] = []

# Guarda quais execuções desta calamidade estão ativas.
var active_instance_ids: Array[int] = []


func _ready() -> void:
	if calamity_controller == null:
		push_error(
			"CalamityController não foi configurado na CalamityFireSpread."
		)
		return

	calamity_controller.calamity_started.connect(
		_on_calamity_started
	)

	calamity_controller.calamity_finished.connect(
		_on_calamity_finished
	)


func _on_calamity_started(
	instance_id: int,
	calamity: CalamityData
) -> void:
	if calamity.calamity_id != CALAMITY_ID:
		return

	if instance_id in active_instance_ids:
		return

	active_instance_ids.append(instance_id)

	if active_instance_ids.size() > 1:
		return

	spawn_fires()


func _on_calamity_finished(
	instance_id: int,
	calamity: CalamityData
) -> void:
	if calamity.calamity_id != CALAMITY_ID:
		return

	active_instance_ids.erase(instance_id)

	if not active_instance_ids.is_empty():
		return

	clear_fires()


func spawn_fires() -> void:
	if fire_floor_scene == null:
		push_error("Fire Floor Scene não foi configurada.")
		return

	if spawn_collision == null:
		push_error("Spawn Collision não foi configurado.")
		return

	var box_shape := spawn_collision.shape as BoxShape3D

	if box_shape == null:
		push_error(
			"O Spawn Collision precisa usar um BoxShape3D."
		)
		return

	clear_fires()

	var attempts: int = 0

	while spawned_fires.size() < fire_amount:
		if attempts >= maximum_spawn_attempts:
			push_warning(
				"Não foi possível criar todos os fogos. Criados: %d de %d."
				% [spawned_fires.size(), fire_amount]
			)
			break

		attempts += 1

		var spawn_position := get_random_position(box_shape)

		if position_is_occupied(spawn_position):
			continue

		create_fire(spawn_position)


func get_random_position(box_shape: BoxShape3D) -> Vector3:
	var half_size := box_shape.size * 0.5

	var local_position := Vector3(
		randf_range(-half_size.x, half_size.x),
		spawn_height,
		randf_range(-half_size.z, half_size.z)
	)

	return spawn_collision.to_global(local_position)


func position_is_occupied(candidate_position: Vector3) -> bool:
	var candidate_2d := Vector2(
		candidate_position.x,
		candidate_position.z
	)

	for occupied_position in occupied_positions:
		var occupied_2d := Vector2(
			occupied_position.x,
			occupied_position.z
		)

		if candidate_2d.distance_to(occupied_2d) < minimum_spacing:
			return true

	return false


func create_fire(spawn_position: Vector3) -> void:
	var fire := fire_floor_scene.instantiate() as Node3D

	if fire == null:
		push_error(
			"A raiz da cena Fire Floor precisa herdar de Node3D."
		)
		return

	add_child(fire)

	fire.global_position = spawn_position

	spawned_fires.append(fire)
	occupied_positions.append(spawn_position)


func clear_fires() -> void:
	for fire in spawned_fires:
		if is_instance_valid(fire):
			fire.queue_free()

	spawned_fires.clear()
	occupied_positions.clear()
