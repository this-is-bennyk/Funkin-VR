extends Spatial

onready var height_text = $Height_Adjuster_VP/Height_Text
onready var confirmation_text = $Height_Adjuster_VP/Confirmation_Text

onready var height_ring = $Height_Ring

var left_stick_wait_time = 0.25
var right_stick_wait_time = 0.25

func _ready():
	yield(get_tree().create_timer(0.5), "timeout")
	Player.set_player_height(true)
	
	height_text.bbcode_text = "[code][center]" + str(Player.arvr_origin.world_scale)
	Player.left_hand.connect("button_pressed", self, "finish_height_adjustment")
	Player.right_hand.connect("button_pressed", self, "finish_height_adjustment")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var left_stick_x_axis = -Player.left_hand.get_joystick_axis(0)
	var right_stick_x_axis = -Player.right_hand.get_joystick_axis(0)
	
	print("left x: " + str(left_stick_x_axis))
	
	if left_stick_x_axis != 0 && right_stick_x_axis == 0:
		if left_stick_wait_time > 0:
			left_stick_wait_time -= delta
		else:
			Player.arvr_origin.world_scale += 0.01 * sign(left_stick_x_axis)
			height_text.bbcode_text = "[code][center]" + str(Player.arvr_origin.world_scale)
			
			left_stick_wait_time = 0.25
	else:
		left_stick_wait_time = 0
	
	if left_stick_x_axis == 0 && right_stick_x_axis != 0:
		if right_stick_wait_time > 0:
			right_stick_wait_time -= delta
		else:
			Player.arvr_origin.world_scale += 0.001 * sign(right_stick_x_axis)
			height_text.bbcode_text = "[code][center]" + str(Player.arvr_origin.world_scale)
			
			right_stick_wait_time = 0.25
	else:
		right_stick_wait_time = 0
	
	if Player.is_correct_height():
		height_ring.material.albedo_color = Color.green
		height_ring.material.albedo_color.a = 0.25
		
		confirmation_text.bbcode_text = "[center]Press TRIGGER to continue."
	
	else:
		height_ring.material.albedo_color = Color.red
		height_ring.material.albedo_color.a = 0.25
		
		confirmation_text.bbcode_text = "[center][color=gray]In order to proceed, adjust your height."

func finish_height_adjustment(button):
	if button == JOY_VR_TRIGGER && Player.is_correct_height():
		Settings.set_setting("player", "in_game_height", Player.arvr_origin.world_scale)
		Settings.save_settings()
		get_parent().load_scene("res://prototypes/menus/Disclaimer.tscn")
