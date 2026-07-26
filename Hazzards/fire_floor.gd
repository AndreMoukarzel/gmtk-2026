extends Area3D

@export var damage_per_tick: float = 20.0
@export var damage_interval: float = 1.0

@onready var damage_timer: Timer = $DamageTimer
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

## Original mesh proportions from fire_floor.tscn (bottom_radius as reference).
const _REF_BOTTOM_RADIUS := 3.0
const _REF_TOP_RADIUS := 2.035
const _REF_SHAPE_RADIUS := 2.805

var bodies_inside: Array[Node3D] = []

var _cylinder_mesh: CylinderMesh
var _cylinder_shape: CylinderShape3D
var _current_diameter: float = _REF_BOTTOM_RADIUS * 2.0
var _max_diameter: float = _REF_BOTTOM_RADIUS * 2.0
var _growth_speed: float = 0.0


func _ready() -> void:
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	_ensure_unique_resources()
	set_process(false)


## start_diameter: size at spawn. growth_speed: diameter units/sec (0 = static).
## max_diameter: growth cap (ignored when growth_speed is 0).
func configure(
	start_diameter: float,
	growth_speed: float = 0.0,
	max_diameter: float = -1.0
) -> void:
	_ensure_unique_resources()

	start_diameter = maxf(start_diameter, 0.05)
	_growth_speed = maxf(growth_speed, 0.0)

	if max_diameter < 0.0:
		max_diameter = start_diameter
	_max_diameter = maxf(max_diameter, start_diameter)

	_set_diameter(start_diameter)
	set_process(_growth_speed > 0.0 and _current_diameter < _max_diameter)


func _process(delta: float) -> void:
	if _growth_speed <= 0.0 or _current_diameter >= _max_diameter:
		set_process(false)
		return

	_set_diameter(
		minf(_current_diameter + _growth_speed * delta, _max_diameter)
	)

	if _current_diameter >= _max_diameter:
		set_process(false)


func _ensure_unique_resources() -> void:
	if mesh_instance == null:
		mesh_instance = $MeshInstance3D
	if collision_shape == null:
		collision_shape = $CollisionShape3D

	if _cylinder_mesh == null:
		var mesh := mesh_instance.mesh as CylinderMesh
		if mesh == null:
			mesh = CylinderMesh.new()
		else:
			mesh = mesh.duplicate() as CylinderMesh
		mesh_instance.mesh = mesh
		_cylinder_mesh = mesh

	if _cylinder_shape == null:
		var shape := collision_shape.shape as CylinderShape3D
		if shape == null:
			shape = CylinderShape3D.new()
		else:
			shape = shape.duplicate() as CylinderShape3D
		collision_shape.shape = shape
		_cylinder_shape = shape


func _set_diameter(diameter: float) -> void:
	_current_diameter = maxf(diameter, 0.05)
	var bottom_radius := _current_diameter * 0.5
	var scale_factor := bottom_radius / _REF_BOTTOM_RADIUS

	_cylinder_mesh.bottom_radius = bottom_radius
	_cylinder_mesh.top_radius = _REF_TOP_RADIUS * scale_factor
	_cylinder_shape.radius = _REF_SHAPE_RADIUS * scale_factor


func _on_body_entered(body: Node3D) -> void:
	if body not in bodies_inside:
		bodies_inside.append(body)
		$LongBurn.play()

	# Apenas inicia o timer. Não causa dano imediatamente.
	if damage_timer.is_stopped():
		damage_timer.start()


func _on_body_exited(body: Node3D) -> void:
	bodies_inside.erase(body)

	if bodies_inside.is_empty():
		damage_timer.stop()
		$LongBurn.stop()


func _on_damage_timer_timeout() -> void:
	for body in bodies_inside.duplicate():
		if not is_instance_valid(body):
			bodies_inside.erase(body)
			continue

		apply_fire_damage(body)

	if bodies_inside.is_empty():
		damage_timer.stop()


func apply_fire_damage(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(
			damage_per_tick,
			Vector3(0, 0, 0),
			DamageTypes.Type.FIRE
		)
		$DamageSFX.play()
