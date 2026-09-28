class_name DetectRange
extends Area2D

@export var col_shape: CollisionShape2D
@export var base_range_size: float
@export var stats: UnitStats: set = _set_stats


func _set_stats(value: UnitStats) -> void:
	stats = value

	if not stats:
		return

	collision_layer = 4 * (stats.team + 1)
	collision_mask = 2 - stats.team

	var circle_shape := CircleShape2D.new()
	circle_shape.radius = base_range_size * stats.attack_range
	col_shape.shape = circle_shape
