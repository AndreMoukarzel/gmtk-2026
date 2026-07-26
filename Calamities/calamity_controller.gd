class_name CalamityController
extends Node

signal calamity_announced(
	instance_id: int,
	calamity: CalamityData,
	warning_time: float
)

signal calamity_countdown_updated(
	instance_id: int,
	remaining_time: float
)

signal calamity_started(
	instance_id: int,
	calamity: CalamityData
)

signal calamity_finished(
	instance_id: int,
	calamity: CalamityData
)


# Tempo entre um anúncio e outro.
@export var announcement_interval: float = 10.0

# Antecedência inicial da profecia.
@export var warning_time: float = 40.0

# Limite mínimo caso queira diminuir o tempo posteriormente.
@export var minimum_warning_time: float = 3.0

# Quanto o tempo de aviso diminui após cada profecia.
@export var warning_reduction: float = 0.0

@export var available_calamities: Array[CalamityData] = []


var _time_until_next_announcement: float
var _next_instance_id: int = 0

# Guarda a última calamidade anunciada.
var _last_announced_calamity: CalamityData = null

# Cada elemento guarda uma calamidade anunciada ainda não iniciada.
var _pending_calamities: Array[Dictionary] = []


func _ready() -> void:
	randomize()
	_time_until_next_announcement = announcement_interval


func _process(delta: float) -> void:
	_update_announcement_timer(delta)
	_update_pending_calamities(delta)


func _update_announcement_timer(delta: float) -> void:
	if available_calamities.is_empty():
		return

	_time_until_next_announcement -= delta

	if _time_until_next_announcement > 0.0:
		return

	_announce_random_calamity()
	_time_until_next_announcement = announcement_interval


func _update_pending_calamities(delta: float) -> void:
	for index in range(_pending_calamities.size() - 1, -1, -1):
		var pending: Dictionary = _pending_calamities[index]

		pending.remaining_time -= delta

		calamity_countdown_updated.emit(
			pending.instance_id,
			maxf(pending.remaining_time, 0.0)
		)

		if pending.remaining_time <= 0.0:
			_start_calamity(pending)
			_pending_calamities.remove_at(index)


func _announce_random_calamity() -> void:
	var calamity: CalamityData = _pick_random_calamity()

	if calamity == null:
		push_warning(
			"CalamityController: nenhuma calamidade válida disponível."
		)
		return

	_last_announced_calamity = calamity
	_next_instance_id += 1

	var pending := {
		"instance_id": _next_instance_id,
		"calamity": calamity,
		"remaining_time": warning_time
	}

	_pending_calamities.append(pending)

	calamity_announced.emit(
		_next_instance_id,
		calamity,
		warning_time
	)

	warning_time = maxf(
		minimum_warning_time,
		warning_time - warning_reduction
	)


func _pick_random_calamity() -> CalamityData:
	var valid_calamities: Array[CalamityData] = []

	for calamity in available_calamities:
		if calamity == null:
			continue

		if calamity == _last_announced_calamity:
			continue

		valid_calamities.append(calamity)

	# Caso exista somente uma calamidade configurada,
	# permite que ela seja repetida para o sistema não parar.
	if valid_calamities.is_empty():
		for calamity in available_calamities:
			if calamity != null:
				valid_calamities.append(calamity)

	if valid_calamities.is_empty():
		return null

	return valid_calamities.pick_random()


func _start_calamity(pending: Dictionary) -> void:
	var instance_id: int = pending.instance_id
	var calamity: CalamityData = pending.calamity

	calamity_started.emit(
		instance_id,
		calamity
	)

	_finish_calamity_after_duration(
		instance_id,
		calamity
	)


func _finish_calamity_after_duration(
	instance_id: int,
	calamity: CalamityData
) -> void:
	# A duração pausa junto com a árvore do jogo.
	await get_tree().create_timer(
		calamity.duration,
		false
	).timeout

	calamity_finished.emit(
		instance_id,
		calamity
	)
