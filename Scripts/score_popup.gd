extends Label3D

func setup(amount: int, fade_seconds: float, score_font_size: int) -> void:
	text = "+%d" % amount
	self.font_size = score_font_size
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	modulate = Color(1.0, 0.92, 0.35, 1.0)
	outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	outline_size = 8

	var start_y := global_position.y
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self,
		"global_position:y",
		start_y + 1.2,
		fade_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(
		self,
		"outline_modulate:a",
		0.0,
		fade_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.chain().tween_callback(queue_free)
