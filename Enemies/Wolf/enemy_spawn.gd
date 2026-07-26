extends Area3D


@export_category("Limite")
## Quantidade máxima de inimigos vivos ao mesmo tempo.
@export_range(1, 300, 1) var MAX_ENEMYS: int = 90


@export_category("Spawn automático")
## Tempo entre os spawns automáticos.
@export_range(0.1, 300.0, 0.1) var spawn_interval: float = 10.0

## Quantidade de RATs em cada spawn automático.
@export_range(0, 100, 1) var automatic_rats: int = 3

## Quantidade de WOLFs em cada spawn automático.
@export_range(0, 100, 1) var automatic_wolves: int = 1

## Quantidade de TROLLs em cada spawn automático.
@export_range(0, 100, 1) var automatic_trolls: int = 0

## Realiza um spawn automático imediatamente quando o jogo começa.
@export var spawn_on_start: bool = true


@export_category("Super Horda")
## ID da calamidade que inicia a Super Horda.
@export var superhord_calamity_id: String = "calamity_superhord"

## Quantidade de RATs criados na Super Horda.
@export_range(0, 300, 1) var superhord_rats: int = 10

## Quantidade de WOLFs criados na Super Horda.
@export_range(0, 300, 1) var superhord_wolves: int = 5

## Quantidade de TROLLs criados na Super Horda.
@export_range(0, 300, 1) var superhord_trolls: int = 5


@export_category("Cenas")
@export var WOLF_SCN: PackedScene
@export var TROLL_SCN: PackedScene
@export var RAT_SCN: PackedScene


@export_category("Calamidades")
@export var calamity_controller: CalamityController


var spawn_timer: Timer


func _ready() -> void:
	randomize()

	validate_enemy_scenes()
	create_spawn_timer()
	connect_calamity_controller()

	if spawn_on_start:
		spawn_automatic_wave()


## Verifica se as cenas dos inimigos foram configuradas.
func validate_enemy_scenes() -> void:
	if RAT_SCN == null:
		push_warning(
			"Spawner: RAT_SCN não foi configurada no Inspector."
		)

	if WOLF_SCN == null:
		push_warning(
			"Spawner: WOLF_SCN não foi configurada no Inspector."
		)

	if TROLL_SCN == null:
		push_warning(
			"Spawner: TROLL_SCN não foi configurada no Inspector."
		)


## Cria o timer responsável pelos spawns automáticos.
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


## Conecta o spawner ao início das calamidades.
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
	print("Timer terminou. Criando spawn automático.")

	spawn_automatic_wave()


## Cria a onda automática utilizando as quantidades definidas no Inspector.
func spawn_automatic_wave() -> void:
	var total_amount: int = (
		automatic_rats
		+ automatic_wolves
		+ automatic_trolls
	)

	print(
		"Spawn automático iniciado: ",
		automatic_rats,
		" RATs, ",
		automatic_wolves,
		" WOLFs e ",
		automatic_trolls,
		" TROLLs. Total: ",
		total_amount
	)

	spawn_specific_enemies(
		RAT_SCN,
		automatic_rats,
		"RAT"
	)

	spawn_specific_enemies(
		WOLF_SCN,
		automatic_wolves,
		"WOLF"
	)

	spawn_specific_enemies(
		TROLL_SCN,
		automatic_trolls,
		"TROLL"
	)


## Cria a Super Horda utilizando as quantidades definidas no Inspector.
func spawn_superhord_wave() -> void:
	var total_amount: int = (
		superhord_rats
		+ superhord_wolves
		+ superhord_trolls
	)

	print(
		"Super Horda iniciada: ",
		superhord_rats,
		" RATs, ",
		superhord_wolves,
		" WOLFs e ",
		superhord_trolls,
		" TROLLs. Total solicitado: ",
		total_amount
	)

	spawn_specific_enemies(
		RAT_SCN,
		superhord_rats,
		"RAT"
	)

	spawn_specific_enemies(
		WOLF_SCN,
		superhord_wolves,
		"WOLF"
	)

	spawn_specific_enemies(
		TROLL_SCN,
		superhord_trolls,
		"TROLL"
	)


## Cria uma quantidade específica de determinado inimigo.
func spawn_specific_enemies(
	enemy_scene: PackedScene,
	amount: int,
	enemy_name: String
) -> void:
	if amount <= 0:
		return

	if enemy_scene == null:
		push_warning(
			"Spawner: a cena de ",
			enemy_name,
			" não foi configurada no Inspector."
		)
		return

	for _index in range(amount):
		if not has_available_space():
			print(
				"Spawner: limite máximo de inimigos atingido durante o spawn de ",
				enemy_name,
				"."
			)
			return

		spawn_enemy_scene(enemy_scene)


## Instancia um inimigo e o posiciona dentro da área.
func spawn_enemy_scene(enemy_scene: PackedScene) -> void:
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

	if enemy_scene == null:
		return

	var enemy: Node3D = enemy_scene.instantiate() as Node3D

	if enemy == null:
		push_error(
			"Spawner: a raiz da cena do inimigo precisa ser Node3D."
		)
		return

	var random_position: Vector3 = random_point_in_area()

	# Os scripts dos inimigos precisam possuir:
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
		enemy_scene.resource_path,
		" em ",
		enemy.global_position
	)


## Verifica se ainda existe espaço até o limite máximo.
func has_available_space() -> bool:
	var enemies_container: Node = get_node_or_null("../Enemies")

	if enemies_container == null:
		push_error(
			"Spawner: não encontrou o nó ../Enemies."
		)
		return false

	return enemies_container.get_child_count() < MAX_ENEMYS


## Escolhe uma posição aleatória dentro do BoxShape3D.
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


## Detecta quando uma calamidade começa.
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

	spawn_superhord_wave()
