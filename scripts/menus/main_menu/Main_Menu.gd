extends Menu3D

onready var gf = $Girlfriend

var freaky_vr = preload("res://assets/music/fnf/Gettin_Freaky_VR.ogg")

func _ready():
	menu_items = {
		$Story_Mode/Area: "Story_Mode_Menu",
		$Freeplay/Area: "Freeplay_Mode_Menu",
		$Options/Area: "Options_Menu",
		$Credits/Area: "Credits_Menu",
		$Exit/Area: "Exit"
	}
	
	if get_parent().main_menu:
		get_parent().main_menu = null
	
	if Conductor.stream != freaky_vr || !Conductor.playing:
		Conductor.play_song(freaky_vr, 102)
	
	gf.start()
	
	if "Fade_Out" in Player.screen_anim.assigned_animation:
		Player.play_transition(Player.Transition.FADE_IN)

func do_menu_item_action():
	.do_menu_item_action()
	
	set_process(false)
	
	if cur_menu_item.name == "Credits" || cur_menu_item.name == "Freeplay":
		Conductor.stop_song()
		if cur_menu_item.name == "Credits":
			gf.play_anim("Wave")
	
	get_tree().create_timer(0.8).connect("timeout", Player, "play_transition", [Player.Transition.FADE_OUT], CONNECT_ONESHOT)
	yield(cur_menu_item.get_node("AnimationPlayer"), "animation_finished")
	
	var menu_val = menu_items[cur_menu_item.get_node("Area")]
	
	if menu_val == "Exit":
		get_tree().quit()
	else:
		get_parent().load_scene("res://prototypes/menus/main_menu/" + menu_val + ".tscn")
