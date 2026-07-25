# Item Fire Boots
extends Area3D

const ITEM_SCENE: PackedScene = preload(
	"res://Scenes/item_fire_boots.tscn"
)

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

	if body.has_method("set_nearby_fire_boots_item"):
		body.set_nearby_fire_boots_item(self)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("remove_nearby_fire_boots_item"):
		body.remove_nearby_fire_boots_item(self)


func collect(player: Node3D) -> void:
	if consumed:
		return

	if not player.has_method("equip_fire_boots"):
		return

	var was_equipped: bool = player.equip_fire_boots(
		ITEM_SCENE,
		item_icon
	)

	if not was_equipped:
		return

	consumed = true
	queue_free()
