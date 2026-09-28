extends SceneTree


func _init() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var root := packed.instantiate()
	self.root.add_child(root)

	var cam: Camera3D = root.get_node("Camera3D")
	var bg: Node3D = root.get_node("Background")
	print("Camera pos=", cam.global_position, " fov=", cam.fov)
	print("Child count of Background: ", bg.get_child_count())
	for child in bg.get_children():
		print("  ", child.name, " @ ", child.global_position)
		var r := 0.5
		var pts := [
			child.global_position,
			child.global_position + Vector3(r, 0, 0),
			child.global_position + Vector3(-r, 0, 0),
			child.global_position + Vector3(0, r, 0),
			child.global_position + Vector3(0, -r, 0),
			child.global_position + Vector3(0, 0, r),
			child.global_position + Vector3(0, 0, -r),
		]
		var inside := 0
		for p in pts:
			if cam.is_position_in_frustum(p):
				inside += 1
		print("    frustum points inside: ", inside, "/", pts.size())

	quit()
