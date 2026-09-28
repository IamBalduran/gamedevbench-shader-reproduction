class_name TargetFinder
extends Node

signal targets_in_range_changed

@export var actor: BattleUnit
var target: BattleUnit
var targets_in_range: Array[BattleUnit] = []


func _ready() -> void:
	if not actor:
		actor = get_parent() as BattleUnit
	if not actor:
		return

	var detect_range: DetectRange = actor.get_node("DetectRange")
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
	target = null
	if not actor or not actor.stats:
		return

	var closest_distance := INF
	for unit in get_tree().get_nodes_in_group(UnitStats.TARGET[actor.stats.team]):
		if unit is BattleUnit:
			var distance := actor.global_position.distance_squared_to(unit.global_position)
			if distance < closest_distance:
				closest_distance = distance
				target = unit


func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()
