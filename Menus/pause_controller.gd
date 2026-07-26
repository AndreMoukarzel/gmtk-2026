extends CanvasLayer

@onready var settings_menu: Control = $SettingsMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	settings_menu.visible = false
	settings_menu.closed.connect(_close_pause_settings)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if _is_game_over_active():
		get_viewport().set_input_as_handled()
		return

	if settings_menu.visible:
		_close_pause_settings()
	else:
		_open_pause_settings()

	get_viewport().set_input_as_handled()


func _open_pause_settings() -> void:
	get_tree().paused = true
	settings_menu.open()


func _close_pause_settings() -> void:
	settings_menu.close()
	if not _is_game_over_active():
		get_tree().paused = false


func _is_game_over_active() -> bool:
	var game_over := get_tree().get_first_node_in_group("game_over_ui")
	return game_over != null and game_over.has_method("is_active") and game_over.is_active()
