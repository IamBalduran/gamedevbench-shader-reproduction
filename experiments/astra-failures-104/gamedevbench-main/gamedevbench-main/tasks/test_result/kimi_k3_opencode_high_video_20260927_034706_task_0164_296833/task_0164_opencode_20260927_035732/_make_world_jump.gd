@tool
extends EditorScript

func _run() -> void:
	attach()

func attach() -> void:
	var packed : PackedScene = load("res://world.tscn")
	var scene := packed.instantiate()
	var driver := Node.new()
	driver.name = "JumpDriver"
	driver.set_script(load("res://_debug_driver.gd"))
	scene.add_child(driver)
	driver.owner = scene
	var out := PackedScene.new()
	out.pack(scene)
	ResourceSaver.save(out, "res://_world_jump.tscn")
	print("saved")
