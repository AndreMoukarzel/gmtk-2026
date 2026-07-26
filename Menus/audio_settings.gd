extends RefCounted

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "audio"
const KEY_VOLUME := "master_volume"
const BUS_INDEX := 0


static func load_volume_percent() -> float:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		return 100.0
	return clampf(float(config.get_value(SECTION, KEY_VOLUME, 100.0)), 0.0, 100.0)


static func save_volume_percent(percent: float) -> void:
	percent = clampf(percent, 0.0, 100.0)
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value(SECTION, KEY_VOLUME, percent)
	config.save(CONFIG_PATH)


static func apply_volume_percent(percent: float) -> void:
	percent = clampf(percent, 0.0, 100.0)
	var linear := percent / 100.0
	if linear <= 0.001:
		AudioServer.set_bus_mute(BUS_INDEX, true)
		AudioServer.set_bus_volume_db(BUS_INDEX, -80.0)
	else:
		AudioServer.set_bus_mute(BUS_INDEX, false)
		AudioServer.set_bus_volume_db(BUS_INDEX, linear_to_db(linear))
