extends Node3D

@export var camera_node: Node3D
@export var camera_actual: Node3D

@export_group("Camera Shake")
@export var noise: FastNoiseLite
@export var noise_panning_speed: float = 30.0
@export var max_power: float = 0.15
@export var blend_speed: float = 7.0
@export var return_strength: float = 5.0
@export var noise_strength: float = 0.2

@export_group("Camera Impulses")
@export var falling_bias: float = 1.0
@export var falling_strength_falloff: float = 2.0
@export var falling_max_strength: float = 1.0
@export var jumping_strength: float = 0.2

var camera_shake_position: Vector3 = Vector3.ZERO
var time_since_started := 0.0

func _ready() -> void:
    if camera_actual:
        camera_actual.position = Vector3.ZERO

func _physics_process(delta: float) -> void:
    time_since_started += delta
    var noise_offset := Vector3.ZERO
    if noise:
        var noise_time := time_since_started * noise_panning_speed
        noise_offset = Vector3(
            noise.get_noise_2d(noise_time, 0.0),
            noise.get_noise_2d(noise_time, 100.0),
            noise.get_noise_2d(noise_time, 200.0)
        ) * noise_strength * camera_shake_position.length()

    if camera_actual:
        camera_actual.position = camera_actual.position.lerp(
            camera_shake_position + noise_offset,
            clampf(blend_speed * delta, 0.0, 1.0)
        )
    camera_shake_position = camera_shake_position.lerp(
        Vector3.ZERO, clampf(return_strength * delta, 0.0, 1.0)
    )

func impulse_camera(direction: Vector3, power: float) -> void:
    var impulse := direction.normalized() * clampf(power, 0.0, max_power)
    camera_shake_position = (camera_shake_position + impulse).limit_length(max_power)

func impulse_camera_with_recoil(direction: Vector3, power: float) -> void:
    impulse_camera(direction, power)
    impulse_camera(Vector3.UP, jumping_strength)

func apply_landing_impulse(previous_y_velocity: float) -> void:
    if previous_y_velocity < -falling_bias:
        var power := minf(
            (-previous_y_velocity - falling_bias) / maxf(falling_strength_falloff, 0.001),
            falling_max_strength
        )
        impulse_camera(Vector3.DOWN, power)
