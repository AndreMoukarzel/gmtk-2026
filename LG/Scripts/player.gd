# Player
extends CharacterBody3D

const SPEED: float = 10.0
const ACCELERATION: float = 250.0
const DECELERATION: float = 350.0

const JUMP_VELOCITY: float = 6.0
const GRAVITY: float = 18.0

@export var shoot_origin: Marker3D

# Boost Speed
var current_speed: float

var nearby_speed_item: Area3D = null

var equipped_speed_item_scene: PackedScene = null
var equipped_speed_value: float = 0.0
var has_speed_item: bool = false

# Bullet
var nearby_bullet_item: Area3D = null

var equipped_bullet_item_scene: PackedScene = null
var equipped_bullet_scene: PackedScene = null
var has_bullet_item: bool = false

var inventory_ui: ItemUI


func _ready() -> void:
	current_speed = Game.speed

	inventory_ui = get_tree().get_first_node_in_group("item_ui") as ItemUI

	if inventory_ui == null:
		push_error("ItemUI não encontrada.")
		return

	inventory_ui.selected_item_changed.connect(
		_on_selected_item_changed
	)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("get_item"):
		print("Q pressionado")
		print("Nearby item: ", nearby_speed_item)
		try_get_item()

	if Input.is_action_just_pressed("drop_item"):
		drop_selected_item()

	# Gravidade
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Tiro
	if Input.is_action_just_pressed("shoot"):
		if can_shoot():
			shoot_at_mouse()
		else:
			print("Você não possui o ItemBullet equipado.")

	# Movimento
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var direction := Vector3(
		input_direction.x,
		0.0,
		input_direction.y
	).normalized()

	if direction != Vector3.ZERO:
		var target_velocity := direction * current_speed

		velocity.x = move_toward(
			velocity.x,
			target_velocity.x,
			ACCELERATION * delta
		)

		velocity.z = move_toward(
			velocity.z,
			target_velocity.z,
			ACCELERATION * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			DECELERATION * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			DECELERATION * delta
		)

	move_and_slide()


func can_shoot() -> bool:
	return has_bullet_item and equipped_bullet_scene != null


func shoot_at_mouse() -> void:
	if equipped_bullet_scene == null:
		push_error("ERRO: Bullet Scene não foi configurada no Inspector.")
		return

	var current_camera := get_viewport().get_camera_3d()

	if current_camera == null:
		push_error("ERRO: nenhuma Camera3D ativa encontrada.")
		return

	var mouse_position := get_viewport().get_mouse_position()

	var ray_origin := current_camera.project_ray_origin(mouse_position)
	var ray_direction := current_camera.project_ray_normal(mouse_position)

	var bullet_origin := global_position

	if shoot_origin != null:
		bullet_origin = shoot_origin.global_position

	# Plano horizontal na altura do tiro
	var shooting_plane := Plane(Vector3.UP, bullet_origin.y)

	var mouse_world_position = shooting_plane.intersects_ray(
		ray_origin,
		ray_direction
	)

	if mouse_world_position == null:
		push_error("ERRO: o raio do mouse não encontrou o plano horizontal.")
		return

	var bullet_direction: Vector3 = mouse_world_position - bullet_origin
	bullet_direction.y = 0.0
	bullet_direction = bullet_direction.normalized()

	if bullet_direction == Vector3.ZERO:
		push_error("ERRO: direção da bala ficou zerada.")
		return

	var bullet = equipped_bullet_scene.instantiate()

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = bullet_origin
	bullet.direction = bullet_direction

	print("Bala criada")
	print("Origem: ", bullet_origin)
	print("Direção: ", bullet_direction)


func set_nearby_speed_item(item: Area3D) -> void:
	nearby_speed_item = item

	print("SpeedUp próximo. Pressione get_item para pegar.")


func remove_nearby_speed_item(item: Area3D) -> void:
	if nearby_speed_item == item:
		nearby_speed_item = null


func try_get_item() -> void:
	if is_instance_valid(nearby_speed_item):
		if nearby_speed_item.has_method("collect"):
			nearby_speed_item.collect(self)
			return

	if is_instance_valid(nearby_bullet_item):
		if nearby_bullet_item.has_method("collect"):
			nearby_bullet_item.collect(self)
			return

	nearby_speed_item = null
	nearby_bullet_item = null

	print("Nenhum item próximo.")


func equip_speed_item(
	item_scene: PackedScene,
	speed_value: float,
	item_icon: Texture2D
) -> bool:
	if has_speed_item:
		print("Você já possui o SpeedUp.")
		return false

	if inventory_ui == null:
		push_error("ItemUI não encontrada.")
		return false

	var was_added := inventory_ui.add_item(
		&"speed",
		item_icon
	)

	if not was_added:
		return false

	equipped_speed_item_scene = item_scene
	equipped_speed_value = speed_value
	has_speed_item = true

	current_speed = equipped_speed_value
	nearby_speed_item = null

	print("SpeedUp equipado.")
	return true


func drop_speed_item() -> void:
	if not has_speed_item:
		return

	if equipped_speed_item_scene == null:
		return

	var dropped_item := equipped_speed_item_scene.instantiate()
	get_tree().current_scene.add_child(dropped_item)

	dropped_item.global_position = (
		global_position + Vector3(0.0, 0.0, 1.5)
	)

	has_speed_item = false
	current_speed = Game.speed

	equipped_speed_item_scene = null
	equipped_speed_value = 0.0
	nearby_speed_item = null

	inventory_ui.remove_item(&"speed")

	print("SpeedUp largado.")


func _on_selected_item_changed(item_id: StringName) -> void:
	print("Item ativo: ", item_id)
	

func set_nearby_bullet_item(item: Area3D) -> void:
	nearby_bullet_item = item
	print("ItemBullet próximo. Pressione get_item para pegar.")


func remove_nearby_bullet_item(item: Area3D) -> void:
	if nearby_bullet_item == item:
		nearby_bullet_item = null


func equip_bullet_item(
	item_scene: PackedScene,
	projectile_scene: PackedScene,
	item_icon: Texture2D
) -> bool:
	if has_bullet_item:
		print("Você já possui o ItemBullet.")
		return false

	if inventory_ui == null:
		push_error("ItemUI não encontrada.")
		return false

	var was_added := inventory_ui.add_item(
		&"bullet",
		item_icon
	)

	if not was_added:
		return false

	equipped_bullet_item_scene = item_scene
	equipped_bullet_scene = projectile_scene
	has_bullet_item = true
	nearby_bullet_item = null

	print("ItemBullet equipado.")
	return true


func drop_selected_item() -> void:
	if inventory_ui == null:
		return

	var selected_item := inventory_ui.get_selected_item_id()

	match selected_item:
		&"speed":
			drop_speed_item()

		&"bullet":
			drop_bullet_item()

		_:
			print("Nenhum item selecionado.")


func drop_bullet_item() -> void:
	if not has_bullet_item:
		return

	if equipped_bullet_item_scene == null:
		return

	var dropped_item := equipped_bullet_item_scene.instantiate()
	get_tree().current_scene.add_child(dropped_item)

	dropped_item.global_position = (
		global_position + Vector3(0.0, 0.0, 1.5)
	)

	has_bullet_item = false
	equipped_bullet_item_scene = null
	equipped_bullet_scene = null
	nearby_bullet_item = null

	inventory_ui.remove_item(&"bullet")

	print("ItemBullet largado.")
