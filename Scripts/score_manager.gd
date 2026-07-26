class_name ScoreManager
extends Node

const ScoreSettings = preload("res://Menus/score_settings.gd")

signal score_changed(new_score: int)

@export_category("Score Popup")
@export var score_popup_scene: PackedScene
## Seconds until the floating "+N" fully fades out.
@export var score_popup_fade_seconds: float = 0.85
## Label3D font size for the floating score popup.
@export var score_popup_font_size: int = 72
## Lift above the death point so the number isn't buried in the mesh.
@export var score_popup_height_offset: float = 1.25

## Current run score. Reset automatically when the scene reloads.
var score: int = 0

var _run_active: bool = true
var _survival_accum: float = 0.0


func _ready() -> void:
	add_to_group("score_manager")
	score_changed.emit(score)


## Add points from any source (survival, kills, pickups, etc.).
func add_score(amount: int) -> void:
	if not _run_active or amount == 0:
		return

	score = maxi(score + amount, 0)
	score_changed.emit(score)


## Combat kill helper: awards points and spawns a fading billboard at the world position.
func add_score_at(amount: int, world_position: Vector3) -> void:
	add_score(amount)
	if _run_active and amount != 0:
		spawn_score_popup(amount, world_position)


func spawn_score_popup(amount: int, world_position: Vector3) -> void:
	if score_popup_scene == null:
		return

	var popup := score_popup_scene.instantiate()
	if popup == null:
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = self

	parent.add_child(popup)
	popup.global_position = world_position + Vector3.UP * score_popup_height_offset

	if popup.has_method("setup"):
		popup.setup(amount, score_popup_fade_seconds, score_popup_font_size)


## Floor-halves the current score (e.g. player death penalty).
func halve_score() -> void:
	if not _run_active:
		return

	score = score / 2
	score_changed.emit(score)


func end_run() -> void:
	_run_active = false


## Stops scoring and persists a new highscore when beaten. Returns the highscore.
func finalize_run() -> int:
	end_run()
	return ScoreSettings.submit_score(score)


func _process(delta: float) -> void:
	if not _run_active:
		return

	_survival_accum += delta
	while _survival_accum >= 1.0:
		_survival_accum -= 1.0
		add_score(1)
