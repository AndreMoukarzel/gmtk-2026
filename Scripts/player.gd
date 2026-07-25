# Player
extends CharacterBody3D


# Movement
const ACCELERATION: float = 250.0
const DECELERATION: float = 350.0
const JUMP_VELOCITY: float = 6.0
const GRAVITY: float = 18.0

@export var equipped_fire_boots_item_scene: PackedScene = null

# Health
@export var max_health: float = 100.0

var health: float
var damage_immunities: Array[DamageTypes.Type] = []

# References
@export var shoot_origin: Marker3D

var inventory_ui: ItemUI

# Boost Speed
var base_speed: float = 10.0
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

# Fire Boots
var nearby_fire_boots_item: Area3D = null
var has_fire_boots_item: bool = false


# Regeneration Item
var nearby_regeneration_item: Area3D = null

var equipped_regeneration_item_scene: PackedScene = null
var equipped_regeneration_value: float = 0.0
var has_regeneration_item: bool = false

var regeneration_timer: float = 0.0


# Light Item
var nearby_light_item: Area3D = null

var equipped_light_item_scene: PackedScene = null
var equipped_light_range: float = 0
var equipped_light_energy: float = 0
var has_light_item: bool = false


@onready var health_fill: MeshInstance3D = $HealthBar/Fill
@onready var item_light: OmniLight3D = $ItemLight


func _ready() -> void:
	health = max_health
	update_health_bar()
	current_speed = base_speed
	item_light.visible = false

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

	process_health_regeneration(delta)

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
	bullet.look_at(bullet.global_position + bullet.direction, Vector3.UP)

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

	if is_instance_valid(nearby_fire_boots_item):
		if nearby_fire_boots_item.has_method("collect"):
			nearby_fire_boots_item.collect(self)
			return

	if is_instance_valid(nearby_regeneration_item):
		if nearby_regeneration_item.has_method("collect"):
			nearby_regeneration_item.collect(self)
			return

	if is_instance_valid(nearby_light_item):
		if nearby_light_item.has_method("collect"):
			nearby_light_item.collect(self)
			return

	nearby_speed_item = null
	nearby_bullet_item = null
	nearby_fire_boots_item = null

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
	current_speed = base_speed

	equipped_speed_item_scene = null
	equipped_speed_value = 0.0
	nearby_speed_item = null

	inventory_ui.remove_item(&"speed")

	print("SpeedUp largado.")


func equip_fire_boots(
	item_icon: Texture2D
) -> bool:
	if has_fire_boots_item:
		print("Você já possui as Fire Boots.")
		return false

	if inventory_ui == null:
		push_error("ItemUI não encontrada.")
		return false

	var was_added := inventory_ui.add_item(
		&"fire_boots",
		item_icon
	)

	if not was_added:
		return false

	has_fire_boots_item = true
	nearby_fire_boots_item = null

	add_damage_immunity(DamageTypes.Type.FIRE)

	print("Fire Boots equipadas. Imunidade a fogo ativada.")
	return true


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

		&"fire_boots":
			drop_fire_boots()

		&"regeneration":
			drop_regeneration_item()

		&"light":
			drop_light_item()

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


func drop_fire_boots() -> void:
	if not has_fire_boots_item:
		return

	var dropped_item := equipped_fire_boots_item_scene.instantiate()
	get_tree().current_scene.add_child(dropped_item)

	dropped_item.global_position = (
		global_position + Vector3(0.0, 0.0, 1.5)
	)

	has_fire_boots_item = false
	nearby_fire_boots_item = null

	remove_damage_immunity(DamageTypes.Type.FIRE)

	inventory_ui.remove_item(&"fire_boots")

	print("Fire Boots largadas. Imunidade a fogo removida.")


func set_nearby_fire_boots_item(item: Area3D) -> void:
	nearby_fire_boots_item = item
	print("Fire Boots próximas. Pressione get_item para pegar.")


func remove_nearby_fire_boots_item(item: Area3D) -> void:
	if nearby_fire_boots_item == item:
		nearby_fire_boots_item = null


func add_damage_immunity(damage_type: DamageTypes.Type) -> void:
	if damage_type not in damage_immunities:
		damage_immunities.append(damage_type)


func remove_damage_immunity(damage_type: DamageTypes.Type) -> void:
	damage_immunities.erase(damage_type)


func is_immune_to(damage_type: DamageTypes.Type) -> bool:
	return damage_type in damage_immunities


