extends Character

onready var jitter = $Jitter

func start():
	idle()
	jitter.play("Jitter")
	set_process(true)

func stop():
	stop_anim_players(false)
	jitter.stop()
	set_process(false)

func on_quarter_hit(quarter):
	if hold_time == 0 && quarter % 2 == 0:
		idle()
