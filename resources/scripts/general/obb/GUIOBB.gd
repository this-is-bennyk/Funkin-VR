extends "res://packages/fnfvr/resources/scripts/general/obb/OBB.gd"

const NORMALIZED_HALF = 0.5
const NO_HAND: int = -1

export(NodePath) var viewport_path

onready var main = get_tree().root.get_node("Main")

onready var viewport = get_node(viewport_path)
onready var plane = Plane(x_axis.global_transform.origin, global_transform.origin, y_axis.global_transform.origin)

var cur_point = Vector2()
var prev_point = Vector2()
var active_hand: int = NO_HAND

func _ready():
	main.player.left_controller.connect("button_pressed", self, "_on_button_press", [ARVRPositionalTracker.TRACKER_LEFT_HAND])
	main.player.left_controller.connect("button_release", self, "_on_button_release", [ARVRPositionalTracker.TRACKER_LEFT_HAND])

	main.player.right_controller.connect("button_pressed", self, "_on_button_press", [ARVRPositionalTracker.TRACKER_RIGHT_HAND])
	main.player.right_controller.connect("button_release", self, "_on_button_release", [ARVRPositionalTracker.TRACKER_RIGHT_HAND])

func _process(_delta):
	if disabled:
		return
	
	plane = Plane(x_axis.global_transform.origin, global_transform.origin, y_axis.global_transform.origin)
	prev_point = cur_point
	
	update_mouse_motion(ARVRPositionalTracker.TRACKER_RIGHT_HAND)
	update_mouse_motion(ARVRPositionalTracker.TRACKER_LEFT_HAND)

func update_mouse_motion(hand: int):
	if !(active_hand == NO_HAND || active_hand == hand):
		return
	
	var index_point = main.player.right_index_reference_point.global_transform.origin \
					  if hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND \
					  else main.player.left_index_reference_point.global_transform.origin
	
	var index_dir_point = main.player.right_index_direction_point.global_transform.origin \
						  if hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND \
						  else main.player.left_index_direction_point.global_transform.origin
	
	var index_dir = (index_dir_point - index_point).normalized()
	var pointed_at = is_being_pointed_at(index_point, index_dir)
	
	if pointed_at:
		cur_point = viewport.size * get_menu_intersection(index_point, index_dir)
		active_hand = hand
		
		_send_mouse_motion_event()
	else:
		active_hand = NO_HAND

func update_mouse_button(pressed: bool):
	_send_mouse_button_event(cur_point, pressed)

func is_being_pointed_at(pt: Vector3, dir_vec: Vector3) -> bool:
	var plane_intersection = plane.intersects_ray(pt, dir_vec)
	
	if !plane_intersection:
		return false
	
	var intersection_vec = plane_intersection - global_transform.origin
	var world_x_axis = x_axis.global_transform.origin - global_transform.origin
	var world_y_axis = y_axis.global_transform.origin - global_transform.origin
	
	return intersection_vec.project(world_x_axis).length_squared() < world_x_axis.length_squared() && \
		   intersection_vec.project(world_y_axis).length_squared() < world_y_axis.length_squared()

func get_menu_intersection(pt: Vector3, dir_vec: Vector3) -> Vector2:
	var plane_intersection = plane.intersects_ray(pt, dir_vec)
	
	var intersection_vec = plane_intersection - global_transform.origin
	var world_x_axis = x_axis.global_transform.origin - global_transform.origin
	var world_y_axis = y_axis.global_transform.origin - global_transform.origin
	
	var normal_center_dist_x = inverse_lerp(0, world_x_axis.length(), intersection_vec.project(world_x_axis).length())
	var normal_center_dist_y = inverse_lerp(0, world_y_axis.length(), intersection_vec.project(world_y_axis).length())
	
	var gui_normal_x_sign = sign(world_x_axis.dot(intersection_vec))
	# The sign is flipped due to us converting the coordinates to screen space
	var gui_normal_y_sign = -sign(world_y_axis.dot(intersection_vec))
	
	var gui_normal_x = NORMALIZED_HALF + normal_center_dist_x * gui_normal_x_sign * NORMALIZED_HALF
	var gui_normal_y = NORMALIZED_HALF + normal_center_dist_y * gui_normal_y_sign * NORMALIZED_HALF
	
	return Vector2(gui_normal_x, gui_normal_y)

func _on_button_press(button: int, hand: int):
	if disabled:
		return
	if !(button == JOY_VR_TRIGGER && active_hand == hand):
		return
	update_mouse_button(true)

func _on_button_release(button: int, hand: int):
	if disabled:
		return
	if !(button == JOY_VR_TRIGGER && active_hand == hand):
		return
	update_mouse_button(false)

func _send_mouse_button_event(point: Vector2, pressed: bool):
	var event = InputEventMouseButton.new()
	
	event.position = point
	event.button_index = BUTTON_LEFT
	event.pressed = pressed
	
	print("Pressed: ", event.position, " ", event.pressed)
	
	viewport.input(event)

func _send_mouse_motion_event():
	var event = InputEventMouseMotion.new()
	
	event.position = cur_point
	event.relative = cur_point - prev_point
	event.button_mask = BUTTON_LEFT
	
	viewport.input(event)
