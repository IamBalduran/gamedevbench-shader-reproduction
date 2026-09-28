extends Node3D

@export var camera_node: Node3D
@export var camera_actual: Node3D
@export var camera_shake_noise: FastNoiseLite

@export var noise_panning_speed := 30.0
@export var max_power := 0.15
@export var blend_speed := 7.0
@export var return_strength := 5.0
@export var noise_strength := 0.2
@export var falling_bias := 1.0
@export var falling_strength_falloff := 2.0
@export var falling_max_strength := 1.0
@export var jumping_strength := 0.2

var camera_shake_position: Vector3 = Vector3.ZERO
var time_since_started := 0.0


func _ready() -> void:
	if camera_actual:
		camera_actual.position = Vector3.ZERO


func _physics_process(delta: float) -> void:
	time_since_started += delta

	var noise_offset := Vector3.ZERO
	if camera_shake_noise:
		var pan := time_since_started * noise_panning_speed
		noise_offset.x = camera_shake_noise.get_noise_2d(pan, 0.0)
		noise_offset.y = camera_shake_noise.get_noise_2d(pan, 100.0)
		noise_offset.z = camera_shake_noise.get_noise_2d(pan, 200.0)

	var target := camera_shake_position + noise_offset * noise_strength

	if camera_actual:
		camera_actual.position = camera_actual.position.lerp(target, blend_speed * delta)

	camera_shake_position = camera_shake_position.lerp(Vector3.ZERO, return_strength * delta)


func impulse_camera(direction: Vector3, power: float) -> void:
	var impulse := direction * power
	camera_shake_position += impulse
	camera_shake_position = camera_shake_position.limit_length(max_power)


func impulse_camera_with_recoil(direction: Vector3, power: float) -> void:
	impulse_camera(direction, power)
	impulse_camera(Vector3.UP, power * jumping_strength)


func apply_landing_impulse(previous_y_velocity: float) -> void:
	if previous_y_velocity < -falling_bias:
		var excess: float = absf(previous_y_velocity) - falling_bias
		var strength := clampf(excess / falling_strength_falloff, 0.0, falling_max_strength)
		impulse_camera(Vector3.DOWN, strength)