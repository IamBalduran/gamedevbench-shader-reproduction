class_name TargetFinder
extends Node

signal targets_in_range_changed

@export var actor: BattleUnit

var target: BattleUnit
var targets_in_range: Array[BattleUnit] = []


func _ready() -> void:
	if not actor:
		return

	var detect_range: DetectRange = actor.get_node_or_null("DetectRange")
	if detect_range:
		detect_range.area_entered.connect(_on_area_entered)
		detect_range.area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area is BattleUnit:
		targets_in_range.append(area)
		targets_in_range_changed.emit()


func _on_area_exited(area: Area2D) -> void:
	if area is BattleUnit:
		targets_in_range.erase(area)
		targets_in_range_changed.emit()


func find_target() -> void:
	if not actor or not actor.stats:
		return

	var group_name: String = UnitStats.TARGET[actor.stats.team]
	var candidates: Array = get_tree().get_nodes_in_group(group_name)

	var best: BattleUnit = null
	var best_dist_sq: float = INF

	for candidate in candidates:
		if candidate is BattleUnit and candidate != actor:
			var dist_sq = actor.global_position.distance_squared_to(candidate.global_position)
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best = candidate

	target = best


func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()