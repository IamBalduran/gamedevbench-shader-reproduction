extends SceneTree

func _init():
	var scene: PackedScene = load("res://scenes/player.tscn")
	print("root before adds: ", get_root(), " child_count=", get_root().get_child_count())
	var a := scene.instantiate()
	var b := scene.instantiate()
	root.add_child(a)
	root.add_child(b)
	print("root child_count after adds: ", root.get_child_count())
	print("a inside tree: ", a.is_inside_tree())
	print("probe: a.material != b.material: ", a.get_node("Sprite2D").material != b.get_node("Sprite2D").material)
	quit()
