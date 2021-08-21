extends Node

# ---------- Settings Constants ----------

const DEFAULT_SETTINGS = "res://default_settings.cfg"
const SAVE_PATH = "user://fnfvr_save.cfg"

# Player
#const STATIONARY_ADJUSTMENT = 0.5

# VR Display
const REFRESH_RATES = [72, 90, 120, 144]

# Second Display
const RESOLUTIONS = [[1920, 1080], [1680, 1050], [1600, 900], [1440, 900], [1366, 768], [1280, 720]]

# ---------- Game Constants ----------

const SCROLL_DISTANCE = 1.6 # units
const SCROLL_TIME = 0.8 # sec

var driver_suffix = "_GLES2" if OS.get_name() == "Android" else ""

# ---------- Variables ----------

var _config_file = ConfigFile.new()
var _settings = {}

func _ready():
	var err = _config_file.load(SAVE_PATH)
	if err:
		reset_settings()
	load_settings()

func load_settings():
	var err = _config_file.load(SAVE_PATH)
	if err:
		print("we have royally fucked up error code %s" % err)
		get_tree().quit()
		return
	
	for section in _config_file.get_sections():
		_settings[section] = {}
		for key in _config_file.get_section_keys(section):
			_settings[section][key] = _config_file.get_value(section, key)
	
	update_volume("master")
	update_volume("music")
	update_volume("sfx")
	
	if !OS.get_name() == "Android":
		update_resolution()

func save_settings():
	for section in _settings.keys():
		for key in _settings[section].keys():
			_config_file.set_value(section, key, _settings[section][key])
	
	_config_file.save(SAVE_PATH)

func reset_settings():
	var err = _config_file.load(DEFAULT_SETTINGS)
	
	if err:
		print("extreme uh oh error code %s" % err)
		get_tree().quit()
		return
	
	_config_file.save(SAVE_PATH)

func get_setting(section, key):
	return _settings[section][key]

func set_setting(section, key, value):
	if !(section in _settings):
		_settings[section] = {key: value}
	else:
		_settings[section][key] = value

func has_setting(section, key):
	return section in _settings && key in _settings[section]

func update_volume(bus_name):
	var actual_bus_name = bus_name.to_upper() if bus_name == "sfx" else bus_name.capitalize()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(actual_bus_name), linear2db(get_setting("audio", bus_name) / 100.0))

func update_resolution():
	OS.window_fullscreen = get_setting("second_display", "fullscreen")
	if !OS.window_fullscreen:
		var window_size_idx = get_setting("second_display", "window_size_idx")
		
		OS.window_size = Vector2(RESOLUTIONS[window_size_idx][0], RESOLUTIONS[window_size_idx][1])
		OS.center_window()
