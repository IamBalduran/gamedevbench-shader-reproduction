extends Camera2D

const SPRING: float = 900.0
const DAMP: float = 18.0
const MULTIPLIER: float = 20.0

var displacement: float = 0.0
var velocity: float = 0.0

func shake(right_pointed: bool):
	# Reverse the kick direction depending on who scored.
	if right_pointed:
		displacement = -MULTIPLIER
	else:
		displacement = MULTIPLIER
	velocity = 0.0

func _physics_process(delta: float):
	# Spring-damper physics: acceleration toward rest (0) with damping.
	var force: float = -SPRING * displacement - DAMP * velocity
	velocity += force * delta
	displacement += velocity * delta
	position.x = displacement
