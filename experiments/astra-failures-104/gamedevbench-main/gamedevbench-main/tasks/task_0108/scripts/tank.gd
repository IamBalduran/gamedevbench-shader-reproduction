extends CharacterBody2D
class_name Tank

const SPEED = 64.0
const TURN_SPEED = 2.0

var direction := Vector2.RIGHT

func _physics_process(delta):
	var drive_input := 0.0
	var turn_input := 0.0
	if InputMap.has_action("move_backward") and InputMap.has_action("move_forward"):
		drive_input = Input.get_axis("move_backward", "move_forward")
	if InputMap.has_action("turn_left") and InputMap.has_action("turn_right"):
		turn_input = Input.get_axis("turn_left", "turn_right")
	if turn_input != 0.0:
		direction = direction.rotated(turn_input * (PI / 2.0) * TURN_SPEED * delta)
		rotation = direction.angle()
	if drive_input != 0.0:
		velocity = direction.normalized() * drive_input * SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()
