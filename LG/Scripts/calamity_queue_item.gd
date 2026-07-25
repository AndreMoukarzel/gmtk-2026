class_name CalamityQueueItem
extends PanelContainer

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var time_label: Label = %TimeLabel

var instance_id: int


func setup(
	new_instance_id: int,
	calamity: CalamityData,
	initial_time: float
) -> void:
	instance_id = new_instance_id

	icon.texture = calamity.icon
	name_label.text = calamity.calamity_name

	update_remaining_time(initial_time)


func update_remaining_time(remaining_time: float) -> void:
	time_label.text = "%.1f" % remaining_time
