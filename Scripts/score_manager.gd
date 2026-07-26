class_name ScoreManager
extends Node

signal score_changed(new_score: int)

## Current run score. Reset automatically when the scene reloads.
var score: int = 0

var _run_active: bool = true
var _survival_accum: float = 0.0


func _ready() -> void:
	add_to_group("score_manager")
	score_changed.emit(score)


## Add points from any source (survival, kills, pickups, etc.).
func add_score(amount: int) -> void:
	if amount == 0:
		return

	score = maxi(score + amount, 0)
	score_changed.emit(score)


func end_run() -> void:
	_run_active = false


func _process(delta: float) -> void:
	if not _run_active:
		return

	_survival_accum += delta
	while _survival_accum >= 1.0:
		_survival_accum -= 1.0
		add_score(1)
