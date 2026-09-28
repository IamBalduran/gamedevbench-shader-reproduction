extends SceneTree

func _init():
	var scene: PackedScene = load("res://scenes/player.tscn")
	var a := scene.instantiate()
	var b := scene.instantiate()

	var mat_a0: Material = a.get_node("Sprite2D").material
	var dup := mat_a0.duplicate(true)
	print("test: dup != original:", dup != mat_a0)
	print("test: dup == b.material (shared local res):", dup == b.get_node("Sprite2D").material)
	print("test: dup is scene-local state:", ResourceLoader.get_resource_uid("res://scenes/player.tscn"))
	quit()
