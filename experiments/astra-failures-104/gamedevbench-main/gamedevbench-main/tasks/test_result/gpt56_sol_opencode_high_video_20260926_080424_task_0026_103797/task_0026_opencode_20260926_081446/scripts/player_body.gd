extends Node3D

@export var camera_node: Node3D
@export var camera_actual: Node3D
@export var camera_shake_noise: FastNoiseLite
@export_range(0.0, 100.0, 0.01) var noise_panning_speed: float = 30.0
@export_range(0.0, 10.0, 0.01) var max_power: float = 0.15
@export_range(0.0, 30.0, 0.01) var blend_speed: float = 7.0
@export_range(0.0, 30.0, 0.01) var return_strength: float = 5.0
@export_range(0.0, 10.0, 0.01) var noise_strength: float = 0.2
@export var falling_bias: float = 1.0
@export_range(0.0, 30.0, 0.01) var falling_strength_falloff: float = 2.0
@export_range(0.0, 10.0, 0.01) var falling_max_strength: float = 1.0
@export_range(0.0, 10.0, 0.01) var jumping_strength: float = 0.2

var camera_shake_position: Vector3 = Vector3.ZERO
var time_since_started: float = 0.0

func _ready() -> void:
    if camera_actual:
        camera_actual.position = Vector3.ZERO

func _physics_process(delta: float) -> void:
    time_since_started += delta
    if not camera_actual:
        return

    camera_shake_position = camera_shake_position.move_toward(Vector3.ZERO, return_strength * delta)
    var noise_offset := Vector3.ZERO
    if camera_shake_noise:
        var noise_time := time_since_started * noise_panning_speed
        noise_offset = Vector3(
            camera_shake_noise.get_noise_1d(noise_time),
            camera_shake_noise.get_noise_1d(noise_time + 31.7),
            camera_shake_noise.get_noise_1d(noise_time + 67.3)
        ) * noise_strength * camera_shake_position.length()

    var target_position := camera_shake_position + noise_offset
    camera_actual.position = camera_actual.position.lerp(target_position, clampf(blend_speed * delta, 0.0, 1.0))

func impulse_camera(direction: Vector3, power: float) -> void:
    var impulse := direction.normalized() * minf(absf(power), max_power)
    camera_shake_position = (camera_shake_position + impulse).limit_length(max_power)

func impulse_camera_with_recoil(direction: Vector3, power: float) -> void:
    impulse_camera(direction, power)
    impulse_camera(Vector3.UP, jumping_strength)

func apply_landing_impulse(previous_y_velocity: float) -> void:
    var downward_speed := -previous_y_velocity - falling_bias
    if downward_speed <= 0.0:
        return

    var landing_strength := minf(downward_speed / falling_strength_falloff, falling_max_strength)
    impulse_camera(Vector3.DOWN, landing_strength)
