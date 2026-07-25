# SwordSlash
extends Node3D

@export var slash_arc_degrees: float = 120.0
@export var slash_height: float = 1.0

var slash_duration: float = 0.2
var sword_damage: float = 25.0
var hitbox_size: Vector3 = Vector3(2, 2, 2)
var hitbox_forward_offset: float = 1.5

@onready var sword_pivot: Node3D = $SwordPivot
@onready var hitbox: Area3D = $Hitbox
@onready var hitbox_shape: CollisionShape3D = $Hitbox/CollisionShape3D


func configure(
	duration: float,
	damage: float,
	box_size: Vector3,
	forward_offset: float
) -> void:
	slash_duration = duration
	sword_damage = damage
	hitbox_size = box_size
	hitbox_forward_offset = forward_offset


func play(aim_direction: Vector3) -> void:
	var flat_direction := Vector3(aim_direction.x, 0.0, aim_direction.z)

	if flat_direction.length_squared() < 0.0001:
		flat_direction = Vector3.FORWARD
	else:
		flat_direction = flat_direction.normalized()

	position = Vector3(0.0, slash_height, 0.0)
	look_at(global_position + flat_direction, Vector3.UP)

	_setup_hitbox()
	_play_sword_arc()
	_run_hitbox_window()


func _setup_hitbox() -> void:
	hitbox.damage = sword_damage
	hitbox.monitoring = false
	hitbox.monitorable = false
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0

	var box := hitbox_shape.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		hitbox_shape.shape = box

	box.size = hitbox_size
	hitbox.position = Vector3(0.0, 0.0, -hitbox_forward_offset)
	hitbox_shape.position = Vector3.ZERO


func _play_sword_arc() -> void:
	var half_arc := deg_to_rad(slash_arc_degrees * 0.5)
	sword_pivot.rotation.y = -half_arc

	var start_yaw := sword_pivot.rotation.y
	var end_yaw := start_yaw + deg_to_rad(slash_arc_degrees)

	var tween := create_tween()
	tween.tween_method(
		_set_sword_yaw,
		start_yaw,
		end_yaw,
		slash_duration
	)
	tween.finished.connect(queue_free)


func _set_sword_yaw(yaw: float) -> void:
	sword_pivot.rotation.y = yaw


func _run_hitbox_window() -> void:
	var enable_delay := slash_duration * 0.25
	var active_duration := slash_duration * 0.5

	await get_tree().create_timer(enable_delay).timeout

	if not is_instance_valid(self):
		return

	_enable_hitbox()

	await get_tree().create_timer(active_duration).timeout

	if not is_instance_valid(self):
		return

	_disable_hitbox()


func _enable_hitbox() -> void:
	hitbox.collision_layer = 8
	hitbox.monitorable = true
	_set_boundary_mesh_visible(true)


func _disable_hitbox() -> void:
	hitbox.collision_layer = 0
	hitbox.monitorable = false
	_set_boundary_mesh_visible(false)


func _set_boundary_mesh_visible(is_visible: bool) -> void:
	var boundary_mesh := hitbox.get_node_or_null("HitboxBoundaryMesh") as MeshInstance3D
	if boundary_mesh != null:
		boundary_mesh.visible = is_visible
