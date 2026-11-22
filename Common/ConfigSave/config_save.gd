extends Object
class_name ConfigSave

const PATH_CONFIG: String = "user://config.cfg"
const SETTINGS: String = "Settings"
const MASTER: String = "Master"
const MUSIC: String = "Music"
const SFX: String = "SFX"
const IDIOMA: String = "Idioma"

static var config: ConfigFile = ConfigFile.new()


static func save() -> Error:
	return config.save(PATH_CONFIG)


static func load() -> Error:
	return config.load(PATH_CONFIG)


static func set_value(key: String, value: Variant) -> void:
	config.set_value(SETTINGS, key, value)


static func get_value(key: String, default: Variant = null) -> Variant:
	return config.get_value(SETTINGS, key, default)
