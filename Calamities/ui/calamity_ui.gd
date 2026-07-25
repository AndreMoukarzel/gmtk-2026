class_name CalamityUI
extends Control

@export var controller: CalamityController

@export var announcement_scene: PackedScene
@export var queue_item_scene: PackedScene


# instance_id → item visual correspondente.
var queue_items: Dictionary = {}


func _ready() -> void:
	controller.calamity_announced.connect(
		_on_calamity_announced
	)

	controller.calamity_countdown_updated.connect(
		_on_calamity_countdown_updated
	)

	controller.calamity_started.connect(
		_on_calamity_started
	)


func _on_calamity_announced(
	instance_id: int,
	calamity: CalamityData,
	warning_time: float
) -> void:
	_show_announcement(calamity)

	var queue_item := queue_item_scene.instantiate() as CalamityQueueItem
	%QueueContainer.add_child(queue_item)

	queue_item.setup(
		instance_id,
		calamity,
		warning_time
	)

	queue_items[instance_id] = queue_item


func _show_announcement(calamity: CalamityData) -> void:
	var announcement := (
		announcement_scene.instantiate()
		as CalamityAnnouncement
	)

	%AnnouncementPosition.add_child(announcement)
	announcement.setup(calamity)
	announcement.play_presentation()


func _on_calamity_countdown_updated(
	instance_id: int,
	remaining_time: float
) -> void:
	if not queue_items.has(instance_id):
		return

	var queue_item := (
		queue_items[instance_id]
		as CalamityQueueItem
	)

	queue_item.update_remaining_time(remaining_time)


func _on_calamity_started(
	instance_id: int,
	calamity: CalamityData
) -> void:
	if not queue_items.has(instance_id):
		return

	var queue_item := (
		queue_items[instance_id]
		as CalamityQueueItem
	)

	queue_items.erase(instance_id)
	queue_item.queue_free()
