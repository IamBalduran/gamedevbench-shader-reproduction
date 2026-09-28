extends Node

var signal_count := 0


func _ready() -> void:
	await run_validation()


func assert_or_fail(condition: bool, reason: String) -> bool:
	if not condition:
		print("VALIDATION_FAILED: %s" % reason)
		get_tree().quit(1)
		return false
	return true


func wait_physics_frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func run_validation() -> void:
	var main := get_node_or_null("Main")
	if not assert_or_fail(main is Node2D, "scenes/test.tscn must instance scenes/main.tscn as Main"):
		return
	
	if not assert_or_fail(ResourceLoader.exists("res://custom_nodes/detect_range.gd"), "Create res://custom_nodes/detect_range.gd"):
		return
	if not assert_or_fail(ResourceLoader.exists("res://custom_nodes/target_finder.gd"), "Create res://custom_nodes/target_finder.gd"):
		return
	
	var unit_stats_script := load("res://data/units/unit_stats.gd") as GDScript
	var constants := unit_stats_script.get_script_constant_map()
	if not assert_or_fail(constants.has("TARGET"), "res://data/units/unit_stats.gd must define TARGET"):
		return
	if not assert_or_fail(constants["TARGET"][0] == "intruders", "UnitStats.TARGET must map Team.PLAYER to intruders"):
		return
	if not assert_or_fail(constants["TARGET"][1] == "guards", "UnitStats.TARGET must map Team.ENEMY to guards"):
		return
	
	var player = main.get_node_or_null("GuardUnit")
	var enemy_near = main.get_node_or_null("IntruderNear")
	var enemy_far = main.get_node_or_null("IntruderFar")
	if not assert_or_fail(player is Area2D, "Main must contain GuardUnit as an Area2D"):
		return
	if not assert_or_fail(enemy_near is Area2D and enemy_far is Area2D, "Main must contain IntruderNear and IntruderFar as Area2D nodes"):
		return
	
	var detect_range = player.get_node_or_null("DetectRange")
	if not assert_or_fail(detect_range is Area2D, "GuardUnit must have a DetectRange Area2D child"):
		return
	if not assert_or_fail(detect_range.get("base_range_size") == 24.0, "DetectRange.base_range_size must be 24.0"):
		return
	if not assert_or_fail(detect_range.collision_layer == 4, "Player DetectRange collision_layer must be 4 * (team + 1)"):
		return
	if not assert_or_fail(detect_range.collision_mask == 2, "Player DetectRange collision_mask must be 2 - team"):
		return
	
	var detect_shape = detect_range.get_node_or_null("CollisionShape2D")
	if not assert_or_fail(detect_shape is CollisionShape2D, "DetectRange must contain a CollisionShape2D child"):
		return
	if not assert_or_fail(detect_shape.shape is CircleShape2D, "DetectRange must replace its collision shape with a CircleShape2D"):
		return
	if not assert_or_fail(is_equal_approx(detect_shape.shape.radius, 96.0), "Player DetectRange radius must equal base_range_size * attack_range"):
		return
	
	var target_finder = player.get_node_or_null("TargetFinder")
	if not assert_or_fail(target_finder is Node, "GuardUnit must have a TargetFinder child"):
		return
	if not assert_or_fail(target_finder.has_method("find_target"), "TargetFinder must implement find_target()"):
		return
	if not assert_or_fail(target_finder.has_method("has_target_in_range"), "TargetFinder must implement has_target_in_range()"):
		return
	if not assert_or_fail(player.get("detect_range") == detect_range, "battle_unit.gd must expose DetectRange as detect_range"):
		return
	if not assert_or_fail(player.get("target_finder") == target_finder, "battle_unit.gd must expose TargetFinder as target_finder"):
		return
	
	target_finder.targets_in_range_changed.connect(_on_targets_in_range_changed)
	await wait_physics_frames(2)
	
	var targets_in_range = target_finder.get("targets_in_range")
	if not assert_or_fail(targets_in_range is Array, "TargetFinder must store targets_in_range as an array"):
		return
	if not assert_or_fail(target_finder.has_target_in_range(), "TargetFinder.has_target_in_range() must return true when an enemy is inside DetectRange"):
		return
	if not assert_or_fail(targets_in_range.size() == 1 and targets_in_range[0] == enemy_near, "Only IntruderNear should start inside GuardUnit DetectRange"):
		return
	if not assert_or_fail(signal_count >= 1, "TargetFinder must emit targets_in_range_changed when an enemy enters DetectRange"):
		return
	
	target_finder.find_target()
	if not assert_or_fail(target_finder.get("target") == enemy_near, "find_target() must pick the closest enemy unit"):
		return
	
	enemy_far.global_position = Vector2(30, 0)
	await wait_physics_frames(2)
	target_finder.find_target()
	if not assert_or_fail(target_finder.get("target") == enemy_far, "find_target() must update target when a closer enemy appears"):
		return
	
	enemy_near.global_position = Vector2(360, 0)
	enemy_far.global_position = Vector2(360, 0)
	await wait_physics_frames(2)
	if not assert_or_fail(not target_finder.has_target_in_range(), "has_target_in_range() must return false when no enemies remain in range"):
		return
	if not assert_or_fail(target_finder.get("targets_in_range").is_empty(), "targets_in_range must remove enemies when they exit DetectRange"):
		return
	if not assert_or_fail(signal_count >= 3, "TargetFinder must emit targets_in_range_changed on both enter and exit updates"):
		return
	
	print("VALIDATION_PASSED: DetectRange and TargetFinder choose and track nearby enemy units")
	get_tree().quit()


func _on_targets_in_range_changed() -> void:
	signal_count += 1
