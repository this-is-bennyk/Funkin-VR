tool
extends ImmediateGeometry

var circle_points = []

func _ready():
	for i in range(360):
		circle_points.append(i / 360.0 * 2 * PI)
	
	begin(Mesh.PRIMITIVE_TRIANGLES)
	set_color(Color.white)

	for point in circle_points:
		add_vertex(Vector3(cos(point), 0, sin(point)))
	
	for point in circle_points:
		add_vertex(Vector3(cos(point), -1, sin(point)))
	
	end()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
