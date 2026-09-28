extends Camera2D

const SPRING = 900
const DAMP = 18
const MULTIPLIER = 20

@onready var displacement: float = position.x
@onready var _rest_position: float = position.x
var velocity: float = 0.0


func shake(right_pointed: bool):
	velocity = -MULTIPLIER if right_pointed else MULTIPLIER


func _physics_process(delta):
	var force = -SPRING * (displacement - _rest_position) - DAMP * velocity
	velocity += force * delta
	displacement += velocity * delta
	position.x = displacement
