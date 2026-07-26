class_name CalamityBlackout
extends Node

@export var controller: CalamityController

@export_group("Elementos afetados")
@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D

@export_group("Configuração")
@export var calamity_id: StringName = &"calamity_blackout"

var _blackout_active: bool = false
var _active_tween: Tween

# Configurações originais.
var _original_light_visible: bool
var _original_light_energy: float

var _original_background_energy: float
var _original_ambient_light_energy: float
var _original_reflected_light_source: Environment.ReflectionSource


func _ready() -> void:
	add_to_group("calamity_blackout")

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

	# Duplicate so we never mutate the PackedScene-cached Environment.
	# Otherwise Play Again / reload keeps the darkened settings.
	if world_environment.environment != null:
		world_environment.environment = world_environment.environment.duplicate()

	directional_light.visible = false

	if world_environment.environment == null:
		return

	var env := world_environment.environment
	_kill_active_tween()
	_active_tween = create_tween()
	_active_tween.set_parallel(true)

	_active_tween.tween_property(
		env, "background_energy_multiplier",
		0.0, 1.0
	)
	_active_tween.tween_property(
		env, "ambient_light_energy",
		0.0, 1.0
	)

	_active_tween.set_parallel(false)
	_active_tween.tween_callback(func():
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	)


func stop_blackout() -> void:
	if not _blackout_active:
		return

	_blackout_active = false
	_kill_active_tween()

	directional_light.visible = _original_light_visible
	directional_light.light_energy = _original_light_energy

	if world_environment.environment == null:
		return

	var env := world_environment.environment
	env.background_energy_multiplier = _original_background_energy
	env.ambient_light_energy = _original_ambient_light_energy
	env.reflected_light_source = _original_reflected_light_source


func _kill_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null


func _save_original_settings() -> void:
	_original_light_visible = directional_light.visible
	_original_light_energy = directional_light.light_energy

	var env := world_environment.environment
	if env == null:
		return

	_original_background_energy = env.background_energy_multiplier
	_original_ambient_light_energy = env.ambient_light_energy
	_original_reflected_light_source = env.reflected_light_source
