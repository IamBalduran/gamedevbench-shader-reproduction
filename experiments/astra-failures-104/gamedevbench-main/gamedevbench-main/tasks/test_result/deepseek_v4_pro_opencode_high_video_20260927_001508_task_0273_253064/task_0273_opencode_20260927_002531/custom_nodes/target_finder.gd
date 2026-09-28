class_name TargetFinder
extends Node

signal targets_in_range_changed

@export var actor: BattleUnit
var target: BattleUnit
var targets_in_range: Array[BattleUnit] = []


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
	var group_name := UnitStats.TARGET[actor.stats.team]
	var candidates := get_tree().get_nodes_in_group(group_name)
	var closest_distance := INF
	var closest_target: BattleUnit = null
	for candidate in candidates:
		if candidate is BattleUnit and candidate != actor:
			var dist := actor.global_position.distance_squared_to(candidate.global_position)
			if dist < closest_distance:
				closest_distance = dist
				closest_target = candidate
	target = closest_target


func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()