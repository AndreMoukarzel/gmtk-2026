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
	get_tree().paused = false
