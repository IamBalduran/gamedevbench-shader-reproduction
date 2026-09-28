extends Node

const REQUIRED_EXPORTS := [
    "camera_shake_noise",
    "camera_shake_noise_panning_speed",
    "camera_shake_max_power",
    "camera_shake_blend_speed",
    "camera_shake_return_strength",
    "camera_shake_noise_strength",
    "camera_shake_falling_bias",
    "camera_shake_falling_strength_falloff",
    "camera_shake_falling_max_strength",
    "camera_shake_jumping_strength",
]

const EXPECTED_DEFAULTS := {
    "camera_shake_noise_panning_speed": 30.0,
    "camera_shake_max_power": 0.15,
    "camera_shake_blend_speed": 7.0,
    "camera_shake_return_strength": 5.0,
    "camera_shake_noise_strength": 0.2,
    "camera_shake_falling_bias": 1.0,
    "camera_shake_falling_strength_falloff": 2.0,
    "camera_shake_falling_max_strength": 1.0,
    "camera_shake_jumping_strength": 0.2,
}

var _failed := false

func _ready() -> void:
    run_validation()

func fail(reason: String) -> void:
    if _failed:
        return
    _failed = true
    print("VALIDATION_FAILED: %s" % reason)
    get_tree().quit(1)

func run_validation() -> void:
    var scene: PackedScene = load("res://scenes/player_body.tscn")
    var player_body = scene.instantiate()
    add_child(player_body)
    await get_tree().process_frame

    _check_camera_hierarchy(player_body)
    if _failed:
        return
    _check_exports(player_body)
    if _failed:
        return
    _check_defaults(player_body)
    if _failed:
        return
    _check_noise_assignment(player_body)
    if _failed:
        return
    _check_impulse_behaviour(player_body)
    if _failed:
        return
    _check_landing_impulse(player_body)
    if _failed:
        return
    print("VALIDATION_PASSED: Camera shake rig matches tutorial expectations")
    get_tree().quit()

func _check_camera_hierarchy(player_body) -> void:
    var camera_node = player_body.get_node_or_null("CameraNode")
    if camera_node == null:
        fail("CameraNode missing under PlayerBody")
        return
    var camera_actual = camera_node.get_node_or_null("CameraActual")
    if camera_actual == null:
        fail("CameraActual missing under CameraNode")
        return
    var camera_3d = camera_actual.get_node_or_null("Camera3D")
    if camera_3d == null:
        fail("Camera3D child missing under CameraActual")
        return

func _check_exports(player_body) -> void:
    var property_map := {}
    for info in player_body.get_property_list():
        property_map[info.name] = info
    for property_name in REQUIRED_EXPORTS:
        if not property_map.has(property_name):
            fail("Export '%s' missing on PlayerBody" % property_name)
            return
        var usage: int = int(property_map[property_name].usage)
        if (usage & PROPERTY_USAGE_EDITOR) == 0:
            fail("Export '%s' must be exposed to the editor" % property_name)
            return

func _check_defaults(player_body) -> void:
    for property_name in EXPECTED_DEFAULTS.keys():
        var expected_value: float = EXPECTED_DEFAULTS[property_name]
        var actual_value = player_body.get(property_name)
        if not is_equal_approx(float(actual_value), expected_value):
            fail("Default for %s should be %s" % [property_name, expected_value])
            return

func _check_noise_assignment(player_body) -> void:
    var noise = player_body.get("camera_shake_noise")
    if noise == null or not (noise is FastNoiseLite):
        fail("camera_shake_noise must be a FastNoiseLite resource")
        return

func _check_impulse_behaviour(player_body) -> void:
    var camera_actual = player_body.camera_actual
    if camera_actual == null:
        fail("camera_actual export must be assigned")
        return
    var initial_time := float(player_body.get("time_since_started"))
    player_body.impulse_camera(Vector3.UP, player_body.camera_shake_max_power * 5.0)
    if player_body.camera_shake_position.length() > player_body.camera_shake_max_power + 0.001:
        fail("impulse_camera must clamp camera_shake_position to camera_shake_max_power")
        return
    player_body._physics_process(0.1)
    if camera_actual.position.length() <= 0.0:
        fail("CameraActual should move away from origin after impulse")
        return
    for i in range(60):
        player_body._physics_process(0.1)
    if camera_actual.position.length() > 0.01:
        fail("CameraActual should blend back to origin")
        return
    if float(player_body.get("time_since_started")) <= initial_time:
        fail("time_since_started must increase each frame")
        return
    var previous_position: Vector3 = player_body.camera_shake_position
    player_body.impulse_camera_with_recoil(Vector3.BACK, 0.05)
    if player_body.camera_shake_position.y <= previous_position.y:
        fail("impulse_camera_with_recoil should add upward kick")
        return

func _check_landing_impulse(player_body) -> void:
    var camera_actual = player_body.camera_actual
    player_body.camera_shake_position = Vector3.ZERO
    if camera_actual:
        camera_actual.position = Vector3.ZERO
    player_body.apply_landing_impulse(-3.0)
    player_body._physics_process(0.05)
    if camera_actual and camera_actual.position.y >= 0.0:
        fail("apply_landing_impulse should add downward offset when landing")
        return
