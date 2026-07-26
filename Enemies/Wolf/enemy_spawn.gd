extends Area3D


@export_category("Limite")
@export_range(1, 300, 1) var MAX_ENEMYS: int = 90


@export_category("Spawn normal")
## Y: tempo entre os spawns.
@export_range(0.1, 300.0, 0.1) var spawn_interval: float = 10.0

## X: quantidade criada em cada spawn normal.
@export_range(1, 100, 1) var enemies_per_spawn: int = 3

## Cria inimigos imediatamente quando o jogo começa.
@export var spawn_on_start: bool = true


@export_category("Super Horda")
## Z: quantidade criada quando calamity_superhord começar.
@export_range(1, 300, 1) var superhord_enemy_amount: int = 20

@export var superhord_calamity_id: String = "calamity_superhord"


@export_category("Cenas")
@export var WOLF_SCN: PackedScene
@export var TROLL_SCN: PackedScene
@export var RAT_SCN: PackedScene


@export_category("Calamidades")
@export var calamity_controller: CalamityController


var spawn_timer: Timer
var enemy_scenes: Array[PackedScene] = []


func _ready() -> void:
	randomize()

	prepare_enemy_scenes()
	create_spawn_timer()
	connect_calamity_controller()

	if spawn_on_start:
		spawn_enemies(enemies_per_spawn)


func prepare_enemy_scenes() -> void:
	enemy_scenes.clear()

	if WOLF_SCN != null:
		enemy_scenes.append(WOLF_SCN)

	if TROLL_SCN != null:
		enemy_scenes.append(TROLL_SCN)

	if RAT_SCN != null:
		enemy_scenes.append(RAT_SCN)

	if enemy_scenes.is_empty():
		push_error(
			"Spawner: configure WOLF_SCN, TROLL_SCN e/ou RAT_SCN no Inspector."
		)
	else:
		print(
			"Spawner preparado com ",
			enemy_scenes.size(),
			" tipos de inimigos."
		)


func create_spawn_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false

	add_child(spawn_timer)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

	print(
		"Timer de spawn iniciado. Próximo spawn em ",
		spawn_interval,
		" segundos."
	)


func connect_calamity_controller() -> void:
	if calamity_controller == null:
		push_warning(
			"Spawner: CalamityController não foi colocado no Inspector."
		)
		return

	if not calamity_controller.calamity_started.is_connected(
		_on_calamity_controller_calamity_started
	):
		calamity_controller.calamity_started.connect(
			_on_calamity_controller_calamity_started
		)


func _on_spawn_timer_timeout() -> void:
	print("Timer terminou. Tentando spawnar inimigos.")

	spawn_enemies(enemies_per_spawn)


func spawn_enemies(amount: int) -> void:
	var enemies_container: Node = get_node_or_null("../Enemies")
	var player: Node3D = get_node_or_null("../Player") as Node3D
	var base: Node3D = get_node_or_null("../Base Hitbox") as Node3D

	if enemies_container == null:
		push_error(
			"Spawner: não encontrou o nó ../Enemies."
		)
		return

	if player == null:
		push_error(
			"Spawner: não encontrou o nó ../Player."
		)
		return

	if base == null:
		push_error(
			"Spawner: não encontrou o nó ../Base Hitbox."
		)
		return

	if enemy_scenes.is_empty():
		push_error(
			"Spawner: nenhuma cena de inimigo foi configurada."
		)
		return

	var current_enemies: int = enemies_container.get_child_count()
	var available_space: int = MAX_ENEMYS - current_enemies
	var amount_to_spawn: int = mini(amount, available_space)

	print(
		"Inimigos atuais: ",
		current_enemies,
		" | Tentando criar: ",
		amount_to_spawn
	)

	if amount_to_spawn <= 0:
		print("Spawner: limite máximo de inimigos atingido.")
		return

	for _index in range(amount_to_spawn):
		var selected_scene: PackedScene = enemy_scenes.pick_random()

		if selected_scene == null:
			continue

		var enemy: Node3D = selected_scene.instantiate() as Node3D

		if enemy == null:
			push_error(
				"Spawner: a raiz da cena do inimigo precisa ser Node3D."
			)
			continue

		var random_position: Vector3 = random_point_in_area()

		# Define as referências antes de adicionar o inimigo.
		# Os três scripts de inimigo precisam possuir:
		# @export var Player: Node3D
		# @export var Base: Node3D
		enemy.set("Player", player)
		enemy.set("Base", base)

		enemies_container.add_child(enemy)

		enemy.global_position = Vector3(
			random_position.x,
			1.0,
			random_position.z
		)

		print(
			"Inimigo criado: ",
			selected_scene.resource_path,
			" em ",
			enemy.global_position
		)


func random_point_in_area() -> Vector3:
	var collision_shape: CollisionShape3D = (
		get_node_or_null("CollisionShape3D") as CollisionShape3D
	)

	if collision_shape == null:
		push_error(
			"Spawner: não encontrou CollisionShape3D dentro do Area3D."
		)
		return global_position

	var box: BoxShape3D = collision_shape.shape as BoxShape3D

	if box == null:
		push_error(
			"Spawner: CollisionShape3D precisa utilizar BoxShape3D."
		)
		return global_position

	var extents: Vector3 = box.size * 0.5

	var local_position := Vector3(
		randf_range(-extents.x, extents.x),
		0.0,
		randf_range(-extents.z, extents.z)
	)

	return collision_shape.global_transform * local_position


func _on_calamity_controller_calamity_started(
	_instance_id: int,
	calamity: CalamityData
) -> void:
	if calamity == null:
		return

	var started_calamity_id: String = str(
		calamity.get("calamity_id")
	)

	print(
		"Calamidade iniciada: ",
		started_calamity_id
	)

	if started_calamity_id != superhord_calamity_id:
		return

	print(
		"Super horda iniciada. Criando ",
		superhord_enemy_amount,
		" inimigos."
	)

	spawn_enemies(superhord_enemy_amount)
