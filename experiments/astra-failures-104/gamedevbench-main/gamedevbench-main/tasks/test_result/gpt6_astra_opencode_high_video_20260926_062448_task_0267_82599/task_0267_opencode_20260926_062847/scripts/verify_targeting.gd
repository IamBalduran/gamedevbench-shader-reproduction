extends SceneTree

var range_changes: int = 0


func _initialize() -> void:
	debug_collisions_hint = true
	_run.call_deferred()


func _run() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	scene.position = Vector2(200, 200)
	root.add_child(scene)
	var player: BattleUnit = scene.get_node("PlayerUnit")
	var near_enemy: BattleUnit = scene.get_node("EnemyUnitNear")
	var far_enemy: BattleUnit = scene.get_node("EnemyUnitFar")
	player.target_finder.targets_in_range_changed.connect(func(): range_changes += 1)
	for frame in range(4):
		await physics_frame

	assert(player.detect_range.collision_layer == 4)
	assert(player.detect_range.collision_mask == 2)
	assert(near_enemy.detect_range.collision_layer == 8)
	assert(near_enemy.detect_range.collision_mask == 1)
	assert(player.detect_range.col_shape.shape is CircleShape2D)
	assert(player.detect_range.col_shape.shape.radius == 64.0)
	assert(player.detect_range.col_shape.shape != near_enemy.detect_range.col_shape.shape)
	assert(player.target_finder.targets_in_range == [near_enemy])
	assert(player.target_finder.has_target_in_range())
	assert(range_changes == 1)
	player.target_finder.find_target()
	assert(player.target_finder.target == near_enemy)
	near_enemy.target_finder.find_target()
	assert(near_enemy.target_finder.target == player)

	var unrelated := Area2D.new()
	root.add_child(unrelated)
	unrelated.add_to_group("enemy_units")
	player.target_finder._on_area_entered(unrelated)
	player.target_finder._on_area_exited(unrelated)
	assert(range_changes == 1)
	assert(player.target_finder.targets_in_range == [near_enemy])
	player.target_finder.find_target()
	assert(player.target_finder.target == near_enemy)

	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.save_png("res://targeting_verification.png") == OK)

	near_enemy.position = Vector2(250, 0)
	for frame in range(4):
		await physics_frame
	assert(not player.target_finder.has_target_in_range())
	assert(range_changes == 2)
	player.target_finder.find_target()
	assert(player.target_finder.target == far_enemy)

	var extended_stats := UnitStats.new()
	extended_stats.team = UnitStats.Team.PLAYER
	extended_stats.attack_range = 5
	player.stats = extended_stats
	assert(player.detect_range.stats == player.stats)
	assert(player.detect_range.col_shape.shape.radius == 160.0)
	for frame in range(4):
		await physics_frame
	assert(player.target_finder.targets_in_range == [far_enemy])
	assert(range_changes == 3)

	near_enemy.remove_from_group("enemy_units")
	far_enemy.remove_from_group("enemy_units")
	player.target_finder.find_target()
	assert(player.target_finder.target == null)
	unrelated.queue_free()
	print("PASS: team masks, range shape isolation/scaling, nearest opponents, entry/exit signals, non-unit filtering, stats updates, and empty opposing groups")
	quit()
