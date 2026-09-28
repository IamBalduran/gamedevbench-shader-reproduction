extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var player: BattleUnit = main.get_node("PlayerUnit")
	var enemy_near: BattleUnit = main.get_node("EnemyUnitNear")
	var failures: Array[String] = []

	_check(player.detect_range.collision_layer == 4, "player range layer", failures)
	_check(player.detect_range.collision_mask == 2, "player range mask", failures)
	_check(player.detect_range.col_shape != null, "player collision shape reference", failures)
	if player.detect_range.col_shape:
		_check(player.detect_range.col_shape.shape is CircleShape2D, "player circle shape", failures)
		_check(player.detect_range.col_shape.shape.radius == 64.0, "player range radius", failures)
	_check(enemy_near.detect_range.collision_layer == 8, "enemy range layer", failures)
	_check(enemy_near.detect_range.collision_mask == 1, "enemy range mask", failures)
	_check(enemy_near.detect_range.col_shape != null, "enemy collision shape reference", failures)
	if enemy_near.detect_range.col_shape:
		_check(enemy_near.detect_range.col_shape.shape.radius == 32.0, "enemy range radius", failures)

	player.target_finder.find_target()
	_check(player.target_finder.target == enemy_near, "closest opposing target", failures)
	_check(player.target_finder.has_target_in_range(), "target detected in range", failures)
	_check(player.target_finder.targets_in_range.has(enemy_near), "near enemy tracked", failures)

	if failures.is_empty():
		print("TARGETING_SMOKE_TEST_OK")
		quit()
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)
