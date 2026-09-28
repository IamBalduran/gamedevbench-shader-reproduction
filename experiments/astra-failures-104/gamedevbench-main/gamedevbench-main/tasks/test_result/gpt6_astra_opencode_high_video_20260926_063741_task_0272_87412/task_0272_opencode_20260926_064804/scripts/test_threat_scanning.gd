extends SceneTree

var failures: Array[String] = []
var range_change_count := 0


func _initialize() -> void:
	debug_collisions_hint = true
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _settle_physics() -> void:
	for frame in range(4):
		await physics_frame
	await process_frame


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node2D
	root.add_child(scene)
	scene.position = Vector2(320, 280)
	var worker := scene.get_node("WorkerMech") as BattleUnit
	var near := scene.get_node("SaboteurNear") as BattleUnit
	var far := scene.get_node("SaboteurFar") as BattleUnit
	var finder := worker.target_finder
	finder.targets_in_range_changed.connect(func(): range_change_count += 1)

	await _settle_physics()
	_check(finder.actor == worker, "TargetFinder must reference its BattleUnit")
	_check(worker.detect_range.stats == worker.stats, "DetectRange must receive the actor stats")
	_check(worker.detect_range.collision_layer == 4, "Player detection layer must be 4")
	_check(worker.detect_range.collision_mask == 2, "Player detection mask must be 2")
	_check(near.detect_range.collision_layer == 8, "Enemy detection layer must be 8")
	_check(near.detect_range.collision_mask == 1, "Enemy detection mask must be 1")
	_check(worker.detect_range.col_shape.shape is CircleShape2D, "Detection shape must be a circle")
	_check(is_equal_approx(worker.detect_range.col_shape.shape.radius, 64.0), "Player radius must scale with attack range")
	_check(is_equal_approx(near.detect_range.col_shape.shape.radius, 32.0), "Enemy radius must scale with attack range")
	_check(near.detect_range.col_shape.shape != far.detect_range.col_shape.shape, "Instances must have independent detection shapes")
	_check(finder.targets_in_range.size() == 1 and finder.targets_in_range.has(near), "Only the near saboteur must initially be in player range")
	_check(range_change_count == 1, "Entering range must emit one change signal")
	_check(finder.has_target_in_range(), "Occupied range must report true")
	_check(not near.target_finder.has_target_in_range(), "Shorter enemy range must initially be empty")

	var decoy := Node2D.new()
	scene.add_child(decoy)
	decoy.add_to_group("saboteurs")
	finder.find_target()
	near.target_finder.find_target()
	_check(finder.target == near, "Closest opposing BattleUnit must be selected, ignoring non-units")
	_check(near.target_finder.target == worker, "Enemy must search the workers group")

	var changes_before := range_change_count
	worker.detect_range.area_entered.emit(near)
	worker.detect_range.area_entered.emit(near.detect_range)
	worker.detect_range.area_exited.emit(near.detect_range)
	_check(finder.targets_in_range.size() == 1, "Duplicate entries and non-BattleUnit areas must be ignored")
	_check(range_change_count == changes_before, "Unchanged range membership must not emit changes")

	near.position = Vector2(250, 0)
	await _settle_physics()
	_check(not finder.has_target_in_range(), "Leaving range must erase the BattleUnit")
	_check(range_change_count == changes_before + 1, "Leaving range must emit one change signal")
	finder.find_target()
	_check(finder.target == far, "Closest target must update even outside detection range")

	far.position = Vector2(20, 0)
	await _settle_physics()
	_check(finder.targets_in_range.size() == 1 and finder.targets_in_range.has(far), "Moving another opponent into range must update membership")
	_check(far.target_finder.targets_in_range.has(worker), "Enemy detection must track nearby workers")
	near.remove_from_group("saboteurs")
	far.remove_from_group("saboteurs")
	finder.find_target()
	_check(finder.target == null, "Searching with no opposing units must clear a stale target")
	near.add_to_group("saboteurs")
	far.add_to_group("saboteurs")
	decoy.queue_free()

	near.position = Vector2(65, 0)
	far.position = Vector2(150, 0)
	await _settle_physics()
	var original_shape := worker.detect_range.col_shape.shape
	var changed_stats := worker.stats.duplicate() as UnitStats
	changed_stats.attack_range = 5
	worker.stats = changed_stats
	await _settle_physics()
	_check(worker.detect_range.col_shape.shape != original_shape, "Assigning stats must replace the detection shape")
	_check(is_equal_approx(worker.detect_range.col_shape.shape.radius, 160.0), "Stats reassignment must resize detection")
	_check(finder.targets_in_range.size() == 2, "Expanded detection must include both opponents")
	_check(is_equal_approx(near.detect_range.col_shape.shape.radius, 32.0), "Resizing one unit must not affect another")

	worker.stats = load("res://data/units/bjorn.tres")
	await _settle_physics()
	finder.find_target()
	_check(finder.targets_in_range.size() == 1 and finder.target == near, "Restoring stats must restore range and nearest target")

	if OS.get_cmdline_user_args().has("--capture"):
		var title := Label.new()
		title.position = Vector2(32, 32)
		title.text = "Threat scanning | Godot 4.4.1\nClosest target: %s | Opponents in range: %d\nWorker radius: 64 px | Saboteur radius: 32 px" % [finder.target.name, finder.targets_in_range.size()]
		root.add_child(title)
		for unit in [worker, near, far]:
			var label := Label.new()
			label.position = unit.global_position + Vector2(-32, 80)
			label.text = unit.name
			root.add_child(label)
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://.godot/threat_scanning.png")
		_check(result == OK, "Collision-debug capture must save successfully")

	if failures.is_empty():
		print("PASS: threat scanning, team masks, nearest targeting, range signals, filtering, and stat reassignment")
	else:
		printerr("FAIL: %d threat-scanning checks" % failures.size())
	quit(0 if failures.is_empty() else 1)
