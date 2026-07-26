extends RefCounted

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "score"
const KEY_HIGHSCORE := "highscore"


static func load_highscore() -> int:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	if err != OK:
		return 0
	return maxi(int(config.get_value(SECTION, KEY_HIGHSCORE, 0)), 0)


static func save_highscore(value: int) -> void:
	value = maxi(value, 0)
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value(SECTION, KEY_HIGHSCORE, value)
	config.save(CONFIG_PATH)


## Saves only if score beats the stored highscore. Returns the (possibly updated) highscore.
static func submit_score(score: int) -> int:
	var highscore := load_highscore()
	if score > highscore:
		highscore = score
		save_highscore(highscore)
	return highscore
