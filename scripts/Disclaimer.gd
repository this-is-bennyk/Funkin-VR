extends Spatial

func _process(delta):
	if Player.left_hand_trigger_just_pressed || Player.right_hand_trigger_just_pressed:
		set_process(false)
		
		$Disclaimer_Sprite.hide()
		$Godot_Logo.show()
		
		$AnimationPlayer.play("Godot_Logo_Anim")
		yield($AnimationPlayer, "animation_finished")
		get_parent().load_scene("res://prototypes/menus/Intro.tscn")
