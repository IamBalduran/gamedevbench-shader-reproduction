extends Area2D

const DEFAULT_SPEED = 150

var _speed = DEFAULT_SPEED
var direction = Vector2.LEFT

@onready var _initial_pos = position

func _process(delta):
	_speed += delta * 2
	position += _speed * delta * direction

func reset(rightPointed: bool):
	if rightPointed:
		direction = Vector2(1, randf_range(-0.9, 0.9))
	else:
		direction = Vector2(-1, randf_range(-0.9, 0.9))
	position = _initial_pos
	_speed = DEFAULT_SPEED
