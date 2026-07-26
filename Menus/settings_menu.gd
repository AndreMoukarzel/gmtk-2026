extends Control

const AudioSettings = preload("res://Menus/audio_settings.gd")

signal closed

@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_spin: SpinBox = %VolumeSpin
@onready var back_button: Button = %BackButton

var _updating_ui: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_spin.min_value = 0.0
	volume_spin.max_value = 100.0
	volume_spin.step = 1.0
	volume_spin.rounded = true
	volume_spin.allow_greater = false
	volume_spin.allow_lesser = false

	volume_slider.value_changed.connect(_on_slider_changed)
	volume_spin.value_changed.connect(_on_spin_changed)
	back_button.pressed.connect(_on_back_pressed)

	var percent: float = AudioSettings.load_volume_percent()
	_set_ui_volume(percent)
	AudioSettings.apply_volume_percent(percent)


func _set_ui_volume(percent: float) -> void:
	_updating_ui = true
	volume_slider.value = percent
	volume_spin.value = percent
	_updating_ui = false


func _apply_and_save(percent: float) -> void:
	percent = clampf(percent, 0.0, 100.0)
	AudioSettings.apply_volume_percent(percent)
	AudioSettings.save_volume_percent(percent)


func _on_slider_changed(value: float) -> void:
	if _updating_ui:
		return
	_updating_ui = true
	volume_spin.value = value
	_updating_ui = false
	_apply_and_save(value)


func _on_spin_changed(value: float) -> void:
	if _updating_ui:
		return
	_updating_ui = true
	volume_slider.value = value
	_updating_ui = false
	_apply_and_save(value)


func _on_back_pressed() -> void:
	closed.emit()


func open() -> void:
	visible = true
	var percent: float = AudioSettings.load_volume_percent()
	_set_ui_volume(percent)
	AudioSettings.apply_volume_percent(percent)
	back_button.grab_focus()


func close() -> void:
	visible = false
