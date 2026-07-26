class_name ItemUI
extends CanvasLayer

signal selected_item_changed(item_id: StringName)


var selected_slot: int = -1

# Identifica qual item está em cada TextureRect.
var slot_item_ids: Array[StringName] = [
	&"",
	&""
]


func _ready() -> void:
	clear_all_items()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("hotbar_1"):
		select_slot(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hotbar_2"):
		select_slot(1)
		get_viewport().set_input_as_handled()


func get_slots() -> Array[TextureRect]:
	return [
		%Item1,
		%Item2
	]


func select_slot(index: int) -> void:
	if index < 0 or index >= slot_item_ids.size():
		return

	# Empty slot: keep current selection.
	if slot_item_ids[index] == &"":
		return

	if selected_slot == index:
		return

	selected_slot = index
	update_selection_visual()
	emit_selection_changed()


func add_item(item_id: StringName, item_texture: Texture2D) -> bool:
	if item_texture == null:
		push_error("Tentativa de adicionar um item sem ícone.")
		return false

	# Não adiciona o mesmo tipo duas vezes.
	if has_item(item_id):
		print("Esse item já está equipado: ", item_id)
		return false

	var slots := get_slots()

	for index in range(slots.size()):
		if slot_item_ids[index] == &"":
			slot_item_ids[index] = item_id
			slots[index].texture = item_texture
			slots[index].visible = true

			# Se não havia item selecionado, seleciona este.
			if selected_slot == -1:
				selected_slot = index

			update_selection_visual()
			emit_selection_changed()

			return true

	print("Não há slot disponível na UI.")
	return false


func remove_item(item_id: StringName) -> void:
	var index := slot_item_ids.find(item_id)

	if index == -1:
		return

	var slots := get_slots()

	slot_item_ids[index] = &""
	slots[index].texture = null

	if selected_slot == index:
		select_first_available_item()

	update_selection_visual()
	emit_selection_changed()


func has_item(item_id: StringName) -> bool:
	return slot_item_ids.has(item_id)


func get_selected_item_id() -> StringName:
	if selected_slot == -1:
		return &""

	return slot_item_ids[selected_slot]


func select_first_available_item() -> void:
	for index in range(slot_item_ids.size()):
		if slot_item_ids[index] != &"":
			selected_slot = index
			return

	selected_slot = -1


func update_selection_visual() -> void:
	var slots := get_slots()

	for index in range(slots.size()):
		var slot := slots[index]

		if slot_item_ids[index] == &"":
			slot.texture = null
			slot.modulate = Color.WHITE
			continue

		if index == selected_slot:
			slot.modulate = Color.WHITE
		else:
			slot.modulate = Color(0.4, 0.4, 0.4, 0.7)


func emit_selection_changed() -> void:
	selected_item_changed.emit(get_selected_item_id())


func clear_all_items() -> void:
	var slots := get_slots()

	for index in range(slots.size()):
		slots[index].texture = null
		slot_item_ids[index] = &""

	selected_slot = -1
	update_selection_visual()
	emit_selection_changed()
