# Player
extends CharacterBody3D


# Movement
const ACCELERATION: float = 250.0
const DECELERATION: float = 350.0
const JUMP_VELOCITY: float = 6.0
const GRAVITY: float = 18.0

const RUNNING_ANIMATION: StringName = &"running"
const IDLE_ANIMATION: StringName = &"mixamo_com"

enum AnimState {
	IDLE,
	RUNNING,
}

# Health
@export var max_health: float = 100.0

var health: float
var damage_immunities: Array[DamageTypes.Type] = []

# Knockback
@export var knockback_strength: float = 12.0
@export var knockback_deceleration: float = 12.0

var knockback_velocity: Vector3 = Vector3.ZERO

@export var hurt_vignette_peak: float = 0.85
@export var hurt_vignette_fade_seconds: float = 0.35

var _hurt_vignette_tween: Tween
var _hurt_vignette_material: ShaderMaterial

# References
@export var shoot_origin: Marker3D
@export var arrow_cooldown: float = 0.3
@export var sword_cooldown: float = 0.3
@export var sword_slash_scene: PackedScene
@export var animation_duration: float = 0.2
@export var sword_damage: float = 25.0
@export var sword_hitbox_size: Vector3 = Vector3(2, 2, 2)
@export var sword_hitbox_forward_offset: float = 1.5
@export var hitbox_boundaries_ingame: bool = true

var inventory_ui: ItemUI
var _arrow_cooldown_remaining: float = 0.0
var _sword_cooldown_remaining: float = 0.0

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

# Sword
var nearby_sword_item: Area3D = null
var equipped_sword_item_scene: PackedScene = null
var has_sword_item: bool = false

# Fire Boots
var equipped_fire_boots_item_scene: PackedScene = null
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

var anim_state: AnimState = AnimState.IDLE
var _highlighted_pickup: Area3D = null

@onready var item_light: OmniLight3D = $ItemLight
@onready var character_model: Node3D = $Character
@onready var hurt_vignette_rect: ColorRect = $HurtVignette/ColorRect
@onready var animation_player: AnimationPlayer = $Character.find_child(
	"AnimationPlayer",
	true,
	false
) as AnimationPlayer


func _ready() -> void:
	health = max_health
	$HealthBar/HealthBar.max_value = max_health
	update_health_bar()
	_setup_hurt_vignette()
	current_speed = base_speed
	item_light.visible = false

	if animation_player == null:
		push_error("AnimationPlayer não encontrada no modelo do player.")
	else:
		_set_anim_state(AnimState.IDLE)

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

	# Ataque do item selecionado (hold to fire)
	if _arrow_cooldown_remaining > 0.0:
		_arrow_cooldown_remaining -= delta

	if _sword_cooldown_remaining > 0.0:
		_sword_cooldown_remaining -= delta

	if Input.is_action_pressed("shoot"):
		_try_use_selected_weapon()

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

		_face_direction(direction)
		_set_anim_state(AnimState.RUNNING)
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

		_set_anim_state(AnimState.IDLE)

	process_health_regeneration(delta)

	# Reduz gradualmente o knockback.
	knockback_velocity.x = move_toward(
		knockback_velocity.x,
		0.0,
		knockback_deceleration * delta
	)
	knockback_velocity.z = move_toward(
		knockback_velocity.z,
		0.0,
		knockback_deceleration * delta
	)

	# Aplica o knockback junto com o movimento normal.
	velocity.x += knockback_velocity.x
	velocity.z += knockback_velocity.z

	move_and_slide()

	# Remove o knockback da velocity para não acumular.
	velocity.x -= knockback_velocity.x
	velocity.z -= knockback_velocity.z


func _face_direction(direction: Vector3) -> void:
	if character_model == null:
		return

	if direction.length_squared() < 0.0001:
		return

	character_model.look_at(
		character_model.global_position + direction,
		Vector3.UP
	)


func _set_anim_state(new_state: AnimState) -> void:
	if new_state == anim_state:
		return

	anim_state = new_state

	if animation_player == null:
		return

	match anim_state:
		AnimState.IDLE:
			animation_player.play(IDLE_ANIMATION)

		AnimState.RUNNING:
			animation_player.play(RUNNING_ANIMATION)


