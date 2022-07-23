extends "res://scripts/menus/options/OptionsUI.gd"

# Remarks: hack hack hack making this an AnimatedSprite w/
# no frames is a HACK

export(NodePath) var main_menu_path

onready var main_menu = get_node(main_menu_path)

func exit():
	main_menu.change_state(2, 2)
	
	menus[0].cur_option = 0
	menus[0].set_option_alphas()
