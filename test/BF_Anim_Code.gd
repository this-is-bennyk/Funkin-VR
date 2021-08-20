# FOR REFERENCE IN LATER UPDATES
#
#extends ARVROrigin
#
##const MODEL_SCALE = 0.011
#const MODEL_SCALE = 0.01
#const JUST_PRESSED_TIME = 1 / 60.0
#
## Player Model Stuff
#
#onready var camera = $ARVRCamera
#onready var screen_flash = $ARVRCamera/Screen_Flash
#onready var screen_wipe = $ARVRCamera/Screen_Wipe
#onready var screen_anim: AnimationPlayer = $ARVRCamera/Screen_Anim
#
#onready var left_hand = $Left_Hand
#onready var left_hand_model = $Left_Hand/Hand_Model
##onready var right_axis_l = $Left_Hand/Right_Axis
##onready var up_axis_l = $Left_Hand/Up_Axis
##onready var forward_axis_l = $Left_Hand/Forward_Axis
#
#onready var right_hand = $Right_Hand
#onready var right_hand_model = $Right_Hand/Hand_Model
##onready var right_axis_r = $Right_Hand/Right_Axis
##onready var up_axis_r = $Right_Hand/Up_Axis
##onready var forward_axis_r = $Right_Hand/Forward_Axis
#
#onready var bf_model = $Boyfriend
#onready var bf_skeleton = $"Boyfriend/Boyfriend Armature/Skeleton"
#
##onready var bf_hand_l_ik = $"Boyfriend/Boyfriend Armature/Skeleton/Shoulder_To_Hand_L"
##onready var bf_hand_r_ik = $"Boyfriend/Boyfriend Armature/Skeleton/Shoulder_To_Hand_R"
#
## Controller Stuff
#
#var left_hand_just_pressed = false
#var left_hand_just_pressed_time = 0
#var left_hand_continued_press = false
#
#var right_hand_just_pressed = false
#var right_hand_just_pressed_time = 0
#var right_hand_continued_press = false
#
## VR Interface Stuff
#
#var VR: ARVRInterface
#
#var DEBUG = false
#
## TODO: Quest ports
##	var VR = ARVRServer.find_interface("OVRMobile")
#
#func _ready():
#	if DEBUG:
#		visible = false
#		set_process(false)
#		return
#
#	VR = ARVRServer.find_interface("OpenVR")
#
#	if VR and VR.initialize():
#		var vp = get_viewport()
#
#		vp.arvr = true
#		vp.keep_3d_linear = true
#
#		OS.vsync_enabled = false
#		Engine.target_fps = 90
#
#	else:
#		assert(false)
#
#	screen_flash.rect_size = ARVRServer.primary_interface.get_render_targetsize()
#	screen_wipe.rect_size = ARVRServer.primary_interface.get_render_targetsize()
#
##	bf_hand_l_ik.start()
##	bf_hand_r_ik.start()
#
#	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("root"), Transform(Basis(), Vector3(-0.3 / bf_model.scale.x, 0, 0)))
#	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("head"), Transform(Vector3(), Vector3(), Vector3(), Vector3()))
#	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("shoulder_l"), Transform(Vector3(), Vector3(), Vector3(), Vector3()))
#	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("shoulder_r"), Transform(Vector3(), Vector3(), Vector3(), Vector3()))
##	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("hand_l"), bf_skeleton.get_bone_pose(bf_skeleton.find_bone("hand_l")).scaled(Vector3(0.5, 0.5, 0.5)))
##	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("hand_r"), bf_skeleton.get_bone_pose(bf_skeleton.find_bone("hand_r")).scaled(Vector3(0.5, 0.5, 0.5)))
#
#	left_hand_model.scale /= 2
#	left_hand_model.get_node("AnimationPlayer").play("Point")
#
#	right_hand_model.scale /= 2
#	right_hand_model.get_node("AnimationPlayer").play("Point_Mic")
#
#	yield(get_tree().create_timer(0.5), "timeout")
#	reset_player_height()
#
#	set_process(true)
#
#func _process(delta):
#	# Update button presses
#
#	if left_hand_just_pressed_time > 0:
#		print("left pressed")
#		left_hand_just_pressed_time -= delta
#	else:
#		left_hand_just_pressed = false
#		left_hand_just_pressed_time = 0
#
#	if right_hand_just_pressed_time > 0:
#		print("right pressed")
#		right_hand_just_pressed_time -= delta
#	else:
#		right_hand_just_pressed = false
#		right_hand_just_pressed_time = 0
#
#	# Update model rotation + translation
#
#	bf_model.rotation.y = camera.rotation.y + PI
##	bf_skeleton.set_bone_pose(bf_skeleton.find_bone("head"), Transform(Quat(Vector3(0, 0, camera.rotation.x))))
#
#	bf_model.translation.x = camera.translation.x
#	bf_model.translation.z = camera.translation.z
#
##	# Move left hand IK
##
##	var left_controller_xform = ARVRServer.get_tracker(0).get_transform(false).orthonormalized()
##	var new_left_hand_target = left_controller_xform.rotated(dir_to_relative_axis(left_hand, up_axis_l), PI / 2).rotated(dir_to_relative_axis(left_hand, forward_axis_l), PI)
##	new_left_hand_target.origin = left_hand.transform.origin
##
##	bf_hand_l_ik.target = new_left_hand_target
##
##	# Move right hand IK
##
##	var right_controller_xform = ARVRServer.get_tracker(1).get_transform(false).orthonormalized()
##	var new_right_hand_target = right_controller_xform.rotated(dir_to_relative_axis(right_hand, up_axis_r), -PI / 2).rotated(dir_to_relative_axis(right_hand, forward_axis_r), -PI)
##	new_right_hand_target.origin = right_hand.transform.origin
##
##	bf_hand_r_ik.target = new_right_hand_target
#
#func dir_to_relative_axis(t, axis):
#	return t.global_transform.origin.direction_to(axis.global_transform.origin)
#
## VR Functions
#
#func reset_player_height():
#	world_scale = 1
#	world_scale = 1 / ARVRServer.get_hmd_transform().origin.y
#
#func _on_controller_button_detected(button, is_right_hand, pressed):
#	var hand_name = "right" if is_right_hand else "left"
#	var anim_suffix = "_Mic" if is_right_hand else ""
#
#	if button == JOY_VR_TRIGGER:
##		if pressed && !get(hand_name + "_hand_just_pressed") && !get(hand_name + "_hand_continued_press"):
#		if pressed && !get(hand_name + "_hand_just_pressed"):
#			set(hand_name + "_hand_just_pressed", true)
#			set(hand_name + "_hand_just_pressed_time", JUST_PRESSED_TIME)
##		elif !pressed:
##			set(hand_name + "_hand_just_pressed", false)
#
#		set(hand_name + "_hand_continued_press", pressed)
#
#		if pressed:
#			get(hand_name + "_hand_model").get_node("AnimationPlayer").play("Grip" + anim_suffix)
#		else:
#			get(hand_name + "_hand_model").get_node("AnimationPlayer").play("Point" + anim_suffix)
