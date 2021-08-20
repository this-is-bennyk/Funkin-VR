extends Spatial

var MAX_DIST_FROM_ZONE_CENTER = 0.15

var zone_left_hand_in = -1
var zone_right_hand_in = -1

func _process(delta):
	for child in get_children():
		var zone = Conductor.Directions.LEFT
		
		match child.name:
			"Down_Zone":
				zone = Conductor.Directions.DOWN
			"Up_Zone":
				zone = Conductor.Directions.UP
			"Right_Zone":
				zone = Conductor.Directions.RIGHT
		
		var dist_to_left_hand = child.global_transform.origin.distance_to(Player.left_hand.global_transform.origin)
		var dist_to_right_hand = child.global_transform.origin.distance_to(Player.right_hand.global_transform.origin)
		
		if dist_to_left_hand <= MAX_DIST_FROM_ZONE_CENTER && zone != zone_right_hand_in:
			zone_left_hand_in = zone
			child.get_node("Arrow").animation = "press"
			child.get_node("Arrow").opacity = 1
		
		elif dist_to_right_hand <= MAX_DIST_FROM_ZONE_CENTER && zone != zone_left_hand_in:
			zone_right_hand_in = zone
			child.get_node("Arrow").animation = "press"
			child.get_node("Arrow").opacity = 1
		
		else:
			child.get_node("Arrow").animation = "default"
			child.get_node("Arrow").opacity = 0.5
