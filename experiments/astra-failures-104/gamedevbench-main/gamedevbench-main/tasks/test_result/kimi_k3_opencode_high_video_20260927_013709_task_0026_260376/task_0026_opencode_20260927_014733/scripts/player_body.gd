extends Node3D

@export var camera_node: Node3D
@export var camera_actual: Node3D

@export_group("Camera Shake")
## Noise resource used to drive the idle camera shake.
@export var camera_shake_noise: FastNoiseLite
## How fast the noise is panned through (higher = faster wobble).
@export var noise_panning_speed: float = 30.0
## The maximum power an impulse can have.
@export var max_power: float = 0.15
## How fast the camera blends toward its target shake position.
@export var blend_speed: float = 7.0
## How fast the shake position returns to the origin.
@export var return_strength: float = 5.0
## How strongly the noise offsets the camera.
@export var noise_strength: float = 0.2

@export_group("Falling / Landing")
## Downward velocity must exceed this before a landing impulse triggers.
@export var falling_bias: float = 1.0
## Divisor that scales how strongly falling speed translates into shake.
@export var falling_strength_falloff: float = 2.0
## Maximum strength of a landing impulse.
@export var falling_max_strength: float = 1.0

@export_group("Jumping")
## Strength of the impulse applied when jumping.
@export var jumping_strength: float = 0.2

var camera_shake_position: Vector3 = Vector3.ZERO
var time_since_started := 0.0

func _ready() -> void:
	if camera_actual:
		camera_actual.position = Vector3.ZERO

func _physics_process(delta: float) -> void:
	time_since_started += delta * noise_panning_speed

	var noise_offset := Vector3.ZERO
	if camera_shake_noise:
		noise_offset = Vector3(
			camera_shake_noise.get_noise_2d(time_since_started, 0.0),
			camera_shake_noise.get_noise_2d(0.0, time_since_started),
			camera_shake_noise.get_noise_2d(time_since_started, time_since_started)
		) * noise_strength

	if camera_actual:
		camera_actual.position = camera_actual.position.lerp(
			camera_shake_position + noise_offset, blend_speed * delta)

	# Decay the accumulated shake back toward the origin.
	camera_shake_position = camera_shake_position.lerp(Vector3.ZERO, return_strength * delta)

func impulse_camera(direction: Vector3, power: float) -> void:
	power = minf(power, max_power)
	camera_shake_position += direction.normalized() * power

func impulse_camera_with_recoil(direction: Vector3, power: float) -> void:
	impulse_camera(direction, power)
	# Upward kick so recoils feel punchy.
	impulse_camera(Vector3.UP, power * 0.5)

func apply_landing_impulse(previous_y_velocity: float) -> void:
	if previous_y_velocity < -falling_bias:
		var strength := clampf(
			(-previous_y_velocity - falling_bias) / falling_strength_falloff,
			0.0, falling_max_strength)
		impulse_camera(Vector3.DOWN, strength)
