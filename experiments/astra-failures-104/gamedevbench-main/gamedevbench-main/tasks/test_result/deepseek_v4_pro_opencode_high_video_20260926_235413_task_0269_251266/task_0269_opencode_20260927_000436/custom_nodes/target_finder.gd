class_name TargetFinder
extends Node

signal targets_in_range_changed

@export var actor: BattleUnit

var target: BattleUnit
var targets_in_range: Array[BattleUnit] = []


func _ready() -> void:
	if not actor:
		return
	if actor.detect_range.area_entered.is_connected(_on_area_entered):
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
	if not actor or not actor.stats:
		return
	var group_name: String = UnitStats.TARGET.get(actor.stats.team, "")
	if group_name.is_empty():
		return
	var group_nodes: Array[Node] = get_tree().get_nodes_in_group(group_name)
	var closest: BattleUnit = null
	var closest_dist_sq: float = INF
	for node in group_nodes:
		if node is BattleUnit and node != actor:
			var dist_sq: float = actor.global_position.distance_squared_to(node.global_position)
			if dist_sq < closest_dist_sq:
				closest_dist_sq = dist_sq
				closest = node
	target = closest


func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()