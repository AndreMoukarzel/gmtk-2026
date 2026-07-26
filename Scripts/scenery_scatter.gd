extends Node3D

## Fills MultiMeshInstance3D props inside ScatterZones CollisionShape3D boxes.
## Zones are markers only (no physics). Points that miss Floor are skipped.

const GROUND_COLLISION_MASK: int = 1
const RAY_START_HEIGHT: float = 80.0
const RAY_LENGTH: float = 200.0

@export_category("General")
@export var random_seed: int = 42
@export var max_slope_degrees: float = 28.0
@export var max_attempts_multiplier: int = 12
@export var height_offset: float = 0.02

@export_category("ForestZone (trees)")
@export var forest_density: float = 0.004
@export var forest_min_spacing: float = 7.0
@export var forest_scale_min: float = 1.7
@export var forest_scale_max: float = 2.5

@export_category("MuddyRocksZone")
@export var muddy_density: float = 0.012
@export var muddy_min_spacing: float = 3.5
@export var muddy_scale_min: float = 0.7
@export var muddy_scale_max: float = 1.4

@export_category("GreyRocksZone")
@export var grey_density: float = 0.01
@export var grey_min_spacing: float = 3.5
@export var grey_scale_min: float = 0.7
@export var grey_scale_max: float = 1.35

@onready var zones_area: Area3D = $Area3D

var _rng := RandomNumberGenerator.new()
var _multimesh_root: Node3D
## mesh path -> Array[Transform3D]
var _transforms_by_mesh: Dictionary = {}


func _ready() -> void:
	_configure_marker_area()
	_rng.seed = random_seed
	_multimesh_root = Node3D.new()
	_multimesh_root.name = "ScatteredProps"
	add_child(_multimesh_root)
	# Wait until physics is ready so Floor raycasts hit the map.
	call_deferred("_scatter_deferred")


func _scatter_deferred() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_scatter_all_zones()
	_build_multimeshes()


func _configure_marker_area() -> void:
	if zones_area == null:
		return
	zones_area.monitoring = false
	zones_area.monitorable = false
	zones_area.collision_layer = 0
	zones_area.collision_mask = 0
	for child in zones_area.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = true


func _scatter_all_zones() -> void:
	if zones_area == null:
		push_error("SceneryScatter: Area3D with zones not found.")
		return

	for child in zones_area.get_children():
		var shape_node := child as CollisionShape3D
		if shape_node == null:
			continue
		var box := shape_node.shape as BoxShape3D
		if box == null:
			push_warning("SceneryScatter: '%s' needs a BoxShape3D." % shape_node.name)
			continue

		var config := _config_for_zone(shape_node.name)
		if config.is_empty():
			push_warning("SceneryScatter: no prop config for zone '%s'." % shape_node.name)
			continue

		_scatter_zone(shape_node, box, config)


func _config_for_zone(zone_name: String) -> Dictionary:
	match zone_name:
		"ForestZone":
			return {
				"meshes": [
					"res://Assets/Models/Map/Scenery/trees/tree_1_mesh.res",
					"res://Assets/Models/Map/Scenery/trees/tree_2_mesh.res",
					"res://Assets/Models/Map/Scenery/trees/tree_3_mesh.res",
					"res://Assets/Models/Map/Scenery/trees/tree_4_mesh.res",
				],
				"density": forest_density,
				"min_spacing": forest_min_spacing,
				"scale_min": forest_scale_min,
				"scale_max": forest_scale_max,
				"align_to_normal": false,
			}
		"MuddyRocksZone":
			return {
				"meshes": [
					"res://Assets/Models/Map/Scenery/rocks/rock_1_mesh.res",
					"res://Assets/Models/Map/Scenery/rocks/rock_2_mesh.res",
					"res://Assets/Models/Map/Scenery/rocks/rock_3_mesh.res",
					"res://Assets/Models/Map/Scenery/rocks/rock_4_mesh.res",
				],
				"density": muddy_density,
				"min_spacing": muddy_min_spacing,
				"scale_min": muddy_scale_min,
				"scale_max": muddy_scale_max,
				"align_to_normal": true,
			}
		"GreyRocksZone":
			return {
				"meshes": [
					"res://Assets/Models/Map/Scenery/rocks/grey_rock_1_mesh.res",
					"res://Assets/Models/Map/Scenery/rocks/grey_rock_2_mesh.res",
					"res://Assets/Models/Map/Scenery/rocks/grey_rock_3_mesh.res",
					"res://Assets/Models/Map/Scenery/rocks/grey_rock_4_mesh.res",
				],
				"density": grey_density,
				"min_spacing": grey_min_spacing,
				"scale_min": grey_scale_min,
				"scale_max": grey_scale_max,
				"align_to_normal": true,
			}
		_:
			return {}


