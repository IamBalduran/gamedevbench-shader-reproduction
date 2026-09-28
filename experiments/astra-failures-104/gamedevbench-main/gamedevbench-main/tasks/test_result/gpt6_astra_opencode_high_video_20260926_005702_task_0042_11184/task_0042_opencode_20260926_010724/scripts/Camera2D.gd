extends Camera2D

var displacement: float = 0.0
var velocity: float = 0.0

const SPRING: float = 900.0
const DAMP: float = 18.0
const MULTIPLIER: float = 20.0

func _ready():
	# Preserve the playfield center while position.x tracks spring displacement.
	offset.x += position.x
	position.x = displacement

func shake(right_pointed: bool):
	displacement = -MULTIPLIER if right_pointed else MULTIPLIER
	velocity = 0.0

func _physics_process(delta: float):
	var force = -SPRING * displacement - DAMP * velocity
	velocity += force * delta
	displacement += velocity * delta
	position.x = displacement
