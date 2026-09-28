class_name TargetFinder
extends Node

@export var actor: BattleUnit

var target: BattleUnit
var targets_in_range: Array[BattleUnit] = []

signal targets_in_range_changed


func _ready() -> void:
	if not actor:
		return

	actor.detect_range.area_entered.connect(_on_area_entered)
	actor.detect_range.area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area is BattleUnit:
		targets_in_range.append(area)
		targets_in_range_changed.emit()


func _on_area_exited(area: Area2D) -> void:
	if area is BattleUnit:
		targets_in_range.erase(area)
		targets_in_range_changed.emit()


func find_target() -> void:
	target = null
	var group_name = UnitStats.TARGET.get(actor.stats.team, "")
	if group_name.is_empty():
		return

	var candidates = get_tree().get_nodes_in_group(group_name)
	var closest_dist := INF
	var closest_unit: BattleUnit = null

	for candidate in candidates:
		if candidate is BattleUnit and candidate != actor:
			var dist = actor.global_position.distance_squared_to(candidate.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_unit = candidate

	target = closest_unit


func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()