extends Area

signal hover(_self)
signal pressed(_self)

enum State {NORMAL, HOVER, PRESSING}

export(AudioStream) var hover_sound
export(AudioStream) var pressed_sound

onready var collision_shape = $CollisionShape
onready var sfx_player = $SFX_Player

var cur_state = State.NORMAL
var ray_overlapping

func _process(delta):
	collision_shape.disabled = !is_visible_in_tree()
	
	if !is_visible_in_tree():
		return
	
	if Player.left_raycast.get_collider() == self:
		ray_overlapping = Player.left_raycast
	elif Player.right_raycast.get_collider() == self:
		ray_overlapping = Player.right_raycast
	else:
		ray_overlapping = null
	
	if !ray_overlapping:
		change_state(State.NORMAL)
		return
	
	match cur_state:
		State.NORMAL:
			if either_hand_pressing():
				change_state(State.PRESSING)
			else:
				change_state(State.HOVER)
				
				if hover_sound:
					sfx_player.stop()
					sfx_player.stream = hover_sound
					sfx_player.play()
				
				emit_signal("hover", self)
		
		State.HOVER:
			if either_hand_pressing():
				change_state(State.PRESSING)
		
		State.PRESSING:
			if either_hand_released():
				change_state(State.HOVER)
				
				if pressed_sound:
					sfx_player.stop()
					sfx_player.stream = pressed_sound
					sfx_player.play()
				
				emit_signal("pressed", self)

func change_state(new_state):
	cur_state = new_state

func either_hand_pressing():
	return (Player.left_hand_continued_press && ray_overlapping == Player.left_raycast) || \
		   (Player.right_hand_continued_press && ray_overlapping == Player.right_raycast)

func either_hand_released():
	return (!Player.left_hand_continued_press && ray_overlapping == Player.left_raycast) || \
		   (!Player.right_hand_continued_press && ray_overlapping == Player.right_raycast)
