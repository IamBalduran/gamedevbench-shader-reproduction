class_name DetectRange
extends Area2D

@export var col_shape: CollisionShape2D
@export var base_range_size: float
@export var stats: UnitStats: set = _set_stats


func _set_stats(value: UnitStats) -> void:
	stats = value
	
	if not stats or not col_shape:
		return
	
	collision_layer = 4 * (stats.team + 1)
	collision_mask = 2 - stats.team
	var circle := CircleShape2D.new()
	circle.radius = base_range_size * stats.attack_range
	col_shape.shape = circle
