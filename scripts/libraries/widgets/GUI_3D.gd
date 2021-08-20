# Based on this script from the Godot Team
# https://github.com/godotengine/godot-demo-projects/blob/3.3-2d4d233/viewport/gui_in_3d/gui_3d.gd

extends Spatial

# Used for checking if the mouse is inside the Area
var is_hand_ray_inside = false
# Used for checking if the mouse was pressed inside the Area
var is_trigger_held = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_fake_mouse_pos2D = Vector2()

onready var node_viewport = $Viewport
onready var node_quad = $Quad
onready var node_area = $Quad/Area

var raycasts = []
var cur_ray = null

func _ready():
	node_area.connect("area_entered", self, "_hand_ray_entered_area")
	node_area.connect("area_exited", self, "_hand_ray_exited_area")

func _process(_delta):
	# NOTE: Remove this function if you don't plan on using billboard settings.
#	if node_quad.get_surface_material(0).params_billboard_mode != 0:
#		rotate_area_to_billboard()
	
	if Player.left_raycast.get_collider() == node_area && Player.right_raycast.get_collider() == node_area:
		if Player.left_hand.get_joystick_axis(JOY_VR_ANALOG_TRIGGER) > 0.6:
			cur_ray = Player.left_raycast
		elif Player.right_hand.get_joystick_axis(JOY_VR_ANALOG_TRIGGER) > 0.6:
			cur_ray = Player.right_raycast
		# otherwise we're using the ray that's already been defined in cur_ray
	
	# Because we already checked to see if both are in the area at the same time,
	# there must be either ONE or ZERO raycasts intersecting with the area.
	elif Player.left_raycast.get_collider() == node_area || Player.right_raycast.get_collider() == node_area:
		cur_ray = Player.left_raycast if Player.left_raycast.get_collider() == node_area else Player.right_raycast
	else:
		cur_ray = null
	
	if cur_ray:
		var fake_mouse_pos3D = node_area.global_transform.affine_inverse() * cur_ray.get_collision_point()
		var fake_mouse_pos2D = Vector2(fake_mouse_pos3D.x, -fake_mouse_pos3D.y)
		
		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: 0 -> quad_size
		fake_mouse_pos2D.x += node_quad.mesh.size.x / 2
		fake_mouse_pos2D.y += node_quad.mesh.size.y / 2
		# Then we need to convert it into the following range: 0 -> 1
		fake_mouse_pos2D.x = fake_mouse_pos2D.x / node_quad.mesh.size.x
		fake_mouse_pos2D.y = fake_mouse_pos2D.y / node_quad.mesh.size.y

		# Finally, we convert the position to the following range: 0 -> viewport.size
		fake_mouse_pos2D.x = fake_mouse_pos2D.x * node_viewport.size.x
		fake_mouse_pos2D.y = fake_mouse_pos2D.y * node_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.
		
		var trigger_pressed = is_trigger_pressed()
		
		if (trigger_pressed && !is_trigger_held) || (!trigger_pressed && is_trigger_held):
			handle_fake_mouse_press(trigger_pressed, fake_mouse_pos2D)
			is_trigger_held = trigger_pressed
		
		handle_fake_mouse_motion(fake_mouse_pos2D)
		
		last_fake_mouse_pos2D = fake_mouse_pos2D

func _hand_ray_entered_area(area):
	if area == Player.left_raycast || area == Player.right_raycast:
		cur_ray = area

func _hand_ray_exited_area(area):
	if area == Player.left_raycast:
		if Player.right_raycast.get_collider() == node_area:
			cur_ray = Player.right_raycast
		else:
			cur_ray = null
	
	elif area == Player.right_raycast:
		if Player.left_raycast.get_collider() == node_area:
			cur_ray = Player.left_raycast
		else:
			cur_ray = null

func handle_fake_mouse_press(trigger_pressed, position):
	print("the mouse: " + str(trigger_pressed) + ", " + str(position))
	
	var trigger_event = InputEventMouseButton.new()
	
	trigger_event.button_index = BUTTON_LEFT
	trigger_event.pressed = trigger_pressed
	
	trigger_event.position = position
	trigger_event.global_position = position
	
	node_viewport.input(trigger_event)

func handle_fake_mouse_motion(position):
	print("the move: " + str(position))
	
	var move_event = InputEventMouseMotion.new()
	
	move_event.position = position
	move_event.global_position = position
	
	move_event.relative = position - last_fake_mouse_pos2D
	
	node_viewport.input(move_event)

func is_trigger_pressed():
	var hand = Player.left_hand if cur_ray == Player.left_raycast else Player.right_hand
	return hand.get_joystick_axis(JOY_VR_ANALOG_TRIGGER) > 0.6

func rotate_area_to_billboard():
	var billboard_mode = node_quad.get_surface_material(0).params_billboard_mode

	# Try to match the area with the material's billboard setting, if enabled
	if billboard_mode > 0:
		# Get the camera
		var camera = get_viewport().get_camera()
		# Look in the same direction as the camera
		var look = camera.to_global(Vector3(0, 0, -100)) - camera.global_transform.origin
		look = node_area.translation + look

		# Y-Billboard: Lock Y rotation, but gives bad results if the camera is tilted.
		if billboard_mode == 2:
			look = Vector3(look.x, 0, look.z)

		node_area.look_at(look, Vector3.UP)

		# Rotate in the Z axis to compensate camera tilt
		node_area.rotate_object_local(Vector3.BACK, camera.rotation.z)
