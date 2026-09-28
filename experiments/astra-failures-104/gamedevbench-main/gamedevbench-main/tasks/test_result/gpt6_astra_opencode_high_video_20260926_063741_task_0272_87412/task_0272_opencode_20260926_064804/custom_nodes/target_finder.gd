class_name TargetFinder
extends Node

signal targets_in_range_changed

@export var actor: BattleUnit

var target: BattleUnit
var targets_in_range: Array[BattleUnit] = []


func _ready() -> void:
	# Children enter ready before the actor's onready variables are assigned.
	var detect_range := actor.get_node("DetectRange") as DetectRange
	detect_range.area_entered.connect(_on_area_entered)
	detect_range.area_exited.connect(_on_area_exited)


func find_target() -> void:
	target = null
	var closest_distance := INF
	var opposing_group: String = UnitStats.TARGET[actor.stats.team]
	for candidate in get_tree().get_nodes_in_group(opposing_group):
		if not candidate is BattleUnit:
			continue

		var distance := actor.global_position.distance_squared_to(candidate.global_position)
		if distance < closest_distance:
			closest_distance = distance
			target = candidate


func has_target_in_range() -> bool:
	return not targets_in_range.is_empty()


func _on_area_entered(area: Area2D) -> void:
	if area is BattleUnit and not targets_in_range.has(area):
		targets_in_range.append(area)
		targets_in_range_changed.emit()


func _on_area_exited(area: Area2D) -> void:
	if area is BattleUnit and targets_in_range.has(area):
		targets_in_range.erase(area)
		targets_in_range_changed.emit()
