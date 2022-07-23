extends Area

const NORMALIZED_HALF = 0.5

export(NodePath) var viewport_path
export(NodePath) var origin_path
export(NodePath) var x_axis_path
export(NodePath) var y_axis_path

onready var main = get_tree().root.get_node("Main")
onready var viewport = get_node(viewport_path)

onready var origin = get_node(origin_path)
onready var x_axis = get_node(x_axis_path)
onready var y_axis = get_node(y_axis_path)

var cur_point = Vector2()

var pointed_at = false
var already_pressed = false
var active_hand = ARVRPositionalTracker.TRACKER_RIGHT_HAND

func _ready():
	main.player.left_controller.connect("button_pressed", self, "_on_button_press", [ARVRPositionalTracker.TRACKER_LEFT_HAND])
	main.player.left_controller.connect("button_release", self, "_on_button_release", [ARVRPositionalTracker.TRACKER_LEFT_HAND])
	
	main.player.right_controller.connect("button_pressed", self, "_on_button_press", [ARVRPositionalTracker.TRACKER_RIGHT_HAND])
	main.player.right_controller.connect("button_release", self, "_on_button_release", [ARVRPositionalTracker.TRACKER_RIGHT_HAND])
	
	connect("area_entered", self, "_on_other_area_passed_through", [true])
	connect("area_exited", self, "_on_other_area_passed_through", [false])

func _process(delta):
	if !pointed_at:
		return
	update_virtual_mouse_pos()
	_send_mouse_event()

func update_virtual_mouse_pos():
	var ray_cast: RayCast = main.player.right_index_ray_cast if active_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND else main.player.left_index_ray_cast
	
	ray_cast.force_raycast_update()
	
	var intersection_vec: Vector3 = ray_cast.get_collision_point() - global_transform.origin
	var x_vec: Vector3 = x_axis.global_transform.origin - origin.global_transform.origin
	var y_vec: Vector3 = y_axis.global_transform.origin - origin.global_transform.origin
	
	var x_dist = inverse_lerp(0, x_vec.length_squared(), intersection_vec.project(x_vec).length_squared()) * NORMALIZED_HALF
	var y_dist = inverse_lerp(0, y_vec.length_squared(), intersection_vec.project(y_vec).length_squared()) * NORMALIZED_HALF
	
	var x_sign = sign(intersection_vec.dot(x_vec))
	# Negative since we're going to screen space coordinates
	var y_sign = -sign(intersection_vec.dot(y_vec))
	
	var result_x = NORMALIZED_HALF + x_dist * x_sign
	var result_y = NORMALIZED_HALF + y_dist * y_sign
	
	cur_point = Vector2(result_x, result_y)

func _on_other_area_passed_through(area: Area, entered: bool):
	if !(area == main.player.left_index_ray_area || area == main.player.right_index_ray_area):
		return
	
	var cur_hand = ARVRPositionalTracker.TRACKER_RIGHT_HAND if area == main.player.right_index_ray_area else ARVRPositionalTracker.TRACKER_LEFT_HAND
	
	if active_hand != cur_hand:
		return
	
	pointed_at = entered
	
	if entered:
		return
	
	# Send a mouse event so that the current mouse press is released
	already_pressed = false
	_send_mouse_event()

func _on_button_press(button: int, hand: int):
	if button != JOY_VR_TRIGGER || already_pressed:
		return
	
	# Change hands even if we're not pressing anything in the viewport
	active_hand = hand
	
	if !pointed_at:
		return
	
	already_pressed = true
	_send_mouse_event()

func _on_button_release(button: int, hand: int):
	if button != JOY_VR_TRIGGER || active_hand != hand:
		return
	
	if already_pressed:
		already_pressed = false
		_send_mouse_event()
	else:
		already_pressed = false

func _send_mouse_event():
	var event = InputEventMouseButton.new()
	
	event.global_position = viewport.size * cur_point
	event.button_index = BUTTON_LEFT
	event.pressed = already_pressed
	
	viewport.input(event)
