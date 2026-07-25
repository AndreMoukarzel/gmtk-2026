# SlashTrail — builds a glowing ribbon from tip samples.
extends MeshInstance3D

@export var tip_path: NodePath = ^"../SwordPivot/TipMarker"
@export var half_width: float = 0.28
@export var max_points: int = 32
@export var min_point_distance: float = 0.02
@export var fade_duration: float = 0.28

var _tip: Node3D
var _points: PackedVector3Array = PackedVector3Array()
var _recording: bool = false
var _fading: bool = false
var _fade: float = 1.0
var _material: ShaderMaterial


func _ready() -> void:
	_resolve_tip()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_setup_material()
	mesh = ArrayMesh.new()


func _resolve_tip() -> void:
	_tip = get_node_or_null(tip_path) as Node3D
	if _tip != null:
		return
	if get_parent() != null:
		_tip = get_parent().get_node_or_null("SwordPivot/TipMarker") as Node3D


func _setup_material() -> void:
	var shader := load("res://Shaders/sword_slash_trail.gdshader") as Shader
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.render_priority = 12
	_material.set_shader_parameter("core_color", Color(1.0, 1.0, 1.0, 1.0))
	_material.set_shader_parameter("glow_color", Color(0.35, 0.75, 1.0, 1.0))
	_material.set_shader_parameter("emission_strength", 10.0)
	_material.set_shader_parameter("fade", 1.0)
	_material.set_shader_parameter("core_width", 0.16)
	material_override = _material


func start_trail() -> void:
	_points.clear()
	_recording = true
	_fading = false
	_fade = 1.0
	if _material != null:
		_material.set_shader_parameter("fade", 1.0)
	_sample_tip(true)
	_rebuild_mesh()


func stop_and_fade() -> void:
	_recording = false
	_fading = true
	_sample_tip(true)
	_rebuild_mesh()


func is_finished() -> bool:
	return _fading and _fade <= 0.0


func _process(delta: float) -> void:
	if _recording:
		_sample_tip(false)
		_rebuild_mesh()
		return

	if not _fading:
		return

	_fade = maxf(_fade - delta / maxf(fade_duration, 0.001), 0.0)
	if _material != null:
		_material.set_shader_parameter("fade", _fade)
	_rebuild_mesh()


func _sample_tip(force: bool) -> void:
	if _tip == null or not is_instance_valid(_tip):
		return

	var local_point := to_local(_tip.global_position)
	if not force and not _points.is_empty():
		if _points[_points.size() - 1].distance_to(local_point) < min_point_distance:
			return

	_points.append(local_point)
	while _points.size() > max_points:
		_points.remove_at(0)


func _rebuild_mesh() -> void:
	var array_mesh := mesh as ArrayMesh
	if array_mesh == null:
		array_mesh = ArrayMesh.new()
		mesh = array_mesh

	array_mesh.clear_surfaces()

	var point_count := _points.size()
	if point_count < 2 or _fade <= 0.0:
		return

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	vertices.resize(point_count * 2)
	normals.resize(point_count * 2)
	uvs.resize(point_count * 2)
	colors.resize(point_count * 2)

	for i in point_count:
		var t := float(i) / float(point_count - 1)
		var point := _points[i]
		var width_scale := sin(t * PI)
		width_scale = maxf(width_scale, 0.15)
		var width := half_width * width_scale * lerpf(1.0, 0.35, 1.0 - _fade)

		var up := Vector3.UP * width
		vertices[i * 2] = point + up
		vertices[i * 2 + 1] = point - up
		normals[i * 2] = Vector3.FORWARD
		normals[i * 2 + 1] = Vector3.FORWARD
		uvs[i * 2] = Vector2(t, 0.0)
		uvs[i * 2 + 1] = Vector2(t, 1.0)
		colors[i * 2] = Color(1, 1, 1, 1)
		colors[i * 2 + 1] = Color(1, 1, 1, 1)

	for i in point_count - 1:
		var a := i * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3
		indices.append_array([a, c, b, b, c, d])

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_material(0, _material)
