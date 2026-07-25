extends Area3D

@export var light_range: float = 15.0
@export var light_energy: float = 2.0
@export var item_icon: Texture2D

var consumed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if consumed:
		return

	if body.has_method("set_nearby_light_item"):
		body.set_nearby_light_item(self)


func _on_body_exited(body: Node3D) -> void:
	if body.has_method("remove_nearby_light_item"):
		body.remove_nearby_light_item(self)


func collect(player: Node3D) -> void:
	if consumed:
		return

	if item_icon == null:
		push_error("O ícone do item de luz não foi configurado.")
		return

	if scene_file_path.is_empty():
		push_error("A cena do item de luz ainda não foi salva.")
		return

	var packed_item_scene := load(scene_file_path) as PackedScene

	if packed_item_scene == null:
		push_error("Não foi possível carregar a cena do item de luz.")
		return

	if not player.has_method("equip_light_item"):
		push_error("O Player não possui equip_light_item().")
		return

	var was_equipped: bool = player.equip_light_item(
		packed_item_scene,
		light_range,
		light_energy,
		item_icon
	)

	if not was_equipped:
		return

	consumed = true
	queue_free()
