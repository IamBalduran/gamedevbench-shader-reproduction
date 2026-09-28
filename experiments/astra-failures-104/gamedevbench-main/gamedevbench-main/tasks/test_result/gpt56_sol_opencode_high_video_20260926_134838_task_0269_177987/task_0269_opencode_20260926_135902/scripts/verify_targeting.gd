extends Node


func _ready() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().physics_frame

	var drone: BattleUnit = main.get_node("DroneUnit")
	var close_intruder: BattleUnit = main.get_node("IntruderClose")
	var distant_intruder: BattleUnit = main.get_node("IntruderDistant")
	var finder := drone.target_finder

	assert(drone.detect_range.collision_layer == 4)
	assert(drone.detect_range.collision_mask == 2)
	assert(drone.detect_range.col_shape.shape.radius == 72.0)
	assert(finder.has_target_in_range())
	finder.find_target()
	assert(finder.target == close_intruder)
	assert(distant_intruder not in finder.targets_in_range)

	print("Targeting verification passed")
	get_tree().quit()
