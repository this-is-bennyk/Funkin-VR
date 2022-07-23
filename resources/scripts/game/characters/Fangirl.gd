extends "res://scripts/game/characters/BPMScaledBeatNode.gd"

export(bool) var distressed = false
export(NodePath) var model
export(int) var material_slot = 0
export(SpatialMaterial) var distress_material
export(String) var distress_anim_name = "Distressed"

func on_ready():
	.on_ready()
	
	if !distressed:
		return
	
	get_node(model).set("material/" + str(material_slot), distress_material)
	idle_anim_name = distress_anim_name
