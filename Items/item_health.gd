extends Area3D

@export var regeneration_per_second: float = 5.0
@export var item_icon: Texture2D

var consumed: bool = false


func _on_body_entered(body: Node3D) -> void:
	if consumed:
		return

	if body.has_method("set_nearby_regeneration_item"):
		body.set_nearby_regeneration_item(self)


func _on_body_exited(body: Node3D) -> void:
	if body.has_method("remove_nearby_regeneration_item"):
		body.remove_nearby_regeneration_item(self)


func collect(player: Node3D) -> void:
	if consumed:
		return

	if item_icon == null:
		push_error("O ícone do item de regeneração não foi configurado.")
		return

	var item_scene := scene_file_path

	if item_scene.is_empty():
		push_error("A cena do item de regeneração ainda não foi salva.")
		return

	var packed_item_scene := load(item_scene) as PackedScene

	if packed_item_scene == null:
		push_error("Não foi possível carregar a cena do item.")
		return

	if not player.has_method("equip_regeneration_item"):
		push_error("O Player não possui equip_regeneration_item().")
		return

	var was_equipped: bool = player.equip_regeneration_item(
		packed_item_scene,
		regeneration_per_second,
		item_icon
	)

	if not was_equipped:
		return

	consumed = true
	queue_free()
