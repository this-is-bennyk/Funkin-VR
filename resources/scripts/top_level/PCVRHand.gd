extends Spatial

export(Array, NodePath) var hand_paths
export(Array, NodePath) var ik_node_paths

var _hands = []
var _ik_nodes = []

func _ready():
	for path in hand_paths:
		_hands.append(get_node(path))
	for path in ik_node_paths:
		_ik_nodes.append(get_node(path))
	
	_set_hand()
	_toggle_hand()
	
	UserData.connect("setting_set", self, "_on_setting_set")

func _on_setting_set(setting, _variant, _category, package):
	if package != "fnfvr":
		return
	
	if setting == "hand_style":
		_set_hand()
	elif setting == "pcvr_runtime":
		_toggle_hand()

func _set_hand():
	var hand_idx = UserData.get_setting("hand_style", 0, "options", "fnfvr")
	
	for i in len(_hands):
		_hands[i].visible = (i == hand_idx)

func _toggle_hand():
	var on_steam_runtime = _on_steam_runtime()
	
	for hand in _hands:
		hand.visible = on_steam_runtime
	
	for ik_node in _ik_nodes:
		var running = ik_node.is_running()
		
		if on_steam_runtime:
			if !running:
				ik_node.start()
		else:
			if running:
				ik_node.stop()

func _on_steam_runtime():
	# PCVR Runtime 0 = SteamVR
	return OS.get_name() != "Android" && UserData.get_setting("pcvr_runtime", 0, "options", "fnfvr") == 0
