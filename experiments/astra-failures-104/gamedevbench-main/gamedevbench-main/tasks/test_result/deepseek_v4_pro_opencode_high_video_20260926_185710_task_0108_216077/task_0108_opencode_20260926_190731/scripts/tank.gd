extends CharacterBody2D
class_name Tank

const SPEED = 64.0
const TURN_SPEED = 2.0

var direction := Vector2.RIGHT

@onready var left_particles: GPUParticles2D = $LeftTrackParticles
@onready var right_particles: GPUParticles2D = $RightTrackParticles

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
	var is_moving := drive_input != 0.0 or turn_input != 0.0
	left_particles.emitting = is_moving
	right_particles.emitting = is_moving
	if is_moving:
		var gradient = World.get_gradient_at(global_position)
		if gradient:
			var left_mat := left_particles.process_material as ParticleProcessMaterial
			var right_mat := right_particles.process_material as ParticleProcessMaterial
			if left_mat:
				left_mat.color_ramp = gradient
			if right_mat:
				right_mat.color_ramp = gradient