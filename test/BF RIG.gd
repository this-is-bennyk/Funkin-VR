extends Spatial

func _ready():
	for i in $"Boyfriend/Boyfriend Armature/Skeleton".get_bone_count():
		print($"Boyfriend/Boyfriend Armature/Skeleton".get_bone_name(i) + " parent: " + str($"Boyfriend/Boyfriend Armature/Skeleton".get_bone_parent(i)))
