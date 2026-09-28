extends Node3D

signal on_shot_camera_impulse(direction: Vector3, power: float)

@export var barrel_end: Node3D
@export var barrel_ray_cast: RayCast3D
@export var camera_shake_power: float = 0.3

func fire_weapon() -> void:
    var direction := -barrel_ray_cast.global_basis.z.normalized()
    on_shot_camera_impulse.emit(direction, camera_shake_power)
