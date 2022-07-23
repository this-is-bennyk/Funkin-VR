extends Sprite

func _input(event):
	if event is InputEventMouse:
		position = event.position
		
		if event is InputEventMouseButton:
			if event.pressed:
				scale = Vector2.ONE * 0.75
			else:
				scale = Vector2.ONE
