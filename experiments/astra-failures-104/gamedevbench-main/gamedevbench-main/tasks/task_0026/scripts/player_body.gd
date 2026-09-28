extends Node3D

@export var camera_node: Node3D
@export var camera_actual: Node3D

var camera_shake_position: Vector3 = Vector3.ZERO
var time_since_started := 0.0

func _ready() -> void:
    if camera_actual:
        camera_actual.position = Vector3.ZERO

func _physics_process(delta: float) -> void:
    pass

func impulse_camera(direction: Vector3, power: float) -> void:
    pass

func impulse_camera_with_recoil(direction: Vector3, power: float) -> void:
    impulse_camera(direction, power)

func apply_landing_impulse(previous_y_velocity: float) -> void:
    pass
