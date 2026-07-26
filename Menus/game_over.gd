extends CanvasLayer

const GAME_SCENE_PATH := "res://Scenes/field_test.tscn"

signal shown

var _is_active: bool = false

@onready var root: Control = $Root
@onready var play_again_button: Button = %PlayAgainButton
@onready var score_label: Label = %ScoreLabel


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

	var manager := get_tree().get_first_node_in_group("score_manager")
	if manager != null:
		if manager.has_method("end_run"):
			manager.end_run()
		score_label.text = "Score: %d" % int(manager.score)
	else:
		score_label.text = "Score: 0"

	get_tree().paused = true
	root.visible = true
	play_again_button.grab_focus()
	shown.emit()


func _on_play_again_pressed() -> void:
	# Undo calamity side-effects on shared resources before leaving the scene.
	for node in get_tree().get_nodes_in_group("calamity_blackout"):
		if node.has_method("stop_blackout"):
			node.stop_blackout()

	get_tree().paused = false
	# Explicit full load of field_test (more reliable than reload while paused).
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE_PATH)
