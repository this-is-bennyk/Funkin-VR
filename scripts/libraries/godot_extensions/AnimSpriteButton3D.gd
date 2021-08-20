extends "res://scripts/libraries/godot_extensions/Button3D.gd"

onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready():
	animated_sprite.playing = true

func change_state(new_state):
	animated_sprite.play(str(new_state))
	.change_state(new_state)
