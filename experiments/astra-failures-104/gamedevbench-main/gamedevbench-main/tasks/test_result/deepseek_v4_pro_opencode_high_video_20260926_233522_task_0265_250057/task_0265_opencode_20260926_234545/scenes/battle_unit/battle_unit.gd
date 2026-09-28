class_name BattleUnit
extends Area2D

@export var stats: UnitStats: set = _set_stats

@onready var detect_range: DetectRange = $DetectRange
@onready var target_finder: TargetFinder = $TargetFinder


func _ready() -> void:
	if stats:
		_set_stats(stats)


func _set_stats(value: UnitStats) -> void:
	stats = value

	if not stats or not is_node_ready():
		return

	stats = value.duplicate()
	collision_layer = stats.team + 1
	detect_range.stats = stats
