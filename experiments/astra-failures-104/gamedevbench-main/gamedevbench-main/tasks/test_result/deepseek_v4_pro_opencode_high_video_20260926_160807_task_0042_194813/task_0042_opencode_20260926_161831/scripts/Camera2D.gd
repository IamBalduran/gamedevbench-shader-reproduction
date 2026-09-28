extends Camera2D

const SPRING = 900
const DAMP = 18
const MULTIPLIER = 20

var displacement: float
var velocity: float = 0.0

func _ready():
	displacement = position.x

func shake(right_pointed: bool):
	if right_pointed:
		velocity = -MULTIPLIER
	else:
		velocity = MULTIPLIER

func _physics_process(delta):
	velocity += (-SPRING * displacement - DAMP * velocity) * delta
	displacement += velocity * delta
	position.x = displacement