extends AsyncState

func do_yielding_event(args: Dictionary = {}):
	var lvl = args.lvl
	
	lvl.train_cooldown.start(Conductor.get_seconds_per_beat() * (9 + randi() % 4))
	
	lvl.train_passing = true
	lvl.train_passing_noise.play()
	
	lvl.train_event_timer.start(4.7)
	
	var result = yield(lvl.train_event_timer, "timeout")
	
	if !canceling:
		lvl.train_anim.play("Train_Pass")
		
		lvl.metronome.dancing = false
		lvl.metronome.get_node("AnimationPlayer").play("W3_Hair_Blow")
		
		lvl.train_event_timer.start(1.8)
		
		result = yield(lvl.train_event_timer, "timeout")
		
		if !canceling:
			lvl.train_passing = false
			lvl.metronome.get_node("AnimationPlayer").play("W3_Hair_Land")
			
			lvl.train_event_timer.start(7 / 24.0)
			
			result = yield(lvl.train_event_timer, "timeout")
			
			if !canceling:
				lvl.metronome.dancing = true
				lvl.metronome.danced_right = true
	
	free()