func _scatter_zone(
	shape_node: CollisionShape3D,
	box: BoxShape3D,
	config: Dictionary
) -> void:
	var footprint := absf(box.size.x * box.size.z)
	var density: float = config["density"]
	var min_spacing: float = config["min_spacing"]
	var target := clampi(int(ceil(footprint * density)), 1, 800)
	var max_attempts := maxi(target * max_attempts_multiplier, target + 50)

	var mesh_paths: Array = config["meshes"]
	var placed_xz: Array[Vector2] = []
	var attempts := 0

	while placed_xz.size() < target and attempts < max_attempts:
		attempts += 1

		var half := box.size * 0.5
		var local := Vector3(
			_rng.randf_range(-half.x, half.x),
			0.0,
			_rng.randf_range(-half.z, half.z)
		)
		var world_xz := shape_node.to_global(local)
		var ground := _raycast_ground(world_xz.x, world_xz.z)
		if ground.is_empty():
			continue

		var normal: Vector3 = ground["normal"]
		if normal.angle_to(Vector3.UP) >= deg_to_rad(max_slope_degrees):
			continue

		var pos: Vector3 = ground["position"]
		var pos2 := Vector2(pos.x, pos.z)
		if _too_close(pos2, placed_xz, min_spacing):
			continue

		var mesh_path: String = mesh_paths[_rng.randi_range(0, mesh_paths.size() - 1)]
		var mesh := _get_mesh(mesh_path)
		if mesh == null:
			continue

		var scale := _rng.randf_range(config["scale_min"], config["scale_max"])
		var xform := _make_transform(
			ground["position"],
			normal,
			scale,
			config["align_to_normal"],
			mesh
		)

		if not _transforms_by_mesh.has(mesh_path):
			_transforms_by_mesh[mesh_path] = []
		(_transforms_by_mesh[mesh_path] as Array).append(xform)
		placed_xz.append(pos2)

	if placed_xz.size() < target:
		push_warning(
			"SceneryScatter: '%s' placed %d / %d (some points missed Floor or spacing)."
			% [shape_node.name, placed_xz.size(), target]
		)


func _raycast_ground(x: float, z: float) -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return {}

	var origin := Vector3(x, RAY_START_HEIGHT, z)
	var end := origin + Vector3.DOWN * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, end)
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

	return {
		"position": hit["position"],
		"normal": normal,
	}


func _too_close(candidate: Vector2, placed: Array[Vector2], min_spacing: float) -> bool:
	for p in placed:
		if candidate.distance_to(p) < min_spacing:
			return true
	return false


var _mesh_cache: Dictionary = {}


func _get_mesh(mesh_path: String) -> Mesh:
	if _mesh_cache.has(mesh_path):
		return _mesh_cache[mesh_path] as Mesh

	var mesh := load(mesh_path) as Mesh
	if mesh != null:
		_mesh_cache[mesh_path] = mesh
	return mesh


func _make_transform(
	ground_position: Vector3,
	normal: Vector3,
	uniform_scale: float,
	align_to_normal: bool,
	mesh: Mesh
) -> Transform3D:
	var yaw := _rng.randf_range(0.0, TAU)
	var basis: Basis

	if align_to_normal:
		var up := normal.normalized()
		var tangent := Vector3.RIGHT.cross(up)
		if tangent.length_squared() < 0.001:
			tangent = Vector3.FORWARD.cross(up)
		tangent = tangent.normalized()
		var bitangent := up.cross(tangent).normalized()
		basis = Basis(tangent, up, bitangent).orthonormalized()
		basis = basis.rotated(up, yaw)
	else:
		# Trees stay upright; only spin around world Y.
		basis = Basis.from_euler(Vector3(0.0, yaw, 0.0))

	basis = basis.scaled(Vector3.ONE * uniform_scale)

	# Sit the mesh AABB bottom on the ground hit (origin is often mesh center).
	var aabb := mesh.get_aabb()
	var local_bottom_lift := Vector3(0.0, -aabb.position.y, 0.0)
	var position := (
		ground_position
		+ normal.normalized() * height_offset
		+ basis * local_bottom_lift
	)

	return Transform3D(basis, position)


func _build_multimeshes() -> void:
	for mesh_path in _transforms_by_mesh.keys():
		var transforms: Array = _transforms_by_mesh[mesh_path]
		if transforms.is_empty():
			continue

		var mesh := _get_mesh(mesh_path)
		if mesh == null:
			push_warning("SceneryScatter: failed to load mesh '%s'." % mesh_path)
			continue

		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = transforms.size()

		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])

		var mmi := MultiMeshInstance3D.new()
		mmi.name = mesh_path.get_file().get_basename()
		mmi.multimesh = multimesh
		_multimesh_root.add_child(mmi)
