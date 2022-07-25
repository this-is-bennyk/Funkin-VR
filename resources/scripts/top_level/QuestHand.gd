extends Spatial

const A_TOUCH = 5
const B_TOUCH = 6

export(NodePath) var controller_path

onready var main = get_tree().root.get_node("Main")
onready var hand_animation_tree = $AnimationTree
onready var hands = [
	$"Boyfriend Hand/Boyfriend Armature",
	$Armature001/Skeleton/FNFHand
]
onready var controller: ARVRController = get_node(controller_path)

func _ready():
	_set_hand()
	_toggle_hand()
	
	UserData.connect("setting_set", self, "_on_setting_set")

func _process(_delta):
	_set_fingers()
	_set_thumb()

func _set_fingers():
	var index_val = controller.get_joystick_axis(JOY_VR_ANALOG_TRIGGER)
	var grip_val = controller.get_joystick_axis(JOY_VR_ANALOG_GRIP)
	
	hand_animation_tree.set("parameters/Fingers/blend_position", Vector2(index_val, grip_val))

func _set_thumb():
	var thumb_val = 1.0 if controller.is_button_pressed(A_TOUCH) || controller.is_button_pressed(B_TOUCH) else 0.0
	hand_animation_tree.set("parameters/Fingers/blend_amount", thumb_val)

func _on_setting_set(setting, _variant, _category, package):
	if package != "fnfvr":
		return
	
	if setting == "hand_style":
		_set_hand()
	elif setting == "pcvr_runtime":
		_toggle_hand()

func _set_hand():
	var hand_idx = UserData.get_setting("hand_style", 0, "options", "fnfvr")
	
	for i in len(hands):
		hands[i].visible = (i == hand_idx)

func _toggle_hand():
	var on_meta_runtime = _on_meta_runtime()
	
	set_process(on_meta_runtime)
	visible = on_meta_runtime

func _on_meta_runtime():
	# PCVR Runtime 1 = Oculus
	return OS.get_name() == "Android" || \
		  (OS.get_name() != "Android" && UserData.get_setting("pcvr_runtime", 0, "options", "fnfvr") == 1)
