extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")

var failures: Array[String] = []
var range_changes: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _settle_physics() -> void:
	for frame in range(4):
		await physics_frame
	await process_frame


func _on_range_changed() -> void:
	range_changes += 1


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	var wizard: BattleUnit = main.get_node("WizardUnit")
	var near: BattleUnit = main.get_node("WarlockNear")
	var far: BattleUnit = main.get_node("WarlockFar")
	var finder := wizard.target_finder
	finder.targets_in_range_changed.connect(_on_range_changed)

	_check(UnitStats.TARGET[UnitStats.Team.PLAYER] == "warlocks", "Player target group")
	_check(UnitStats.TARGET[UnitStats.Team.ENEMY] == "wizards", "Enemy target group")
	_check(finder.actor == wizard, "TargetFinder actor reference")
	_check(wizard.detect_range.stats == wizard.stats, "DetectRange receives actor stats")
	_check(wizard.detect_range.col_shape == wizard.detect_range.get_node("CollisionShape2D"), "Collision shape reference")
	_check(wizard.detect_range.col_shape.shape is CircleShape2D, "Circular detection shape")
	_check(is_equal_approx(wizard.detect_range.col_shape.shape.radius, 128.0), "Player radius uses attack range")
	_check(is_equal_approx(near.detect_range.col_shape.shape.radius, 32.0), "Enemy radius uses attack range")
	_check(wizard.collision_layer == 1 and near.collision_layer == 2, "Body collision layers")
	_check(wizard.detect_range.collision_layer == 4 and wizard.detect_range.collision_mask == 2, "Player range layers")
	_check(near.detect_range.collision_layer == 8 and near.detect_range.collision_mask == 1, "Enemy range layers")
	_check(near.stats != far.stats, "Unit stats are independent resources")
	_check(near.detect_range.col_shape.shape != far.detect_range.col_shape.shape, "Range shapes are independent")

	# Use nonzero world coordinates to exercise global-distance targeting.
	main.position = Vector2(240, 180)
	var decoy := Node2D.new()
	main.add_child(decoy)
	decoy.add_to_group("warlocks")
	finder.find_target()
	_check(finder.target == near, "Closest opposing BattleUnit selected; non-units ignored")
	far.target_finder.find_target()
	_check(far.target_finder.target == wizard, "Enemy can target player outside attack range")
	await _settle_physics()
	_check(finder.targets_in_range.size() == 1 and finder.targets_in_range.has(near), "Only nearby enemy enters player range")
	_check(finder.has_target_in_range(), "Player reports occupied range")
	_check(not near.target_finder.has_target_in_range(), "Short enemy range starts empty")
	_check(range_changes == 1, "Enter emits range change")

	var changes_before := range_changes
	var unrelated_area := Area2D.new()
	finder._on_area_entered(unrelated_area)
	finder._on_area_exited(unrelated_area)
	_check(range_changes == changes_before and finder.targets_in_range.size() == 1, "Non-BattleUnit areas ignored")
	unrelated_area.free()

	near.position = Vector2(20, 0)
	await _settle_physics()
	_check(near.target_finder.targets_in_range.has(wizard), "Enemy detection finds only opposing body")
	_check(finder.targets_in_range.size() == 1, "Overlapping detection areas do not become targets")

	near.position = Vector2(400, 0)
	await _settle_physics()
	_check(not finder.has_target_in_range(), "Exit removes target from range")
	_check(range_changes == changes_before + 1, "Exit emits range change")
	finder.find_target()
	_check(finder.target == far, "Target updates when closest enemy changes")

	far.position = Vector2(90, 0)
	await _settle_physics()
	_check(finder.targets_in_range.size() == 1 and finder.targets_in_range.has(far), "New enemy enters range")
	near.position = Vector2(70, 0)
	await _settle_physics()
	_check(finder.targets_in_range.size() == 2, "Multiple enemies tracked")
	near.position = Vector2(400, 0)
	await _settle_physics()
	_check(finder.targets_in_range.size() == 1 and finder.targets_in_range.has(far), "Exit preserves remaining target")

	var updated_stats := UnitStats.new()
	updated_stats.team = UnitStats.Team.PLAYER
	updated_stats.attack_range = 1
	var old_shape := wizard.detect_range.col_shape.shape
	wizard.stats = updated_stats
	await _settle_physics()
	_check(wizard.detect_range.stats == wizard.stats, "Reassigned stats propagate")
	_check(wizard.detect_range.col_shape.shape != old_shape, "Stats assignment replaces range shape")
	_check(is_equal_approx(wizard.detect_range.col_shape.shape.radius, 32.0), "Reassigned range resizes circle")
	_check(not finder.has_target_in_range(), "Shrinking range removes distant enemies")
	finder.find_target()
	_check(finder.target == far, "Find target searches group beyond range")

	near.remove_from_group("warlocks")
	far.remove_from_group("warlocks")
	finder.find_target()
	_check(finder.target == null, "No opposing units clears old target")

	updated_stats.team = UnitStats.Team.ENEMY
	wizard.stats = updated_stats
	_check(wizard.collision_layer == 2, "Team reassignment changes body layer")
	_check(wizard.detect_range.collision_layer == 8 and wizard.detect_range.collision_mask == 1, "Team reassignment updates range filtering")

	var standalone_range := DetectRange.new()
	standalone_range.stats = updated_stats
	standalone_range.col_shape = CollisionShape2D.new()
	standalone_range.add_child(standalone_range.col_shape)
	main.add_child(standalone_range)
	_check(standalone_range.col_shape.shape is CircleShape2D, "Stats assigned before scene readiness create range shape")
	main.free()
	await process_frame
	if failures.is_empty():
		print("PASS: targeting, signals, physics filtering, and stat reassignment")
	else:
		print("FAIL: %d targeting checks" % failures.size())
	quit(0 if failures.is_empty() else 1)