func _try_use_selected_weapon() -> void:
	if inventory_ui == null:
		return

	if inventory_ui.has_item(&"bullet"):
		if not can_shoot():
			if Input.is_action_just_pressed("shoot"):
				print("Você não possui o ItemBullet equipado.")
			return

		if _arrow_cooldown_remaining <= 0.0:
			shoot_at_mouse()
			_arrow_cooldown_remaining = arrow_cooldown

	if inventory_ui.has_item(&"sword"):
		if not can_slash():
			# if Input.is_action_just_pressed("shoot"):
			# 	print("Você não possui a Sword equipada.")
			return

		if _sword_cooldown_remaining <= 0.0:
			slash_at_mouse()
			_sword_cooldown_remaining = sword_cooldown


func can_shoot() -> bool:
	return has_bullet_item and equipped_bullet_scene != null


func can_slash() -> bool:
	return has_sword_item and sword_slash_scene != null


func get_aim_direction_from_mouse() -> Vector3:
	var current_camera := get_viewport().get_camera_3d()

	if current_camera == null:
		push_error("ERRO: nenhuma Camera3D ativa encontrada.")
		return Vector3.ZERO

	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := current_camera.project_ray_origin(mouse_position)
	var ray_direction := current_camera.project_ray_normal(mouse_position)

	var aim_origin := global_position

	if shoot_origin != null:
		aim_origin = shoot_origin.global_position

	var aim_plane := Plane(Vector3.UP, aim_origin.y)
	var mouse_world_position = aim_plane.intersects_ray(
		ray_origin,
		ray_direction
	)

	if mouse_world_position == null:
		push_error("ERRO: o raio do mouse não encontrou o plano horizontal.")
		return Vector3.ZERO

	var aim_direction: Vector3 = mouse_world_position - aim_origin
	aim_direction.y = 0.0
	aim_direction = aim_direction.normalized()

	if aim_direction == Vector3.ZERO:
		push_error("ERRO: direção de mira ficou zerada.")
		return Vector3.ZERO

	return aim_direction


func shoot_at_mouse() -> void:
	if equipped_bullet_scene == null:
		push_error("ERRO: Bullet Scene não foi configurada no Inspector.")
		return

	var bullet_direction := get_aim_direction_from_mouse()

	if bullet_direction == Vector3.ZERO:
		return

	var bullet_origin := global_position

	if shoot_origin != null:
		bullet_origin = shoot_origin.global_position

	var bullet = equipped_bullet_scene.instantiate()

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = bullet_origin
	bullet.direction = bullet_direction
	bullet.look_at(bullet.global_position + bullet.direction, Vector3.UP)


func slash_at_mouse() -> void:
	if sword_slash_scene == null:
		push_error("ERRO: Sword Slash Scene não foi configurada no Inspector.")
		return

	var slash_direction := get_aim_direction_from_mouse()

	if slash_direction == Vector3.ZERO:
		return

	var slash := sword_slash_scene.instantiate() as Node3D

	if slash == null:
		push_error("ERRO: a cena do slash precisa herdar de Node3D.")
		return

	add_child(slash)

	if slash.has_method("configure"):
		slash.configure(
			animation_duration,
			sword_damage,
			sword_hitbox_size,
			sword_hitbox_forward_offset
		)

	if slash.has_method("play"):
		slash.play(slash_direction)
	else:
		push_error("ERRO: SwordSlash não possui play().")
		slash.queue_free()
		return

	if slash.has_node("Hitbox"):
		add_hitbox_boundaries_ingame(slash.get_node("Hitbox") as Area3D)


func add_hitbox_boundaries_ingame(hitbox: Area3D) -> void:
	if not hitbox_boundaries_ingame:
		return

	if hitbox == null:
		return

	var collision_shape := hitbox.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		return

	var box_shape := collision_shape.shape as BoxShape3D
	if box_shape == null:
		return

	if hitbox.get_node_or_null("HitboxBoundaryMesh") != null:
		return

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "HitboxBoundaryMesh"

	var box_mesh := BoxMesh.new()
	box_mesh.size = box_shape.size
	mesh_instance.mesh = box_mesh

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.2, 0.2, 0.35)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material

	hitbox.add_child(mesh_instance)
	mesh_instance.visible = false


func set_nearby_speed_item(item: Area3D) -> void:
	nearby_speed_item = item
	print("SpeedUp próximo. Pressione get_item para pegar.")
	_refresh_pickup_highlight()


func remove_nearby_speed_item(item: Area3D) -> void:
	if nearby_speed_item == item:
		nearby_speed_item = null
		_refresh_pickup_highlight()


