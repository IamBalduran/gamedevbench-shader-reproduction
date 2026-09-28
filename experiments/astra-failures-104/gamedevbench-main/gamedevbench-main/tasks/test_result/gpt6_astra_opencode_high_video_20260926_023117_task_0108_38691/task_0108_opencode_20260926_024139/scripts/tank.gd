extends CharacterBody2D
class_name Tank

const SPEED = 64.0
const TURN_SPEED = 2.0

var direction := Vector2.RIGHT
@onready var left_track_particles: GPUParticles2D = $LeftTrackParticles
@onready var right_track_particles: GPUParticles2D = $RightTrackParticles

var current_particle_gradient: GradientTexture1D = null

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
	_update_track_particles()


func _update_track_particles() -> void:
	var particle_gradient := World.get_gradient_at(position)
	if particle_gradient != current_particle_gradient:
		current_particle_gradient = particle_gradient
		left_track_particles.process_material.color_ramp = particle_gradient
		right_track_particles.process_material.color_ramp = particle_gradient

	var moving := velocity != Vector2.ZERO
	left_track_particles.emitting = moving
	right_track_particles.emitting = moving
