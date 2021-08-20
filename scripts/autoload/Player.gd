extends Viewport

signal retry

#const MODEL_SCALE = 0.011
const MODEL_SCALE = 0.011
const JUST_PRESSED_TIME = 1 / 60.0
const HAND_SIZE = Vector3(0.1, 0.01, 0.01)
var STEP_ZONE_SIZE = 0.65
#var GRIP_IDX = 3 if OS.get_name() == "Android" else JOY_VR_ANALOG_GRIP

const MISS_MATERIAL = preload("res://assets/models/chars/bf/regular/BoyfriendFailTex.material")
const DEATH_MATERIAL = preload("res://assets/models/chars/bf/Death_Material.tres")

const DEFAULT_DEATH_MUSIC = preload("res://assets/music/fnf/gameOver.ogg")
const DEFAULT_DEATH_SOUND = preload("res://assets/sounds/fnf_loss_sfx.ogg")
const DEFAULT_RETRY_SOUND = preload("res://assets/music/fnf/gameOverEnd.ogg")
const RETURN_TO_MAIN_MENU_SOUND = preload("res://assets/sounds/cancelMenu.ogg")

# Amount of rumble initially set doesn't seem to matter for Quest 2 on PC
const NOTE_RUMBLE = 0.25
const SUSTAIN_RUMBLE = 0.1
const RUMBLE_DECAY = 2

enum Transition {FLASH, FADE_IN, FADE_OUT, DEATH_FADE}

# Player Model Stuff

onready var arvr_origin = $Player_Model
onready var camera = $Player_Model/ARVRCamera

onready var screen_flash = $Player_Model/ARVRCamera/Screen_Flash
onready var screen_flash_gles2 = $Player_Model/ARVRCamera/Screen_Flash_GLES2

onready var screen_wipe = $Player_Model/ARVRCamera/Screen_Wipe
onready var screen_wipe_gles2 = $Player_Model/ARVRCamera/Screen_Wipe_GLES2

onready var screen_anim: AnimationPlayer = $Player_Model/ARVRCamera/Screen_Anim

onready var left_hand = $Player_Model/Left_Hand
onready var left_hand_model = $Player_Model/Left_Hand/Hand_Model
onready var left_raycast = $Player_Model/Left_Hand/RayCast
onready var left_collision_indicator = $Player_Model/Left_Hand/Ray_Collision_Indicator

onready var right_hand = $Player_Model/Right_Hand
onready var right_hand_model = $Player_Model/Right_Hand/Hand_Model
onready var right_raycast = $Player_Model/Right_Hand/RayCast
onready var right_collision_indicator = $Player_Model/Right_Hand/Ray_Collision_Indicator

onready var bf_model = $Player_Model/Boyfriend
onready var bf_skeleton = $"Player_Model/Boyfriend/Boyfriend Armature/Skeleton"

# Controller Stuff

onready var left_hand_aabb = AABB($Player_Model/Left_Hand.global_transform.origin - HAND_SIZE * STEP_ZONE_SIZE / 2, HAND_SIZE * STEP_ZONE_SIZE)
onready var right_hand_aabb = AABB($Player_Model/Right_Hand.global_transform.origin - HAND_SIZE * STEP_ZONE_SIZE / 2, HAND_SIZE * STEP_ZONE_SIZE)

var left_hand_trigger_just_pressed = false
#var left_hand_trigger_just_pressed_time = 0
var left_hand_trigger_continued_press = false

#var left_hand_grip_just_pressed = false
##var left_hand_grip_just_pressed_time = 0
#var left_hand_grip_continued_press = false

var right_hand_trigger_just_pressed = false
#var right_hand_trigger_just_pressed_time = 0
var right_hand_trigger_continued_press = false

#var right_hand_grip_just_pressed = false
##var right_hand_grip_just_pressed_time = 0
#var right_hand_grip_continued_press = false

# Death Menu Stuff

onready var death_menu = $Death_Menu
onready var dropped_mic = $Death_Menu/Dropped_Microphone
onready var blue_balls = $Death_Menu/Blue_Balls

onready var retry_text = $Death_Menu/Retry_Text
onready var retry_text_anim = $Death_Menu/Retry_Text/AnimationPlayer
onready var retry_info = $Death_Menu/Retry_Info

onready var death_sfx_player = $Death_Menu/Death_SFX
onready var death_tween = $Death_Menu/Tween

# Pause Menu Stuff

