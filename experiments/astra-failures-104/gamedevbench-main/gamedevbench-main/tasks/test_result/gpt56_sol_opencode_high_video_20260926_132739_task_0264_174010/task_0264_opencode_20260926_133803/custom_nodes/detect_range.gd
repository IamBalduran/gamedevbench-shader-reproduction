class_name DetectRange
extends Area2D

@export var col_shape: CollisionShape2D
@export var base_range_size: float = 32.0
@export var stats: UnitStats: set = _set_stats


func _set_stats(value: UnitStats) -> void:
	stats = value

	if not stats or not col_shape:
		return

	collision_layer = 4 * (stats.team + 1)
	collision_mask = 2 - stats.team
	var range_shape := CircleShape2D.new()
	range_shape.radius = base_range_size * stats.attack_range
	col_shape.shape = range_shape
