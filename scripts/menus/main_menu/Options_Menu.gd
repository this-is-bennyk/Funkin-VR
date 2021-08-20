extends Menu3D

onready var option_pages = [
	$Options_VP/Options_GUI/Page1,
	$Options_VP/Options_GUI/Page2,
	$Options_VP/Options_GUI/Page3
]

var button_ranges = [
	[3, 8],
	[9, 13],
	[14, 33]
]

onready var back_btn_area = $Back/Area

onready var master_vol_text = $Options_VP/Options_GUI/Page1/Master_Vol
onready var music_vol_text = $Options_VP/Options_GUI/Page1/Music_Vol
onready var sfx_vol_text = $Options_VP/Options_GUI/Page1/SFX_Vol

onready var cur_height_text = $Options_VP/Options_GUI/Page2/Cur_Height
onready var height_ring = $Height_Ring
onready var height_warning = $Options_VP/Options_GUI/Warning_Icon

onready var x_pos_text = $Options_VP/Options_GUI/Page3/X_Pos
onready var y_pos_text = $Options_VP/Options_GUI/Page3/Y_Pos
onready var z_pos_text = $Options_VP/Options_GUI/Page3/Z_Pos
onready var angle_text = $Options_VP/Options_GUI/Page3/Angle
onready var scale_text = $Options_VP/Options_GUI/Page3/Scale
onready var test_step_zone = $Test_Step_Zone

onready var version_text = $Options_VP/Options_GUI/Version

var cur_page = 0

func _ready():
	menu_items = {
		$Prev_Page/Area: null,
		$Next_Page/Area: null,
		$Back/Area: null,
		
		$Page1_Buttons/Master_Down/Area: null,
		$Page1_Buttons/Master_Up/Area: null,
		$Page1_Buttons/Music_Down/Area: null,
		$Page1_Buttons/Music_Up/Area: null,
		$Page1_Buttons/SFX_Down/Area: null,
		$Page1_Buttons/SFX_Up/Area: null,
		
		$Page2_Buttons/Height_Down_Thousandth/Area: null,
		$Page2_Buttons/Height_Down_Hundredth/Area: null,
		$Page2_Buttons/Height_Up_Hundredth/Area: null,
		$Page2_Buttons/Height_Up_Thousandth/Area: null,
		$Page2_Buttons/Reset_Height/Area: null,
		
		$Page3_Buttons/XPos_Down_H/Area: null,
		$Page3_Buttons/XPos_Down_T/Area: null,
		$Page3_Buttons/XPos_Up_T/Area: null,
		$Page3_Buttons/XPos_Up_H/Area: null,
		$Page3_Buttons/YPos_Down_H/Area: null,
		$Page3_Buttons/YPos_Down_T/Area: null,
		$Page3_Buttons/YPos_Up_T/Area: null,
		$Page3_Buttons/YPos_Up_H/Area: null,
		$Page3_Buttons/ZPos_Down_H/Area: null,
		$Page3_Buttons/ZPos_Down_T/Area: null,
		$Page3_Buttons/ZPos_Up_T/Area: null,
		$Page3_Buttons/ZPos_Up_H/Area: null,
		$Page3_Buttons/Angle_Down_H/Area: null,
		$Page3_Buttons/Angle_Down_W/Area: null,
		$Page3_Buttons/Angle_Up_W/Area: null,
		$Page3_Buttons/Angle_Up_H/Area: null,
		$Page3_Buttons/Scale_Down_H/Area: null,
		$Page3_Buttons/Scale_Down_T/Area: null,
		$Page3_Buttons/Scale_Up_T/Area: null,
		$Page3_Buttons/Scale_Up_H/Area: null
	}
	
	change_page(0)
	
	change_volume("master", 0, false)
	change_volume("music", 0, false)
	change_volume("sfx", 0, false)
	
	change_height(0, false)
	
	change_step_zone(Vector3(), 0, 0, false)
	
	version_text.text = "Version " + ProjectSettings.get_setting("application/config/version")
	
	Player.play_transition(Player.Transition.FADE_IN)

