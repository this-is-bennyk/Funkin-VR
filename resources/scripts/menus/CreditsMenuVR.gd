extends "res://scripts/menus/CreditsMenu.gd"

const FNFVR_CREDITS = preload("res://packages/fnfvr/credits.tres")

# Previous _ready will be called
func _ready():
	credits.connect("meta_clicked", self, "_on_link_clicked")

func on_input(event):
	pass

func _create_credits():
	credits.parse_bbcode("[center]")
	
	_parse_credits(BENJINE_CREDITS)
	_parse_credits(FNFVR_CREDITS)
	
	credits.append_bbcode(SEPARATOR)
