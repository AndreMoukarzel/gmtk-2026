extends CanvasLayer

signal shown

var _is_active: bool = false

@onready var root: Control = $Root
@onready var play_again_button: Button = %PlayAgainButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	add_to_group("game_over_ui")
	root.visible = false
	play_again_button.pressed.connect(_on_play_again_pressed)


func is_active() -> bool:
	return _is_active


func trigger() -> void:
	if _is_active:
		return

	_is_active = true
	get_tree().paused = true
	root.visible = true
	play_again_button.grab_focus()
	shown.emit()


func _on_play_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
