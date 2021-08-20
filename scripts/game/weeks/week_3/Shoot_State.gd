extends AsyncState

func do_yielding_event(args: Dictionary = {}):
	var lvl = args.lvl
	var dodge_dir = args.dodge_dir
	
	lvl.opponent.play_anim("W3_Preparing", Conductor.get_seconds_per_beat() * 2, true, true)
	
	lvl.warning_popup.show()
	
	var arrow_name = "Down"
	match dodge_dir:
		lvl.LTR_STRAFE:
			arrow_name = "Right"
		lvl.RTL_STRAFE:
			arrow_name = "Left"
	
	for child in lvl.warning_popup.get_children():
		if child.name == "Sign" || child.name == "AnimationPlayer":
			continue
		child.visible = arrow_name in child.name
	
	lvl.warning_popup.get_node("AnimationPlayer").play("Warning_Flash")
	
	lvl.preparing_timer.start(Conductor.get_seconds_per_beat() * 2)
	
	var result = yield(lvl.preparing_timer, "timeout")
	
	if !canceling:
		lvl.warning_popup.hide()
		lvl.warning_popup.get_node("AnimationPlayer").stop()
		
		lvl.opponent.play_anim("W3_Shooting", 0, false, true)
		lvl.shooting_noise.play()
		
		result = yield(lvl.get_tree(), "idle_frame")
		
		if !canceling:
			var bf_safe_condition = false
			
			match dodge_dir:
				lvl.SQUAT:
					bf_safe_condition = Player.camera.global_transform.origin.y < 0.9
				lvl.LTR_STRAFE:
					bf_safe_condition = Player.camera.global_transform.origin.x > 0
				lvl.RTL_STRAFE:
					bf_safe_condition = Player.camera.global_transform.origin.x < 0
			
			if !bf_safe_condition:
				lvl.update_health(-1)
	
	free()
