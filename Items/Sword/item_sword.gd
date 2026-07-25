extends Area3D

@export var item_icon: Texture2D

var consumed: bool = false


func _on_body_entered(body: Node3D) -> void:
	if consumed:
		return

	if body.has_method("set_nearby_sword_item"):
		body.set_nearby_sword_item(self)


func _on_body_exited(body: Node3D) -> void:
	if body.has_method("remove_nearby_sword_item"):
		body.remove_nearby_sword_item(self)


func collect(player: Node3D) -> void:
	if consumed:
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

	var was_equipped: bool = player.equip_sword_item(
		own_scene,
		item_icon
	)

	if not was_equipped:
		return

	consumed = true
	set_deferred("monitoring", false)
	queue_free()
