extends SceneTree

func _init():
	var scene: PackedScene = load("res://scenes/audio_demo.tscn")
	var inst = scene.instantiate()
	print(inst.get_script())
	quit()
