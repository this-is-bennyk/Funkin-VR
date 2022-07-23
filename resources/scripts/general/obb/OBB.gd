extends Spatial

export(bool) var disabled = false

onready var x_axis = $X
onready var y_axis = $Y
onready var z_axis = $Z

func has_point(pt: Vector3) -> bool:
	if disabled:
		return false
	
	var diff_pt2origin = pt - global_transform.origin
	var world_x_axis = x_axis.global_transform.origin - global_transform.origin
	var world_y_axis = y_axis.global_transform.origin - global_transform.origin
	var world_z_axis = z_axis.global_transform.origin - global_transform.origin
	
	var within_x = diff_pt2origin.project(world_x_axis).length_squared() <= world_x_axis.length_squared()
	var within_y = diff_pt2origin.project(world_y_axis).length_squared() <= world_y_axis.length_squared()
	var within_z = diff_pt2origin.project(world_z_axis).length_squared() <= world_z_axis.length_squared()
	
	return within_x && within_y && within_z
