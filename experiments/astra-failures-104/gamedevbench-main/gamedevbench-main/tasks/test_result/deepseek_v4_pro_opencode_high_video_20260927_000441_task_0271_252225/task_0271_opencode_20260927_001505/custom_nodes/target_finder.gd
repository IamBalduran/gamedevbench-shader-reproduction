class_name TargetFinder
extends Node

signal targets_in_range_changed

@export var actor: BattleUnit
var target: BattleUnit
var targets_in_range: Array[BattleUnit] = []

func _ready() -> void:
	if actor and actor.detect_range:
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
	var group_name: String = UnitStats.TARGET[actor.stats.team]
	var units: Array[Node] = actor.get_tree().get_nodes_in_group(group_name)
	target = null
	var closest_dist: float = INF
	for unit: Node in units:
		if unit is BattleUnit and unit != actor:
			var dist: float = actor.global_position.distance_squared_to(unit.global_position)
			if dist < closest_dist:
				closest_dist = dist
				target = unit

func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()