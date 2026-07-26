extends Control

signal closed

@onready var back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	closed.emit()
	close()


func close() -> void:
	visible = false