onready var pause_menu = $Pause_Menu
onready var pause_music = $Pause_Menu/Pause_Music

var can_pause = false
var pause_timer: SceneTreeTimer

# VR Interface Stuff

# WTF: GLES2 DOES NOT WORK WHEN TESTING ON DESKTOP.
# NOTHING WILL RENDER TO THE HEADSET IF YOU'RE NOT USING GLES3.

var VR: ARVRInterface
var ovr_mobile_init_config
var ovr_mobile_performance
var ovr_mobile_runtime_config_performed = false

const DEBUG = false

func _ready():
	if DEBUG:
		arvr_origin.visible = false
		set_process(false)
		return
	
	initialize_vr()
	
	left_hand.connect("button_pressed", self, "on_controller_button_detected", [false, true])
	left_hand.connect("button_release", self, "on_controller_button_detected", [false, false])
	right_hand.connect("button_pressed", self, "on_controller_button_detected", [true, true])
	right_hand.connect("button_release", self, "on_controller_button_detected", [true, false])
	
	screen_flash.rect_size = ARVRServer.primary_interface.get_render_targetsize()
	screen_wipe.rect_size = ARVRServer.primary_interface.get_render_targetsize()
	
	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("root"), Transform(Basis(), Vector3(-0.3 / bf_model.scale.x, 0, 0)))
	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("head"), Transform(Vector3(), Vector3(), Vector3(), Vector3()))
	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("shoulder_l"), Transform(Vector3(), Vector3(), Vector3(), Vector3()))
	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("shoulder_r"), Transform(Vector3(), Vector3(), Vector3(), Vector3()))
	
	left_hand_model.scale /= 2
	left_hand_model.get_node("AnimationPlayer").play("Point")
	
	right_hand_model.scale /= 2
	right_hand_model.get_node("AnimationPlayer").play("Point_Mic")
	
	if OS.get_name() == "Android":
		left_hand_model.rotate_x(PI / 2)
		right_hand_model.rotate_x(PI / 2)
		
		left_raycast.cast_to = Vector3(0, 0, -10)
		right_raycast.cast_to = Vector3(0, 0, -10)
	
	retry_text.hide()
	retry_info.hide()
	retry_text.bumping = false
	retry_text.material_override.set_shader_param("frequency", 0.0)
	retry_text.material_override.set_shader_param("amplitude", 0.0)
	blue_balls.bumping = false
	
	if Settings.get_setting("player", "in_game_height") != -999:
		set_player_height(false)
	
	set_process(true)

