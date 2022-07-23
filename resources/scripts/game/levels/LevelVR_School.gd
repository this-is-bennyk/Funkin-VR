extends "res://packages/fnfvr/resources/scripts/game/levels/LevelVR.gd"

onready var fangirls = $Fangirls
onready var dialogue_menu = $DialogueMenu
onready var dialogue_menu_vp = $DialogueMenu/Viewport
onready var dialogue_menu_obb = $DialogueMenu/Display/OBB
onready var dialogue_menu_anim = $Menu_Anim

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
	
	for fangirl in fangirls.get_children():
		fangirl.idle()
	
	match song_data.name:
		"Senpai":
			new_dialogue = Dialogic.start("FNF_Senpai", '', "res://addons/dialogic/Nodes/DialogNode.tscn", false)
		"Roses":
			new_dialogue = Dialogic.start("FNF_Roses", '', "res://addons/dialogic/Nodes/DialogNode.tscn", false)
			
			_change_to_roses()
	
	if new_dialogue:
		new_dialogue.connect("timeline_end", self, "_after_textbox", [], CONNECT_ONESHOT | CONNECT_DEFERRED)
		dialogue_menu_vp.add_child(new_dialogue)
		dialogue_menu_vp.move_child(new_dialogue, 0)
		
		dialogue_menu_anim.play("Wait_For_Interaction")
	else:
		start_level_part_2()

func _after_textbox(_tl_name):
	dialogue_menu.hide()
	dialogue_menu_obb.disabled = true
	start_level_part_2()

func do_level_specific_prep():
	match song_data.name:
		"Roses":
			_change_to_roses()

func _change_to_roses():
	switch_performer("opponent", "senpai_angry")
	
	for fangirl in fangirls.get_children():
		fangirl.distressed = true
		fangirl.on_ready()
