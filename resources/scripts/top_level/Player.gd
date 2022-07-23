extends Spatial

const SHORTEST_HEIGHT = 1.2192 # ~4 ft
const TALLEST_HEIGHT = 2.1336 # ~7 ft
const RESET_HEIGHT_Y = 2

const RESET_HEIGHT_TIME = 2

signal transition_finished(trans_name)
signal height_changed(height)

export(NodePath) var left_index_point_path
export(NodePath) var right_index_point_path

export(NodePath) var left_index_reference_point_path
export(NodePath) var right_index_reference_point_path

export(NodePath) var left_index_direction_point_path
export(NodePath) var right_index_direction_point_path

onready var origin = $FPController
onready var headset_camera = $FPController/ARVRCamera

onready var left_hand = $FPController/LeftHand
onready var right_hand = $FPController/LeftHand

onready var left_hand_quest = $FPController/LeftHandController/LeftHand_Quest
onready var right_hand_quest = $FPController/RightHandController/RightHand_Quest

onready var left_controller = $FPController/LeftHandController
onready var right_controller = $FPController/RightHandController

onready var left_index_point = get_node(left_index_point_path)
onready var right_index_point = get_node(right_index_point_path)

onready var left_index_reference_point = get_node(left_index_reference_point_path)
onready var right_index_reference_point = get_node(right_index_reference_point_path)

onready var left_index_direction_point = get_node(left_index_direction_point_path)
onready var right_index_direction_point = get_node(right_index_direction_point_path)

onready var transition_system = $FPController/ARVRCamera/Overlay_VP/Transition/AnimationPlayer
onready var height_adjustment_progress = $FPController/ARVRCamera/Overlay_VP/Height_Adjuster/Height_Adjustment_Progress

var left_pressed_for_height = false
var right_pressed_for_height = false

var height_adjustment_timer = 0

func _ready():
	if !OS.get_name() == "Android":
		return
	
	# WHAT IS WRONG WITH YOU QUEST 2
	left_hand.hide()
	right_hand.hide()
	
	left_hand_quest.show()
	right_hand_quest.show()
	
	left_index_point = left_index_reference_point
	right_index_point = right_index_reference_point

func play_transition(transition_name):
	transition_system.stop()
	
	if transition_system.is_connected("animation_finished", self, "_on_trans_anim_finished"):
		transition_system.disconnect("animation_finished", self, "_on_trans_anim_finished")
	
	transition_system.play(transition_name)
	transition_system.connect("animation_finished", self, "_on_trans_anim_finished", [], CONNECT_DEFERRED | CONNECT_ONESHOT)

func reset_height():
	var cur_height = clamp(headset_camera.translation.y, SHORTEST_HEIGHT, TALLEST_HEIGHT)
	var cur_scale = 1.0 / cur_height
	
	origin.scale = Vector3(cur_scale, cur_scale, cur_scale)
	
	emit_signal("height_changed", cur_height)

func _process(delta):
	update_height_adjuster(delta)

func _on_trans_anim_finished(trans_name):
	emit_signal("transition_finished", trans_name)

func update_height_adjuster(delta):
	if !(left_controller.translation.y >= RESET_HEIGHT_Y && \
		right_controller.translation.y >= RESET_HEIGHT_Y && \
		left_pressed_for_height && right_pressed_for_height):
		height_adjustment_timer = 0
		height_adjustment_progress.value = 0
		return
	
	height_adjustment_timer += delta
	height_adjustment_progress.value = height_adjustment_timer / RESET_HEIGHT_TIME
	
	if height_adjustment_timer > RESET_HEIGHT_TIME:
		reset_height()
		
		height_adjustment_timer = 0
		height_adjustment_progress.value = 0
		
		left_pressed_for_height = false
		right_pressed_for_height = false

func _on_left_hand_button_pressed(button):
	if button != JOY_VR_TRIGGER:
		return
	left_pressed_for_height = true

func _on_right_hand_button_pressed(button):
	if button != JOY_VR_TRIGGER:
		return
	right_pressed_for_height = true

func _on_left_hand_button_release(button):
	if button != JOY_VR_TRIGGER:
		return
	left_pressed_for_height = false

func _on_right_hand_button_release(button):
	if button != JOY_VR_TRIGGER:
		return
	right_pressed_for_height = false