func try_get_item() -> void:
	if is_instance_valid(nearby_speed_item):
		if nearby_speed_item.has_method("collect"):
			nearby_speed_item.collect(self)
			nearby_speed_item = null
			_refresh_pickup_highlight()
			return

	if is_instance_valid(nearby_bullet_item):
		if nearby_bullet_item.has_method("collect"):
			nearby_bullet_item.collect(self)
			nearby_bullet_item = null
			_refresh_pickup_highlight()
			return

	if is_instance_valid(nearby_fire_boots_item):
		if nearby_fire_boots_item.has_method("collect"):
			nearby_fire_boots_item.collect(self)
			nearby_fire_boots_item = null
			_refresh_pickup_highlight()
			return

	if is_instance_valid(nearby_regeneration_item):
		if nearby_regeneration_item.has_method("collect"):
			nearby_regeneration_item.collect(self)
			nearby_regeneration_item = null
			_refresh_pickup_highlight()
			return

	if is_instance_valid(nearby_light_item):
		if nearby_light_item.has_method("collect"):
			nearby_light_item.collect(self)
			nearby_light_item = null
			_refresh_pickup_highlight()
			return

	if is_instance_valid(nearby_sword_item):
		if nearby_sword_item.has_method("collect"):
			nearby_sword_item.collect(self)
			nearby_sword_item = null
			_refresh_pickup_highlight()
			return

	nearby_speed_item = null
	nearby_bullet_item = null
	nearby_fire_boots_item = null
	nearby_sword_item = null
	_refresh_pickup_highlight()

	print("Nenhum item próximo.")


func _get_active_nearby_pickup() -> Area3D:
	# Same priority order as try_get_item().
	if is_instance_valid(nearby_speed_item):
		return nearby_speed_item

	if is_instance_valid(nearby_bullet_item):
		return nearby_bullet_item

	if is_instance_valid(nearby_fire_boots_item):
		return nearby_fire_boots_item

	if is_instance_valid(nearby_regeneration_item):
		return nearby_regeneration_item

	if is_instance_valid(nearby_light_item):
		return nearby_light_item

	if is_instance_valid(nearby_sword_item):
		return nearby_sword_item

	return null


func _refresh_pickup_highlight() -> void:
	var target := _get_active_nearby_pickup()

	# #region agent log
	_agent_dbg_log("A", "player.gd:_refresh_pickup_highlight", "refresh called", {
		"target": str(target),
		"target_name": target.name if target else "",
		"prev": str(_highlighted_pickup),
		"nearby_sword": is_instance_valid(nearby_sword_item),
		"nearby_bullet": is_instance_valid(nearby_bullet_item),
		"nearby_speed": is_instance_valid(nearby_speed_item),
		"same_target": _highlighted_pickup == target
	})
	# #endregion

	if _highlighted_pickup == target:
		return

	if is_instance_valid(_highlighted_pickup):
		PickupHighlight.set_highlighted(_highlighted_pickup, false)

	_highlighted_pickup = target

	if is_instance_valid(_highlighted_pickup):
		PickupHighlight.set_highlighted(_highlighted_pickup, true)


func _agent_dbg_log(hypothesis_id: String, location: String, message: String, data: Dictionary = {}) -> void:
	# #region agent log
	var path := "c:/Users/breno/Desktop/GMTK2026/gmtk-2026/debug-319202.log"
	var payload := {
		"sessionId": "319202",
		"runId": "post-fix",
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_unix_time_from_system() * 1000.0
	}
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(payload))
	file.close()
	# #endregion


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
	item_scene: PackedScene,
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

	equipped_fire_boots_item_scene = item_scene
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
	_refresh_pickup_highlight()


func remove_nearby_bullet_item(item: Area3D) -> void:
	if nearby_bullet_item == item:
		nearby_bullet_item = null
		_refresh_pickup_highlight()


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

		&"sword":
			drop_sword_item()

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


func set_nearby_sword_item(item: Area3D) -> void:
	nearby_sword_item = item
	print("Sword próxima. Pressione get_item para pegar.")
	_refresh_pickup_highlight()


func remove_nearby_sword_item(item: Area3D) -> void:
	if nearby_sword_item == item:
		nearby_sword_item = null
		_refresh_pickup_highlight()