func do_menu_item_action():
	.do_menu_item_action()
	
	match cur_menu_item.name:
		"Back":
			Settings.save_settings()
			return_to_main_menu()
		"Prev_Page":
			change_page(-1)
		"Next_Page":
			change_page(1)
		
		"Master_Down":
			change_volume("master", -10)
		"Master_Up":
			change_volume("master", 10)
		"Music_Down":
			change_volume("music", -10)
		"Music_Up":
			change_volume("music", 10)
		"SFX_Down":
			change_volume("sfx", -10)
		"SFX_Up":
			change_volume("sfx", 10)
		
		"Height_Down_Thousandth":
			change_height(-0.001)
		"Height_Down_Hundredth":
			change_height(-0.01)
		"Height_Up_Hundredth":
			change_height(0.01)
		"Height_Up_Thousandth":
			change_height(0.001)
		"Reset_Height":
			change_height(null)
		
		"XPos_Down_H":
			change_step_zone(Vector3(-0.01, 0, 0))
		"XPos_Down_T":
			change_step_zone(Vector3(-0.1, 0, 0))
		"XPos_Up_T":
			change_step_zone(Vector3(0.1, 0, 0))
		"XPos_Up_H":
			change_step_zone(Vector3(0.01, 0, 0))
		"YPos_Down_H":
			change_step_zone(Vector3(0, -0.01, 0))
		"YPos_Down_T":
			change_step_zone(Vector3(0, -0.1, 0))
		"YPos_Up_T":
			change_step_zone(Vector3(0, 0.1, 0))
		"YPos_Up_H":
			change_step_zone(Vector3(0, 0.01, 0))
		"ZPos_Down_H":
			change_step_zone(Vector3(0, 0, -0.01))
		"ZPos_Down_T":
			change_step_zone(Vector3(0, 0, -0.1))
		"ZPos_Up_T":
			change_step_zone(Vector3(0, 0, 0.1))
		"ZPos_Up_H":
			change_step_zone(Vector3(0, 0, 0.01))
		"Angle_Down_H":
			change_step_zone(Vector3(), -0.5)
		"Angle_Down_W":
			change_step_zone(Vector3(), -1)
		"Angle_Up_W":
			change_step_zone(Vector3(), 1)
		"Angle_Up_H":
			change_step_zone(Vector3(), 0.5)
		"Scale_Down_H":
			change_step_zone(Vector3(), 0, -0.01)
		"Scale_Down_T":
			change_step_zone(Vector3(), 0, -0.1)
		"Scale_Up_T":
			change_step_zone(Vector3(), 0, 0.1)
		"Scale_Up_H":
			change_step_zone(Vector3(), 0, 0.01)

func change_page(increment):
	cur_page = wrapi(cur_page + increment, 0, len(option_pages))
	var buttons_to_enable = range(3) if Player.is_correct_height() else range(2)
	buttons_to_enable.append_array(range(button_ranges[cur_page][0], button_ranges[cur_page][1] + 1))
	
	for i in len(option_pages):
		option_pages[i].visible = i == cur_page
	
	var button_list = menu_items.keys()
	
	for i in len(menu_items):
		# This is !(index in buttons_to_enable) since we want disabled to be true when
		# the button is not enabled
		set_item_interactable(button_list[i], !(i in buttons_to_enable))
	
	height_ring.visible = cur_page == 1
	test_step_zone.visible = cur_page == 2

func change_volume(bus, increment, update_settings = true):
	if update_settings:
		Settings.set_setting("audio", bus, clamp(Settings.get_setting("audio", bus) + increment, 0, 100))
		Settings.update_volume(bus)
	
	var cur_vol_text = str(Settings.get_setting("audio", bus))
	
	if bus == "master":
		master_vol_text.text = cur_vol_text
	elif bus == "music":
		music_vol_text.text = cur_vol_text
	else:
		sfx_vol_text.text = cur_vol_text

func change_height(increment, update_settings = true):
	if update_settings:
		if increment == null:
			Player.set_player_height(true)
		else:
			Settings.set_setting("player", "in_game_height", Settings.get_setting("player", "in_game_height") + increment)
			Player.set_player_height(false)
	
	cur_height_text.text = str(Settings.get_setting("player", "in_game_height"))
	height_ring.material.albedo_color = Color.green if Player.is_correct_height() else Color.red
	height_ring.material.albedo_color.a = 0.25
	
	height_warning.visible = !Player.is_correct_height()
	set_item_interactable(back_btn_area, height_warning.visible)

func change_step_zone(pos_increment = Vector3(), angle_increment = 0, scale_increment = 0, update_settings = true):
	if update_settings:
		Settings.set_setting("step_zone", "location", Settings.get_setting("step_zone", "location") + pos_increment)
		Settings.set_setting("step_zone", "angle", clamp(Settings.get_setting("step_zone", "angle") + angle_increment, -15, 0))
		Settings.set_setting("step_zone", "scale", clamp(Settings.get_setting("step_zone", "scale") + scale_increment, 0.1, 1))
	
	test_step_zone.translation = Settings.get_setting("step_zone", "location")
	test_step_zone.rotation_degrees.x = Settings.get_setting("step_zone", "angle")
	
	var new_scale = Settings.get_setting("step_zone", "scale")
	test_step_zone.scale = Vector3(new_scale, new_scale, new_scale)
	
	x_pos_text.text = str(test_step_zone.translation.x)
	y_pos_text.text = str(test_step_zone.translation.y)
	z_pos_text.text = str(test_step_zone.translation.z)
	angle_text.text = str(test_step_zone.rotation_degrees.x)
	scale_text.text = str(test_step_zone.scale.x)