func _process(delta):
	# Quests: Perform runtime config stuff here for some reason
	if OS.get_name() == "Android" && !ovr_mobile_runtime_config_performed:
		ovr_mobile_performance = load("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
		
		ovr_mobile_performance.set_clock_levels(1, 1)
		ovr_mobile_performance.set_extra_latency_mode(1)
		
		ovr_mobile_runtime_config_performed = true
	
	# Update hand hitboxes
	
#	left_hand_aabb.position = left_hand_model.global_transform.origin - HAND_SIZE * STEP_ZONE_SIZE / 2
#	right_hand_aabb.position = right_hand_model.global_transform.origin - HAND_SIZE * STEP_ZONE_SIZE / 2
	
#	$Left_Box.global_transform.origin = left_hand_aabb.position
#	$Right_Box.global_transform.origin = right_hand_aabb.position
	
	# Update rumble
	
	if left_hand.rumble > 0:
		left_hand.rumble -= delta * RUMBLE_DECAY
		if left_hand.rumble < 0:
			left_hand.rumble = 0
	
	if right_hand.rumble > 0:
		right_hand.rumble -= delta * RUMBLE_DECAY
		if right_hand.rumble < 0:
			right_hand.rumble = 0
	
	# Update analog just pressed checks
	
#	if left_hand_trigger_just_pressed_time > 0:
#		left_hand_trigger_just_pressed_time -= delta
#	else:
	left_hand_trigger_just_pressed = false
#		left_hand_trigger_just_pressed_time = 0
	
#	if left_hand_grip_just_pressed_time > 0:
#		left_hand_grip_just_pressed_time -= delta
#	else:
#	left_hand_grip_just_pressed = false
#		left_hand_grip_just_pressed_time = 0
	
#	if right_hand_trigger_just_pressed_time > 0:
#		right_hand_trigger_just_pressed_time -= delta
#	else:
#	right_hand_trigger_just_pressed = false
#		right_hand_trigger_just_pressed_time = 0
	
#	if right_hand_grip_just_pressed_time > 0:
#		right_hand_grip_just_pressed_time -= delta
#	else:
#	right_hand_grip_just_pressed = false
#		right_hand_grip_just_pressed_time = 0
	
	# Update trigger presses
	
	update_analog_press(true, JOY_VR_ANALOG_TRIGGER)
#	update_analog_press(true, GRIP_IDX)
	update_analog_press(false, JOY_VR_ANALOG_TRIGGER)
#	update_analog_press(false, GRIP_IDX)
	
	# Update model rotation + translation
	
	bf_model.rotation.y = camera.rotation.y + PI
	bf_model.translation.x = camera.translation.x
	bf_model.translation.z = camera.translation.z
	
	left_raycast.force_raycast_update()
	right_raycast.force_raycast_update()
	
	if left_raycast.is_colliding():
		left_collision_indicator.show()
		left_collision_indicator.global_transform.origin = left_raycast.get_collision_point()
	else:
		left_collision_indicator.hide()
	
	if right_raycast.is_colliding():
		right_collision_indicator.show()
		right_collision_indicator.global_transform.origin = right_raycast.get_collision_point()
	else:
		right_collision_indicator.hide()
	
	blue_balls.global_transform = Transform(Basis(Quat(bf_model.global_transform.basis.get_rotation_quat())), bf_model.global_transform.origin)

func play_transition(transition):
	screen_anim.stop()
	var anim_suffix = "_GLES2" if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2 else ""
	var anim_name
	
	match transition:
		Transition.FLASH:
			anim_name = "Flash"
		Transition.FADE_IN:
			anim_name = "Fade_In"
		Transition.FADE_OUT:
			anim_name = "Fade_Out"
		Transition.DEATH_FADE:
			anim_name = "Death_Fade"
	
	screen_anim.play(anim_name + anim_suffix)

func do_game_over(death_sound = null, death_music = null, retry_sound = null):
	death_menu.show()
	dropped_mic.show()
	dropped_mic.global_transform = right_hand_model.global_transform
	switch_materials(DEATH_MATERIAL)
	
	var dropped_mic_final_xform = Transform(Basis(Quat(Vector3(0, -PI / 2, 0))).scaled(dropped_mic.global_transform.basis.get_scale()),
											dropped_mic.global_transform.origin * Vector3(1, 0, 1))
	
	if !_retry_or_quit_pressed():
		death_sfx_player.stream = death_sound if death_sound else DEFAULT_DEATH_SOUND
		death_sfx_player.play()
		
		yield(get_tree().create_timer(0.65), "timeout")
		
		if !_retry_or_quit_pressed():
			death_tween.interpolate_property(dropped_mic, "global_transform",
											 dropped_mic.global_transform,
											 dropped_mic_final_xform,
											 0.38, Tween.TRANS_EXPO, Tween.EASE_IN)
			death_tween.start()
			yield(get_tree().create_timer(34 / 24.0), "timeout")
			
			retry_text.show()
			retry_info.show()
			retry_text.bumping = true
			retry_text.material_override.set_shader_param("frequency", 2.0)
			retry_text.material_override.set_shader_param("amplitude", 0.1)
			blue_balls.bumping = true
			
			if death_music:
				Conductor.play_song(death_music, 100)
			else:
				Conductor.play_song(DEFAULT_DEATH_MUSIC, 100)
	
			# TODO: replace this
			while !_retry_or_quit_pressed():
				yield(get_tree(), "idle_frame")
			
			Conductor.stop_song()
		
		else:
			death_sfx_player.stop()
			dropped_mic.global_transform = dropped_mic_final_xform
		
	else:
		dropped_mic.global_transform = dropped_mic_final_xform
	
	# TODO: Finish this shit
	Conductor.stop_song()
	
	if left_hand_trigger_continued_press || right_hand_trigger_continued_press:
		dropped_mic.hide()
		
		retry_text.show() # if we haven't already
		retry_info.hide()
		retry_text.bumping = false
		retry_text.material_override.set_shader_param("frequency", 0.0)
		retry_text.material_override.set_shader_param("amplitude", 0.0)
		retry_text_anim.play("Confirm")
		blue_balls.bumping = false
		
		death_sfx_player.stream = retry_sound if retry_sound else DEFAULT_RETRY_SOUND
		death_sfx_player.play()
		yield(get_tree().create_timer(0.7), "timeout")
		
		play_transition(Transition.DEATH_FADE)
		yield(screen_anim, "animation_finished")
		
		retry_text.hide()
		death_menu.hide()
		death_sfx_player.stop()
		
		switch_materials()
		play_transition(Transition.FADE_IN)
		emit_signal("retry")
	else:
		dropped_mic.hide()
		retry_text.hide()
		retry_text_anim.stop()
		retry_info.hide()
		death_menu.hide()
		
		death_sfx_player.stream = RETURN_TO_MAIN_MENU_SOUND
		death_sfx_player.play()
		
		play_transition(Transition.FADE_OUT)
		yield(screen_anim, "animation_finished")

		var main_vp = get_tree().root
		main_vp.get_child(main_vp.get_child_count() - 1).load_scene("res://prototypes/menus/main_menu/Main_Menu.tscn")

func _retry_or_quit_pressed():
	return GDScriptX.xor(left_hand_trigger_continued_press || right_hand_trigger_continued_press, 
						 left_hand.is_button_pressed(JOY_OPENVR_MENU) || left_hand.is_button_pressed(JOY_OCULUS_MENU) || \
						 right_hand.is_button_pressed(JOY_OPENVR_MENU) || right_hand.is_button_pressed(JOY_OCULUS_MENU))
#	return (left_hand_trigger_continued_press || right_hand_trigger_continued_press || \
#			left_hand.is_button_pressed(JOY_OPENVR_MENU) || left_hand.is_button_pressed(JOY_OCULUS_MENU) || \
#			right_hand.is_button_pressed(JOY_OPENVR_MENU) || right_hand.is_button_pressed(JOY_OCULUS_MENU))

# VR Functions

func initialize_vr():
	if OS.get_name() == "Android":
		VR = ARVRServer.find_interface("OVRMobile")
		
		if VR:
			ovr_mobile_init_config = load("res://addons/godot_ovrmobile/OvrInitConfig.gdns").new()
			ovr_mobile_init_config.set_render_target_size_multiplier(1)
			
			if VR.initialize():
				hdr = false
				keep_3d_linear = false
			
				OS.vsync_enabled = false
				Engine.target_fps = 90
	
	else:
		VR = ARVRServer.find_interface("OpenVR")

		if VR and VR.initialize():
			OS.vsync_enabled = false
			Engine.target_fps = 90

func switch_materials(mat = null):
	match mat:
		MISS_MATERIAL, DEATH_MATERIAL:
			bf_model.get_node("Boyfriend Armature/Skeleton/Boyfriend").material_override = mat
			left_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend").material_override = mat
			right_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend").material_override = mat
			
			bf_model.get_node("Boyfriend Armature/Skeleton/Boyfriend Cell Shade").visible = !(mat == DEATH_MATERIAL)
			left_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend Cell Shade").visible = !(mat == DEATH_MATERIAL)
			right_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend Cell Shade").visible = !(mat == DEATH_MATERIAL)
			
			right_hand_model.get_node("Boyfriend Armature/Skeleton/Microphone").visible = !(mat == DEATH_MATERIAL)
		_:
			bf_model.get_node("Boyfriend Armature/Skeleton/Boyfriend").material_override = null
			left_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend").material_override = null
			right_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend").material_override = null
			
			bf_model.get_node("Boyfriend Armature/Skeleton/Boyfriend Cell Shade").show()
			left_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend Cell Shade").show()
			right_hand_model.get_node("Boyfriend Armature/Skeleton/Boyfriend Cell Shade").show()
			
			right_hand_model.get_node("Boyfriend Armature/Skeleton/Microphone").show()

func set_player_height(reset):
	if reset:
		arvr_origin.world_scale = 1
#		arvr_origin.world_scale = 1 / ARVRServer.get_hmd_transform().origin.y
		var new_height = 1 / ARVRServer.get_hmd_transform().origin.y
		
		var new_height_str = str(new_height)
		if len(new_height_str) > 5:
			new_height_str = new_height_str.substr(0, 5)
			new_height = float(new_height_str)
		arvr_origin.world_scale = new_height
		
		Settings.set_setting("player", "in_game_height", arvr_origin.world_scale)
		Settings.save_settings()
	else:
		arvr_origin.world_scale = Settings.get_setting("player", "in_game_height")

func is_correct_height():
	return camera.global_transform.origin.y >= 0.95 && \
		   camera.global_transform.origin.y <= 1.05

# ASSUMPTION: analog_axis is either JOY_VR_ANALOG_TRIGGER or JOY_VR_ANALOG_GRIP
func update_analog_press(is_right_hand, analog_axis):
	var hand_name = "right" if is_right_hand else "left"
	var button_name = "trigger" if analog_axis == JOY_VR_ANALOG_TRIGGER else "grip"
	var anim_suffix = "_Mic" if is_right_hand else ""
	var pressed = get(hand_name + "_hand").get_joystick_axis(analog_axis) > 0.6
	
#	if pressed && !get(hand_name + "_hand_" + button_name + "_just_pressed"):
#		set(hand_name + "_hand_" + button_name + "_just_pressed", true)
#		set(hand_name + "_hand_" + button_name + "_just_pressed_time", JUST_PRESSED_TIME)
	
	var previously_pressed = get(hand_name + "_hand_" + button_name + "_continued_press")
	set(hand_name + "_hand_" + button_name + "_continued_press", pressed)
	
	if pressed:
		if !get(hand_name + "_hand_" + button_name + "_just_pressed") && !previously_pressed:
			set(hand_name + "_hand_" + button_name + "_just_pressed", true)
#			set(hand_name + "_hand_" + button_name + "_just_pressed_time", JUST_PRESSED_TIME)
		
		var updated_just_pressed = get(hand_name + "_hand_" + button_name + "_just_pressed")
		
		if updated_just_pressed:
			get(hand_name + "_hand_model").get_node("AnimationPlayer").play("Grip" + anim_suffix)
		
		if get_tree().paused && can_pause && updated_just_pressed:
#			if analog_axis == GRIP_IDX:
#				can_pause = false
#				pause_menu.hide()
#				Conductor.stop_song()
#				play_transition(Transition.FADE_OUT)
#				yield(screen_anim, "animation_finished")
#
#				set_pause(false)
#				yield(get_tree(), "idle_frame")
#
#				var main_vp = get_tree().root
#				main_vp.get_child(main_vp.get_child_count() - 1).load_scene("res://prototypes/menus/main_menu/Main_Menu.tscn")
#			else:
			set_pause(false)
	
	if !get(hand_name + "_hand_trigger_just_pressed") && !get(hand_name + "_hand_trigger_just_pressed") && \
	   !get(hand_name + "_hand_grip_just_pressed") && !get(hand_name + "_hand_grip_just_pressed"):
		get(hand_name + "_hand_model").get_node("AnimationPlayer").play("Point" + anim_suffix)

func on_controller_button_detected(button, is_right_hand, pressed):
#	var hand_name = "right" if is_right_hand else "left"
#	var anim_suffix = "_Mic" if is_right_hand else ""
	
#	if button == JOY_VR_TRIGGER:
#		if pressed && !get(hand_name + "_hand_just_pressed"):
#			set(hand_name + "_hand_just_pressed", true)
#			set(hand_name + "_hand_just_pressed_time", JUST_PRESSED_TIME)
#
#		set(hand_name + "_hand_continued_press", pressed)
#
#		if pressed:
#			if get_tree().paused:
#				set_pause(false)
#
#			get(hand_name + "_hand_model").get_node("AnimationPlayer").play("Grip" + anim_suffix)
#		else:
#			get(hand_name + "_hand_model").get_node("AnimationPlayer").play("Point" + anim_suffix)
	
	if (button == JOY_OPENVR_MENU || button == JOY_OCULUS_MENU) && can_pause && !pressed:
		if !get_tree().paused:
			set_pause(true)
		else:
			can_pause = false
			pause_menu.hide()
			Conductor.stop_song()
			play_transition(Transition.FADE_OUT)
			yield(screen_anim, "animation_finished")

			set_pause(false)
			yield(get_tree(), "idle_frame")

			var main_vp = get_tree().root
			main_vp.get_child(main_vp.get_child_count() - 1).load_scene("res://prototypes/menus/main_menu/Main_Menu.tscn")

func set_rumble(for_right_hand, intensity):
	if for_right_hand:
		if intensity > right_hand.rumble:
			right_hand.rumble = intensity
	else:
		if intensity > left_hand.rumble:
			left_hand.rumble = intensity

func set_pause(pausing):
	if pausing:
		if can_pause && (!pause_timer || pause_timer.time_left <= 0):
			pause_music.play()
		else:
			return
	else:
		pause_music.stop()
		pause_timer = get_tree().create_timer(0.5)
	
	pause_menu.visible = pausing
	get_tree().paused = pausing
