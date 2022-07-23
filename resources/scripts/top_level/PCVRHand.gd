extends Spatial

export(Array, NodePath) var hand_paths
export(Array, NodePath) var ik_node_paths

var _hands = []

func _ready():
	for path in hand_paths:
		_hands.append(get_node(path))
	
	if OS.get_name() == "Android":
		for hand in _hands:
			hand.hide()
		return
	
	for ik_node_path in ik_node_paths:
		get_node(ik_node_path).start()
	
	_set_hand()
	UserData.connect("setting_set", self, "_on_setting_set")

func _on_setting_set(setting, _variant, _category, package):
	if setting == "hand_style" && package == "fnfvr":
		_set_hand()

func _set_hand():
	var hand_idx = UserData.get_setting("hand_style", 0, "options", "fnfvr")
	
	for i in len(_hands):
		_hands[i].visible = (i == hand_idx)
