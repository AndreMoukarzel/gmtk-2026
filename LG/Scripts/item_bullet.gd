# Item Bullet
extends Area3D

@export var bullet_scene: PackedScene
@export var item_icon: Texture2D

var consumed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if consumed:
		return

	if not body.is_in_group("player"):
		return

	if body.has_method("set_nearby_bullet_item"):
		body.set_nearby_bullet_item(self)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("remove_nearby_bullet_item"):
		body.remove_nearby_bullet_item(self)


func collect(player: Node3D) -> void:
	if consumed:
		return

	if bullet_scene == null:
		push_error("Bullet Scene não foi configurada no ItemBullet.")
		return

	if item_icon == null:
		push_error("Item Icon não foi configurado no ItemBullet.")
		return

	var own_scene := load(scene_file_path) as PackedScene

	if own_scene == null:
		push_error(
			"Não foi possível carregar a cena do ItemBullet: "
			+ scene_file_path
		)
		return

	if not player.has_method("equip_bullet_item"):
		return

	var was_equipped: bool = player.equip_bullet_item(
		own_scene,
		bullet_scene,
		item_icon
	)

	if not was_equipped:
		return

	consumed = true
	set_deferred("monitoring", false)
	queue_free()
