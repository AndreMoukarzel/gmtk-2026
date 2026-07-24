class_name CalamityBlackout
extends Node

@export var controller: CalamityController

@export_group("Elementos afetados")
@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D

@export_group("Configuração")
@export var calamity_id: StringName = &"calamity_blackout"

var _blackout_active: bool = false

# Configurações originais.
var _original_light_visible: bool
var _original_light_energy: float

var _original_environment: Environment
var _original_background_energy: float
var _original_ambient_light_energy: float
var _original_reflected_light_source: Environment.ReflectionSource


func _ready() -> void:
	if controller == null:
		push_error("CalamityBlackout: Controller não configurado.")
		return

	if world_environment == null:
		push_error("CalamityBlackout: WorldEnvironment não configurado.")
		return

	if directional_light == null:
		push_error("CalamityBlackout: DirectionalLight3D não configurada.")
		return

	controller.calamity_started.connect(_on_calamity_started)
	controller.calamity_finished.connect(_on_calamity_finished)


func _on_calamity_started(
	_instance_id: int,
	calamity: CalamityData
) -> void:
	if calamity.calamity_id != calamity_id:
		return

	start_blackout()


func _on_calamity_finished(
	_instance_id: int,
	calamity: CalamityData
) -> void:
	if calamity.calamity_id != calamity_id:
		return

	stop_blackout()


func start_blackout() -> void:
	if _blackout_active:
		return

	_blackout_active = true

	_save_original_settings()

	# Desliga a luz direcional.
	directional_light.visible = false

	# Escurece o ambiente.
	if world_environment.environment != null:
		world_environment.environment.background_energy_multiplier = 0.0
		world_environment.environment.ambient_light_energy = 0.0
		world_environment.environment.reflected_light_source = (
			Environment.REFLECTION_SOURCE_DISABLED
	)


func stop_blackout() -> void:
	if not _blackout_active:
		return

	_blackout_active = false

	# Restaura a luz direcional.
	directional_light.visible = _original_light_visible
	directional_light.light_energy = _original_light_energy

	# Restaura as configurações originais do ambiente.
	if world_environment.environment != null:
		world_environment.environment.background_energy_multiplier = (
			_original_background_energy
		)

		world_environment.environment.ambient_light_energy = (
			_original_ambient_light_energy
		)

		world_environment.environment.reflected_light_source = (
			_original_reflected_light_source
		)


func _save_original_settings() -> void:
	_original_light_visible = directional_light.visible
	_original_light_energy = directional_light.light_energy

	_original_environment = world_environment.environment

	if _original_environment == null:
		return

	_original_background_energy = (
		_original_environment.background_energy_multiplier
	)

	_original_ambient_light_energy = (
		_original_environment.ambient_light_energy
	)

	_original_reflected_light_source = (
		_original_environment.reflected_light_source
	)
