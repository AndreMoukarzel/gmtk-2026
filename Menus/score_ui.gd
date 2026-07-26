extends CanvasLayer

@onready var score_label: Label = %ScoreLabel


func _ready() -> void:
	var manager := _get_score_manager()
	if manager == null:
		push_error("ScoreUI: ScoreManager not found.")
		_set_score_text(0)
		return

	if manager.has_signal("score_changed"):
		manager.score_changed.connect(_on_score_changed)

	_set_score_text(manager.score)


func _on_score_changed(new_score: int) -> void:
	_set_score_text(new_score)


func _set_score_text(value: int) -> void:
	score_label.text = "Score: %d" % value


func _get_score_manager() -> Node:
	return get_tree().get_first_node_in_group("score_manager")
