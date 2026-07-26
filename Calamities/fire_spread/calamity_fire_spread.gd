class_name CalamityFireSpread
extends Node3D

const CALAMITY_ID: String = "calamity_firespread"
## Physics layer 1 = "Floor" in project.godot
const GROUND_COLLISION_MASK: int = 1
## Optional level marker under Castle (or elsewhere) for base courtyard fire.
const BASE_SPAWN_SHAPE_NAME: String = "BoxForFireCalamityToHitBase"
## Reject ground hits steeper than this (degrees from world up).
const MAX_SLOPE_DEGREES: float = 10.0

@export_category("References")
@export var calamity_controller: CalamityController
@export var fire_floor_scene: PackedScene
## Extra spawn box (e.g. castle courtyard). Filled at base_coverage_percent.
@export var base_spawn_shape: CollisionShape3D

@export_category("Fire Spread")
## Approximate share of the field SpawnArea covered by fire footprints at spawn size.
@export_range(1.0, 100.0, 0.5) var coverage_percent: float = 15.0
## Coverage for base_spawn_shape only (default: fill the whole box).
@export_range(1.0, 100.0, 0.5) var base_coverage_percent: float = 100.0
## Diameter of each fire patch when it first appears.
@export var spawn_diameter: float = 6.0
## How fast each fire's diameter grows (units/sec). 0 = static size.
@export var growth_speed: float = 0.0
## Maximum diameter while growing (ignored when growth_speed is 0).
@export var max_diameter: float = 12.0
## Small lift along the ground normal to avoid z-fighting.
@export var spawn_height: float = 0.05
@export var maximum_spawn_attempts: int = 1000

@onready var spawn_collision: CollisionShape3D = $SpawnArea/CollisionShape3D

## World Y where downward rays start. Keep above the highest map point.
var ray_start_height: float = 40.0
## How far downward each ray travels from ray_start_height.
var ray_length: float = 100.0

var spawned_fires: Array[Node3D] = []
var occupied_positions: Array[Vector3] = []

# Guarda quais execuções desta calamidade estão ativas.
var active_instance_ids: Array[int] = []


func _ready() -> void:
	_resolve_base_spawn_shape()

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


func _resolve_base_spawn_shape() -> void:
	if base_spawn_shape == null:
		var scene_root := get_tree().current_scene
		if scene_root != null:
			base_spawn_shape = scene_root.find_child(
				BASE_SPAWN_SHAPE_NAME,
				true,
				false
			) as CollisionShape3D

	if base_spawn_shape == null:
		return

	# Marker only — must not add Floor collision or steal fire rays.
	base_spawn_shape.disabled = true


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

	_resolve_base_spawn_shape()
	clear_fires()

	_spawn_fires_in_shape(spawn_collision, coverage_percent)

	if base_spawn_shape != null:
		_spawn_fires_in_shape(base_spawn_shape, base_coverage_percent)


func _spawn_fires_in_shape(
	collision: CollisionShape3D,
	coverage: float
) -> void:
	var box_shape := collision.shape as BoxShape3D
	if box_shape == null:
		push_error(
			"Spawn shape '%s' precisa usar um BoxShape3D."
			% collision.name
		)
		return

	var target_count := _calculate_fire_count(box_shape, coverage)
	var spacing := maxf(spawn_diameter, 0.1)
	var attempts: int = 0
	var created_before := spawned_fires.size()

	while spawned_fires.size() - created_before < target_count:
		if attempts >= maximum_spawn_attempts:
			push_warning(
				"Não foi possível criar todos os fogos em '%s'. Criados: %d de %d."
				% [
					collision.name,
					spawned_fires.size() - created_before,
					target_count,
				]
			)
			break

		attempts += 1

		var spawn_pose := get_ground_spawn_pose(collision, box_shape)
		if spawn_pose.is_empty():
			continue

		var spawn_position: Vector3 = spawn_pose["position"]
		if position_is_occupied(spawn_position, spacing):
			continue

		create_fire(spawn_position, spawn_pose["normal"])


func _calculate_fire_count(box_shape: BoxShape3D, coverage: float) -> int:
	var area := absf(box_shape.size.x * box_shape.size.z)
	var radius := maxf(spawn_diameter, 0.1) * 0.5
	var fire_area := PI * radius * radius
	var target := int(
		ceil(area * (coverage / 100.0) / maxf(fire_area, 0.001))
	)
	return clampi(target, 1, 500)


func get_ground_spawn_pose(
	collision: CollisionShape3D,
	box_shape: BoxShape3D
) -> Dictionary:
	var half_size := box_shape.size * 0.5

	var local_position := Vector3(
		randf_range(-half_size.x, half_size.x),
		0.0,
		randf_range(-half_size.z, half_size.z)
	)

	var global_xz := collision.to_global(local_position)
	var ray_origin := Vector3(global_xz.x, ray_start_height, global_xz.z)
	var ray_end := ray_origin + Vector3.DOWN * ray_length

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return {}

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = GROUND_COLLISION_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return {}

	var normal: Vector3 = hit["normal"]
	if normal.length_squared() < 0.0001:
		normal = Vector3.UP
	else:
		normal = normal.normalized()

	# Skip steep ground so fire discs don't clip through slopes/cliffs.
	if normal.angle_to(Vector3.UP) >= deg_to_rad(MAX_SLOPE_DEGREES):
		return {}

	var pos: Vector3 = hit["position"] + normal * spawn_height
	return {
		"position": pos,
		"normal": normal,
	}


func position_is_occupied(
	candidate_position: Vector3,
	spacing: float
) -> bool:
	var candidate_2d := Vector2(
		candidate_position.x,
		candidate_position.z
	)

	for occupied_position in occupied_positions:
		var occupied_2d := Vector2(
			occupied_position.x,
			occupied_position.z
		)

		if candidate_2d.distance_to(occupied_2d) < spacing:
			return true

	return false


func create_fire(spawn_position: Vector3, ground_normal: Vector3) -> void:
	var fire := fire_floor_scene.instantiate() as Node3D

	if fire == null:
		push_error(
			"A raiz da cena Fire Floor precisa herdar de Node3D."
		)
		return

	add_child(fire)

	fire.global_position = spawn_position
	_align_y_to_normal(fire, ground_normal)

	if fire.has_method("configure"):
		fire.configure(spawn_diameter, growth_speed, max_diameter)

	spawned_fires.append(fire)
	occupied_positions.append(spawn_position)


func _align_y_to_normal(node: Node3D, normal: Vector3) -> void:
	var up := normal.normalized()
	var tangent := Vector3.RIGHT.cross(up)
	if tangent.length_squared() < 0.001:
		tangent = Vector3.FORWARD.cross(up)
	tangent = tangent.normalized()
	var bitangent := up.cross(tangent).normalized()
	node.global_basis = Basis(tangent, up, bitangent).orthonormalized()


func clear_fires() -> void:
	for fire in spawned_fires:
		if is_instance_valid(fire):
			fire.queue_free()

	spawned_fires.clear()
	occupied_positions.clear()
