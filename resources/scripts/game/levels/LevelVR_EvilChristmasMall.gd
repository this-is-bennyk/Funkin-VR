extends "res://packages/fnfvr/resources/scripts/game/levels/LevelVR.gd"

onready var world_anim = $WorldEnvironment/AnimationPlayer

func do_pre_level_story_event():
	get_performer("metronome").play_anim("Dance_Right")
	get_performer("opponent").play_anim("Idle")
	
	world_anim.play("Scary")
	world_anim.connect("animation_finished", self, "_on_intro_finished", [], CONNECT_DEFERRED | CONNECT_ONESHOT)

func _on_intro_finished(_anim_name):
	start_level_part_2()