func equip_sword_item(
	item_scene: PackedScene,
	item_icon: Texture2D
) -> bool:
	if has_sword_item:
		print("Você já possui a Sword.")
		return false

	if inventory_ui == null:
		push_error("ItemUI não encontrada.")
		return false

	var was_added := inventory_ui.add_item(
		&"sword",
		item_icon
	)

	if not was_added:
		return false

	equipped_sword_item_scene = item_scene
	has_sword_item = true
	nearby_sword_item = null

	print("Sword equipada.")
	return true


func drop_sword_item() -> void:
	if not has_sword_item:
		return

	if equipped_sword_item_scene == null:
		return

	var dropped_item := equipped_sword_item_scene.instantiate()
	get_tree().current_scene.add_child(dropped_item)

	dropped_item.global_position = (
		global_position + Vector3(0.0, 0.0, 1.5)
	)

	has_sword_item = false
	equipped_sword_item_scene = null
	nearby_sword_item = null

	inventory_ui.remove_item(&"sword")

	print("Sword largada.")


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
	_refresh_pickup_highlight()


func remove_nearby_fire_boots_item(item: Area3D) -> void:
	if nearby_fire_boots_item == item:
		nearby_fire_boots_item = null
		_refresh_pickup_highlight()


func add_damage_immunity(damage_type: DamageTypes.Type) -> void:
	if damage_type not in damage_immunities:
		damage_immunities.append(damage_type)


func remove_damage_immunity(damage_type: DamageTypes.Type) -> void:
	damage_immunities.erase(damage_type)


func is_immune_to(damage_type: DamageTypes.Type) -> bool:
	return damage_type in damage_immunities


func take_damage(
	damage: float,
	attack_origin: Vector3 = Vector3(0, 0, 0),
	damage_type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
) -> void:
	if damage <= 0.0:
		return
	
	if is_immune_to(damage_type):
		print("Dano bloqueado: ", damage_type)
		return

	health = maxf(health - damage, 0.0)
	update_health_bar()
	apply_knockback(attack_origin)
	flash_hurt_vignette()

	print("Player recebeu ", damage, " de dano.")
	print("Vida atual: ", health)

	if health <= 0.0:
		die()


func _setup_hurt_vignette() -> void:
	if hurt_vignette_rect == null:
		return

	var material := hurt_vignette_rect.material as ShaderMaterial
	if material == null:
		return

	_hurt_vignette_material = material.duplicate() as ShaderMaterial
	hurt_vignette_rect.material = _hurt_vignette_material
	_hurt_vignette_material.set_shader_parameter("intensity", 0.0)


func flash_hurt_vignette() -> void:
	if _hurt_vignette_material == null:
		return

	if _hurt_vignette_tween != null and _hurt_vignette_tween.is_valid():
		_hurt_vignette_tween.kill()

	_hurt_vignette_material.set_shader_parameter("intensity", hurt_vignette_peak)
	_hurt_vignette_tween = create_tween()
	_hurt_vignette_tween.tween_method(
		_set_hurt_vignette_intensity,
		hurt_vignette_peak,
		0.0,
		hurt_vignette_fade_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_hurt_vignette_intensity(value: float) -> void:
	if _hurt_vignette_material != null:
		_hurt_vignette_material.set_shader_parameter("intensity", value)


func apply_knockback(attack_origin: Vector3) -> void:
	# Skip default / missing origins (e.g. fire DoT) so we don't fling from world origin.
	if attack_origin.length_squared() < 0.0001:
		return

	var knockback_direction := global_position - attack_origin
	knockback_direction.y = 0.0

	if knockback_direction.length_squared() < 0.0001:
		return

	knockback_direction = knockback_direction.normalized()
	knockback_velocity.x += knockback_direction.x * knockback_strength
	knockback_velocity.z += knockback_direction.z * knockback_strength


func die() -> void:
	print("Player morreu.")
	knockback_velocity = Vector3.ZERO
	if _hurt_vignette_tween != null and _hurt_vignette_tween.is_valid():
		_hurt_vignette_tween.kill()
	_set_hurt_vignette_intensity(0.0)


func update_health_bar() -> void:
	$HealthBar/HealthBar.value = health


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
	_refresh_pickup_highlight()


func remove_nearby_regeneration_item(item: Area3D) -> void:
	if nearby_regeneration_item == item:
		nearby_regeneration_item = null
		_refresh_pickup_highlight()


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
	_refresh_pickup_highlight()


func remove_nearby_light_item(item: Area3D) -> void:
	if nearby_light_item == item:
		nearby_light_item = null
		_refresh_pickup_highlight()


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
