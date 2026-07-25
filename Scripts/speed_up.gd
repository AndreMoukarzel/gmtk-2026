# Item Speedup
extends Area3D

@export var boosted_speed: float = 18.0
@export var item_icon: Texture2D

var consumed: bool = false


func _ready() -> void:
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if consumed:
		return

	if not body.is_in_group("player"):
		return

	if body.has_method("set_nearby_speed_item"):
		body.set_nearby_speed_item(self)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("remove_nearby_speed_item"):
		body.remove_nearby_speed_item(self)


func collect(player: Node3D) -> void:
	if consumed:
		return

	var own_scene := load(scene_file_path) as PackedScene

	if own_scene == null:
		push_error("Não foi possível carregar a cena do SpeedUp.")
		return

	var was_equipped: bool = player.equip_speed_item(
		own_scene,
		boosted_speed,
		item_icon
	)

	if not was_equipped:
		return

	consumed = true
	set_deferred("monitoring", false)
	queue_free()
