extends "res://scripts/libraries/godot_extensions/Button3D.gd"

onready var anim_player = $AnimationPlayer

func change_state(new_state):
	anim_player.play(str(new_state))
	.change_state(new_state)
