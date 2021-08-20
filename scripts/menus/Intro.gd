extends Spatial

onready var gf = $Girlfriend

var intro_already_done = false
var logo_bumped_right = true
var freaky_menu = preload("res://assets/music/fnf/freakyMenu.ogg")

func _ready():
	Conductor.connect("quarter_hit", self, "on_quarter_hit")
	Conductor.play_song(freaky_menu, 102)
	gf.start()

func _process(delta):
	if Player.left_hand_trigger_just_pressed || Player.right_hand_trigger_just_pressed:
		if intro_already_done:
			set_process(false)
			transition_to_main_menu()
		else:
			finish_intro_sequence()

func on_quarter_hit(quarter):
	if !intro_already_done:
		match quarter:
			2:
				$FNFVR_Dev_Icons/Presents.show()
			3:
				$FNFVR_Dev_Icons.hide()
			4:
				$FNF_Dev_Msg.show()
			6:
				$FNF_Dev_Msg/Association.show()
				$FNF_Dev_Msg/NG_Logo.show()
			7:
				$FNF_Dev_Msg.hide()
			8:
				$Funny_Quote.show()
			10:
				$Funny_Quote/Quote_VP/Label2.show()
				$Funny_Quote/Quote_VP/Label3.show()
			11:
				$Funny_Quote.hide()
			12:
				$FNFVR_Logo_Popup.show()
				$FNFVR_Logo_Popup/AnimationPlayer.play("Friday")
			13:
				$FNFVR_Logo_Popup/AnimationPlayer.play("Night")
			14:
				$FNFVR_Logo_Popup/AnimationPlayer.play("Funkin")
			15:
				$FNFVR_Logo_Popup/AnimationPlayer.play("VR")
			16:
				finish_intro_sequence()
	
	var anim_name = "0" if logo_bumped_right else "1"
	$Logo/AnimationPlayer.play(anim_name)
	logo_bumped_right = !logo_bumped_right

func finish_intro_sequence():
	Player.play_transition(Player.Transition.FLASH)
	
	$FNFVR_Dev_Icons.hide()
	$FNF_Dev_Msg.hide()
	$Funny_Quote.hide()
	$FNFVR_Logo_Popup.hide()
	
	$Logo.show()
	$Press_Start.show()
	gf.show()
	intro_already_done = true

func transition_to_main_menu():
	print("moving to main menu")
	Conductor.stop_song()
	
	gf.stop()
	gf.play_anim("Wave")
	$Press_Start/AnimationPlayer.play("Confirm")
	
	yield($Press_Start/AnimationPlayer, "animation_finished")
	
	$Press_Start/AnimationPlayer.play("Fade")
	$GF_Tween.interpolate_property(gf, "translation", gf.translation, Vector3(-1.606, -0.78, -0.877), 1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$GF_Tween.interpolate_property(gf, "rotation_degrees:y", gf.rotation_degrees.y, 60.529, 1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	$GF_Tween.start()
	
	yield($GF_Tween, "tween_all_completed")
	
	get_parent().load_scene()
