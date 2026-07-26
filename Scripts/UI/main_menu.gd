extends Control

const AudioSettings = preload("res://Scripts/UI/audio_settings.gd")
const GAME_SCENE_PATH := "res://Scenes/field_test.tscn"

@onready var main_buttons: VBoxContainer = %MainButtons
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var settings_menu: Control = %SettingsMenu


func _ready() -> void:
	AudioSettings.apply_volume_percent(AudioSettings.load_volume_percent())

	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	settings_menu.closed.connect(_on_settings_closed)

	settings_menu.visible = false
	main_buttons.visible = true
	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not settings_menu.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_settings_closed()
		get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_settings_pressed() -> void:
	main_buttons.visible = false
	settings_menu.open()


func _on_settings_closed() -> void:
	settings_menu.close()
	main_buttons.visible = true
	settings_button.grab_focus()


func _on_exit_pressed() -> void:
	get_tree().quit()
