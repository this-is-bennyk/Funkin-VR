extends Spatial

export(bool) var all_children_are_particles = false
export(Array) var particle_children = []

func change_all_particle_emissions(emitting: bool):
	var children = get_children() if all_children_are_particles else particle_children
	
	for child in children:
		child.restart()
