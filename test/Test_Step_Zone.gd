extends Node2D

var note = preload("res://prototypes/game/Note.tscn")
var sus_note = preload("res://prototypes/game/Sustained_Note.tscn")

var left = preload("res://assets/graphics/game/notes/regular/left/Left_Note.tres")
var left_hold_line = preload("res://assets/graphics/game/notes/regular/left/Left_Hold_Piece.tres")
var left_endcap = preload("res://assets/graphics/game/notes/regular/left/Left_Endcap.tres")

var right = preload("res://assets/graphics/game/notes/regular/right/Right_Note.tres")
var right_hold_line = preload("res://assets/graphics/game/notes/regular/right/Right_Hold_Piece.tres")
var right_endcap = preload("res://assets/graphics/game/notes/regular/right/Right_Endcap.tres")

var up = preload("res://assets/graphics/game/notes/regular/up/Up_Note.tres")
var up_hold_line = preload("res://assets/graphics/game/notes/regular/up/Up_Hold_Piece.tres")
var up_endcap = preload("res://assets/graphics/game/notes/regular/up/Up_Endcap.tres")

var down = preload("res://assets/graphics/game/notes/regular/down/Down_Note.tres")
var down_hold_line = preload("res://assets/graphics/game/notes/regular/down/Down_Hold_Piece.tres")
var down_endcap = preload("res://assets/graphics/game/notes/regular/down/Down_Endcap.tres")

var sussy = false

func _process(delta):
	if Input.is_action_just_pressed("ui_left"):
		spawn_note(Conductor.Directions.LEFT, sussy)
	
	if Input.is_action_just_pressed("ui_down"):
		spawn_note(Conductor.Directions.DOWN, sussy)
	
	if Input.is_action_just_pressed("ui_up"):
		spawn_note(Conductor.Directions.UP, sussy)
	
	if Input.is_action_just_pressed("ui_right"):
		spawn_note(Conductor.Directions.RIGHT, sussy)
	
	if Input.is_action_just_pressed("ui_accept"):
		sussy = !sussy
		print("sussy: " + str(sussy))

func spawn_note(dir, sustained):
	var new_note
	
	if sustained:
		new_note = sus_note.instance()
		new_note.sustain_length = 1000
	else:
		new_note = note.instance()
	
	new_note.direction = dir
	
	match dir:
		Conductor.Directions.LEFT:
			new_note.texture = left
			
			if sustained:
				new_note.hold_line_sprite = left_hold_line
				new_note.endcap_sprite = left_endcap
		
		Conductor.Directions.DOWN:
			new_note.texture = down
			
			if sustained:
				new_note.hold_line_sprite = down_hold_line
				new_note.endcap_sprite = down_endcap
		
		Conductor.Directions.UP:
			new_note.texture = up
			
			if sustained:
				new_note.hold_line_sprite = up_hold_line
				new_note.endcap_sprite = up_endcap
		
		Conductor.Directions.RIGHT:
			new_note.texture = right
			
			if sustained:
				new_note.hold_line_sprite = right_hold_line
				new_note.endcap_sprite = right_endcap
	
	new_note.global_position = Vector2(100 * (dir + 1) + 77 * dir, Note.SCROLL_DISTANCE * new_note.song_speed)
	
	$Note_List.add_child(new_note)
