extends Spatial

signal loaded(assets)

onready var main = get_parent()

var thread: Thread = Thread.new()

const PLAYER = preload("res://packages/fnfvr/resources/scripts/top_level/Player.gd")

func load_objects(object_paths: Array):
	show()
	
	main.player.play_transition("Basic_Fade_In")
	yield(main.player, "transition_finished")
	
	thread.start(self, "_load_objs_on_thread", object_paths)

# In theory, we don't need access to the assets until they
# are completely loaded sooooooo no mutex?
func _load_objs_on_thread(object_paths):
	print("Loading in VR")
	
	var assets = {}
	for path in object_paths:
		# Loading 3D assets takes an extreme amount of time
		# with the RIL. This is the only way to reasonably load
		# the levels
		assets[path] = load(path)
		print("Loaded: ", path)
	
	print("Done loading in VR")
	call_deferred("_on_loading_finished")
	return assets

func _on_loading_finished():
	var assets = thread.wait_to_finish()
	
	main.player.play_transition("Basic_Fade_Out")
	yield(main.player, "transition_finished")
	
	hide()
	emit_signal("loaded", assets)
