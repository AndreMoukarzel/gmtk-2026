class_name CalamityAnnouncement
extends PanelContainer

signal presentation_finished

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel


func setup(calamity: CalamityData) -> void:
	icon.texture = calamity.icon
	name_label.text = calamity.calamity_name
	description_label.text = calamity.description


func play_presentation() -> void:
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)

	var appear_tween := create_tween()
	appear_tween.set_parallel(true)

	appear_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		0.25
	)

	appear_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.25
	).set_trans(Tween.TRANS_BACK)

	await appear_tween.finished
	await get_tree().create_timer(1.5).timeout

	var disappear_tween := create_tween()
	disappear_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.25
	)

	await disappear_tween.finished

	presentation_finished.emit()
	queue_free()