func take_damage(
	damage: float
) -> void:
	if damage <= 0.0:
		return

	health = maxf(health - damage, 0.0)
	update_health_bar()

	print("Player recebeu ", damage, " de dano.")
	print("Vida atual: ", health)

	if health <= 0.0:
		die()


func die() -> void:
	print("Player morreu.")


func update_health_bar() -> void:
	var health_percent := health / max_health

	health_fill.scale.x = health_percent
	health_fill.position.x = -(1.0 - health_percent) * 0.6


func process_health_regeneration(delta: float) -> void:
	if not has_regeneration_item:
		regeneration_timer = 0.0
		return

	if health >= max_health:
		regeneration_timer = 0.0
		return

	regeneration_timer += delta

	if regeneration_timer >= 1.0:
		regeneration_timer -= 1.0
		heal(equipped_regeneration_value)


func heal(amount: float) -> void:
	if amount <= 0.0:
		return

	health = minf(health + amount, max_health)
	update_health_bar()

	print("Player recuperou ", amount, " de vida.")
	print("Vida atual: ", health)


func set_nearby_regeneration_item(item: Area3D) -> void:
	nearby_regeneration_item = item
	print("Item de regeneração próximo. Pressione get_item para pegar.")


func remove_nearby_regeneration_item(item: Area3D) -> void:
	if nearby_regeneration_item == item:
		nearby_regeneration_item = null


func equip_regeneration_item(
	item_scene: PackedScene,
	regeneration_value: float,
	item_icon: Texture2D
) -> bool:
	if has_regeneration_item:
		print("Você já possui o item de regeneração.")
		return false

	if inventory_ui == null:
		push_error("ItemUI não encontrada.")
		return false

	var was_added := inventory_ui.add_item(
		&"regeneration",
		item_icon
	)

	if not was_added:
		return false

	equipped_regeneration_item_scene = item_scene
	equipped_regeneration_value = regeneration_value
	has_regeneration_item = true
	nearby_regeneration_item = null
	regeneration_timer = 0.0

	print(
		"Item de regeneração equipado. Recuperação por segundo: ",
		regeneration_value
	)

	return true


func drop_regeneration_item() -> void:
	if not has_regeneration_item:
		return

	if equipped_regeneration_item_scene == null:
		return

	var dropped_item := equipped_regeneration_item_scene.instantiate()
	get_tree().current_scene.add_child(dropped_item)

	dropped_item.global_position = (
		global_position + Vector3(0.0, 0.0, 1.5)
	)

	has_regeneration_item = false
	equipped_regeneration_item_scene = null
	equipped_regeneration_value = 0.0
	nearby_regeneration_item = null
	regeneration_timer = 0.0

	inventory_ui.remove_item(&"regeneration")

	print("Item de regeneração largado.")


func set_nearby_light_item(item: Area3D) -> void:
	nearby_light_item = item

	print("Item de luz próximo. Pressione get_item para pegar.")


func remove_nearby_light_item(item: Area3D) -> void:
	if nearby_light_item == item:
		nearby_light_item = null


func equip_light_item(
	item_scene: PackedScene,
	light_range: float,
	light_energy: float,
	item_icon: Texture2D
) -> bool:
	if has_light_item:
		print("Você já possui o item de luz.")
		return false

	if inventory_ui == null:
		push_error("ItemUI não encontrada.")
		return false

	if item_light == null:
		push_error("ItemLight não foi encontrada no Player.")
		return false

	var was_added := inventory_ui.add_item(
		&"light",
		item_icon
	)

	if not was_added:
		return false

	equipped_light_item_scene = item_scene
	equipped_light_range = light_range
	equipped_light_energy = light_energy
	has_light_item = true
	nearby_light_item = null

	item_light.omni_range = equipped_light_range
	item_light.light_energy = equipped_light_energy
	item_light.visible = true

	print("Item de luz equipado.")
	return true


func drop_light_item() -> void:
	if not has_light_item:
		return

	if equipped_light_item_scene == null:
		return

	var dropped_item := equipped_light_item_scene.instantiate()
	get_tree().current_scene.add_child(dropped_item)

	dropped_item.global_position = (
		global_position + Vector3(0.0, 0.0, 1.5)
	)

	has_light_item = false
	equipped_light_item_scene = null
	nearby_light_item = null

	item_light.visible = false

	inventory_ui.remove_item(&"light")

	print("Item de luz largado. Luz desativada.")
