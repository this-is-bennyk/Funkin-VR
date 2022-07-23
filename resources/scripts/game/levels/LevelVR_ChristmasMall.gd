extends "res://packages/fnfvr/resources/scripts/game/levels/LevelVR.gd"

onready var parents = $Parents_XMas
onready var santa = $Santa

func do_level_specific_prep():
	match song_data.name:
		"Eggnog":
			get_performer("opponent").idle_frequency = 2
			santa.idle_frequency = 2

func switch_singing_parent():
	parents.current_suffix = 1 if parents.current_suffix == 0 else 0
