extends SceneTree

var failures: int = 0
var range_changes: int = 0


func _initialize() -> void:
	debug_collisions_hint = true
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _settle_physics() -> void:
	for frame in range(4):
		await physics_frame


func _run() -> void:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	scene.position = Vector2(250, 250)
	root.add_child(scene)
	var ally: BattleUnit = scene.get_node("AllyUnit")
	var near: BattleUnit = scene.get_node("HostileNear")
	var far: BattleUnit = scene.get_node("HostileFar")
	var finder := ally.target_finder
	finder.targets_in_range_changed.connect(func(): range_changes += 1)
	await _settle_physics()
	_check(ally.detect_range.collision_layer == 4 and ally.detect_range.collision_mask == 2, "Player detection filters")
	_check(near.detect_range.collision_layer == 8 and near.detect_range.collision_mask == 1, "Enemy detection filters")
	_check(ally.detect_range.col_shape.shape.radius == 100.0, "Player range scaling")
	_check(near.detect_range.col_shape.shape.radius == 50.0, "Enemy range scaling")
	_check(ally.detect_range.col_shape.shape != near.detect_range.col_shape.shape, "Units need independent range shapes")
	_check(finder.targets_in_range == [near] and finder.has_target_in_range(), "Only nearby enemy enters player range")
	_check(range_changes == 1, "Entering range emits one notification")
	_check(not near.target_finder.has_target_in_range(), "Enemy shorter range excludes ally")
	finder.find_target()
	_check(finder.target == near, "Closest hostile is selected")
	near.target_finder.find_target()
	_check(near.target_finder.target == ally, "Enemy selects ally")
	var decoy := Node2D.new()
	scene.add_child(decoy)
	decoy.add_to_group("hostiles")
	finder.find_target()
	_check(finder.target == near, "Non-unit group members are ignored")
	decoy.queue_free()
	var unrelated := Area2D.new()
	ally.detect_range.area_entered.emit(unrelated)
	ally.detect_range.area_exited.emit(unrelated)
	_check(finder.targets_in_range == [near] and range_changes == 1, "Non-unit area signals are ignored")
	unrelated.free()
	near.position = Vector2(300, 0)
	await _settle_physics()
	_check(not finder.has_target_in_range() and range_changes == 2, "Exit clears range and emits notification")
	finder.find_target()
	_check(finder.target == far, "Nearest target updates even outside attack range")
	near.remove_from_group("hostiles")
	far.remove_from_group("hostiles")
	finder.find_target()
	_check(finder.target == null, "Empty opposing group clears old target")
	near.add_to_group("hostiles")
	far.add_to_group("hostiles")
	var updated := UnitStats.new()
	updated.team = UnitStats.Team.PLAYER
	updated.attack_range = 4
	ally.stats = updated
	_check(ally.detect_range.stats == ally.stats and ally.stats != updated, "Duplicated stats propagate to detector")
	_check(ally.detect_range.col_shape.shape.radius == 200.0, "Reassigned stats resize detection")
	await _settle_physics()
	_check(finder.targets_in_range == [far], "Expanded range detects farther enemy")
	ally.stats = load("res://data/units/bjorn.tres")
	near.position = Vector2(75, 0)
	await _settle_physics()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_check(image.save_png("res://targeting-verification.png") == OK, "Save runtime verification image")
	if failures == 0:
		print("PASS: targeting, collision filters, range signals, invalid candidates, and stat reassignment")
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
