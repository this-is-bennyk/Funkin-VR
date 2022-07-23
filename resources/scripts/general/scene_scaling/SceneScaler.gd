extends Spatial

onready var main = get_tree().root.get_node("Main")

func _ready():
	_reset_scale()
	main.player.connect("height_changed", self, "_reset_scale")

func _reset_scale(_height = 1.8):
	scale = main.player.origin.scale
