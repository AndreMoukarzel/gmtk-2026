extends CanvasLayer

@export var base_hitbox: Node

@onready var health_bar: ProgressBar = %HealthBar
@onready var value_label: Label = %ValueLabel


func _ready() -> void:
	if base_hitbox == null:
		var scene_root := get_tree().current_scene
		if scene_root != null:
			base_hitbox = scene_root.get_node_or_null("Base Hitbox")

	if base_hitbox == null:
		push_error("CastleHealthUI: Base Hitbox not found.")
		return

	if base_hitbox.has_signal("health_changed"):
		base_hitbox.health_changed.connect(_on_health_changed)

	call_deferred("_refresh_from_base")


func _refresh_from_base() -> void:
	if base_hitbox == null:
		return
	if "health" in base_hitbox and "max_health" in base_hitbox:
		_on_health_changed(base_hitbox.health, base_hitbox.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	value_label.text = "%d / %d" % [ceili(current), ceili(maximum)]
