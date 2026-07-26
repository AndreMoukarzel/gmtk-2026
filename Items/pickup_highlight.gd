class_name PickupHighlight
extends RefCounted

const OUTLINE_SHADER_PATH := "res://Shaders/item_pickup_outline.gdshader"
const META_KEY := &"pickup_highlight_restore"

static var _outline_material: ShaderMaterial


static func get_outline_material() -> ShaderMaterial:
	if _outline_material != null:
		return _outline_material

	var shader := load(OUTLINE_SHADER_PATH) as Shader
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = shader
	_outline_material.render_priority = 10
	_outline_material.set_shader_parameter("outline_color", Color(0.35, 0.7, 1.0))
	_outline_material.set_shader_parameter("fresnel_power", 1.4)
	_outline_material.set_shader_parameter("emission_strength", 18.0)
	_outline_material.set_shader_parameter("rim_floor", 0.12)
	return _outline_material


static func set_highlighted(item: Node3D, active: bool) -> void:
	if item == null or not is_instance_valid(item):
		return

	var meshes := _collect_item_meshes(item)

	for mesh_instance in meshes:
		if active:
			_apply_highlight(mesh_instance)
		else:
			_clear_highlight(mesh_instance)


static func _apply_highlight(mesh_instance: MeshInstance3D) -> String:
	var outline := get_outline_material()

	# Prefer next_pass on a duplicated active material — more reliable than overlay
	# alone on imported meshes / material_override setups.
	if mesh_instance.material_override != null:
		if not mesh_instance.has_meta(META_KEY):
			mesh_instance.set_meta(META_KEY, {
				"mode": "override",
				"material": mesh_instance.material_override
			})
		var dup: Material = mesh_instance.material_override.duplicate()
		_set_next_pass(dup, outline)
		mesh_instance.material_override = dup
		mesh_instance.material_overlay = outline
		return "override_next_pass+overlay"

	var surface_count := 0
	if mesh_instance.mesh != null:
		surface_count = mesh_instance.mesh.get_surface_count()

	if surface_count > 0:
		var saved_surfaces: Array = []
		for surface_index in surface_count:
			saved_surfaces.append(mesh_instance.get_surface_override_material(surface_index))
			var active_material := mesh_instance.get_active_material(surface_index)
			var dup: Material
			if active_material != null:
				dup = active_material.duplicate()
			else:
				dup = StandardMaterial3D.new()
			_set_next_pass(dup, outline)
			mesh_instance.set_surface_override_material(surface_index, dup)

		if not mesh_instance.has_meta(META_KEY):
			mesh_instance.set_meta(META_KEY, {
				"mode": "surfaces",
				"surfaces": saved_surfaces
			})
		mesh_instance.material_overlay = outline
		return "surface_next_pass+overlay"

	mesh_instance.material_overlay = outline
	return "overlay_only"


static func _clear_highlight(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.material_overlay = null

	if not mesh_instance.has_meta(META_KEY):
		return

	var restore: Dictionary = mesh_instance.get_meta(META_KEY)
	mesh_instance.remove_meta(META_KEY)

	match restore.get("mode", ""):
		"override":
			mesh_instance.material_override = restore.get("material")
		"surfaces":
			var saved_surfaces: Array = restore.get("surfaces", [])
			for surface_index in saved_surfaces.size():
				mesh_instance.set_surface_override_material(
					surface_index,
					saved_surfaces[surface_index]
				)


static func _set_next_pass(material: Material, outline: Material) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).next_pass = outline
	elif material is BaseMaterial3D:
		(material as BaseMaterial3D).next_pass = outline


static func _collect_item_meshes(root: Node) -> Array[MeshInstance3D]:
	# Highlight only the floor aura cylinder, never the item model.
	var meshes: Array[MeshInstance3D] = []

	var aura := root.get_node_or_null("Aura")
	if aura is MeshInstance3D:
		meshes.append(aura as MeshInstance3D)
		return meshes

	# Speed boots (and similar) use an unnamed MeshInstance3D cylinder.
	for child in root.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			if mesh_instance.mesh is CylinderMesh:
				meshes.append(mesh_instance)
				return meshes

	for child in root.get_children():
		if child is MeshInstance3D:
			meshes.append(child as MeshInstance3D)
			return meshes

	return meshes
