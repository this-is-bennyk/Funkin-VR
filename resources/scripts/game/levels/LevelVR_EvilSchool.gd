extends "res://packages/fnfvr/resources/scripts/game/levels/LevelVR.gd"

onready var dialogue_menu = $DialogueMenu
onready var dialogue_menu_vp = $DialogueMenu/Viewport
onready var dialogue_menu_obb = $DialogueMenu/Display/OBB

onready var senpai_death_anim = $Senpai_Death

func set_preload_variables():
	countdown_voices = [
		preload("res://assets/sounds/introGo-pixel.ogg"),
		preload("res://assets/sounds/intro1-pixel.ogg"),
		preload("res://assets/sounds/intro2-pixel.ogg"),
		preload("res://assets/sounds/intro3-pixel.ogg")
	]
	
	popup_combo = preload("res://packages/fnfvr/resources/scenes/game/PopupComboVR_Pixel.tscn")
	
	miss_sounds = [
		preload("res://assets/sounds/missnote1.ogg"),
		preload("res://assets/sounds/missnote2.ogg"),
		preload("res://assets/sounds/missnote3.ogg")
	]

func do_pre_level_story_event():
	var new_dialogue = null
	
	get_performer("metronome").idle()
	get_performer("opponent").idle()
	
	match song_data.name:
		"Thorns":
			new_dialogue = Dialogic.start("FNF_Thorns", '', "res://addons/dialogic/Nodes/DialogNode.tscn", false)
	
	if new_dialogue:
		new_dialogue.connect("timeline_end", self, "_after_textbox", [], CONNECT_ONESHOT | CONNECT_DEFERRED)
		dialogue_menu_vp.add_child(new_dialogue)
		dialogue_menu_vp.move_child(new_dialogue, 0)
		
		senpai_death_anim.play("Senpai_Dies")
		
	else:
		start_level_part_2()

func _after_textbox(_tl_name):
	dialogue_menu.hide()
	dialogue_menu_obb.disabled = true
	start_level_part_2()
