extends Area3D

@export var item_icon: Texture2D

var consumed: bool = false


func _on_body_entered(body: Node3D) -> void:
	if consumed:
		return

	# #region agent log
	var _dbg_path := "c:/Users/breno/Desktop/GMTK2026/gmtk-2026/debug-319202.log"
	var _dbg_payload := {
		"sessionId": "319202",
		"runId": "pre-fix",
		"hypothesisId": "D",
		"location": "item_sword.gd:_on_body_entered",
		"message": "sword body entered",
		"data": {
			"body": body.name,
			"body_class": body.get_class(),
			"has_set_nearby": body.has_method("set_nearby_sword_item"),
			"in_player_group": body.is_in_group("player")
		},
		"timestamp": Time.get_unix_time_from_system() * 1000.0
	}
	var _dbg_file := FileAccess.open(_dbg_path, FileAccess.READ_WRITE)
	if _dbg_file == null:
		_dbg_file = FileAccess.open(_dbg_path, FileAccess.WRITE)
	if _dbg_file != null:
		_dbg_file.seek_end()
		_dbg_file.store_line(JSON.stringify(_dbg_payload))
		_dbg_file.close()
	# #endregion

	if body.has_method("set_nearby_sword_item"):
		body.set_nearby_sword_item(self)


func _on_body_exited(body: Node3D) -> void:
	if body.has_method("remove_nearby_sword_item"):
		body.remove_nearby_sword_item(self)


func collect(player: Node3D) -> void:
	if consumed:
		return

	if item_icon == null:
		push_error("Item Icon não foi configurado no ItemSword.")
		return

	var own_scene := load(scene_file_path) as PackedScene

	if own_scene == null:
		push_error(
			"Não foi possível carregar a cena do ItemSword: "
			+ scene_file_path
		)
		return

	if not player.has_method("equip_sword_item"):
		return

	var was_equipped: bool = player.equip_sword_item(
		own_scene,
		item_icon
	)

	if not was_equipped:
		return

	consumed = true
	set_deferred("monitoring", false)
	queue_free()
