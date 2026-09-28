class_name TargetFinder
extends Node

signal targets_in_range_changed

@export var actor: BattleUnit

var target: BattleUnit
var targets_in_range: Array[BattleUnit]


func _ready() -> void:
	actor.detect_range.area_entered.connect(_on_detect_range_area_entered)
	actor.detect_range.area_exited.connect(_on_detect_range_area_exited)


func find_target() -> void:
	target = null
	var closest_distance := INF

	for node in get_tree().get_nodes_in_group(UnitStats.TARGET[actor.stats.team]):
		if not node is BattleUnit:
			continue

		var distance := actor.global_position.distance_squared_to(node.global_position)
		if distance < closest_distance:
			closest_distance = distance
			target = node


func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()


func _on_detect_range_area_entered(area: Area2D) -> void:
	if area is BattleUnit:
		targets_in_range.append(area)
		targets_in_range_changed.emit()


func _on_detect_range_area_exited(area: Area2D) -> void:
	if area is BattleUnit:
		targets_in_range.erase(area)
		targets_in_range_changed.emit()
