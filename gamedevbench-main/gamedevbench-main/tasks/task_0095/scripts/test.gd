extends Node

func _ready() -> void:
    run_validation()

func run_validation() -> void:
    var main_node := get_node_or_null("Main")
    if main_node == null:
        _fail("Main node not found")
        return

    var canvas_layer := main_node.get_node_or_null("CanvasLayer")
    if canvas_layer == null:
        _fail("CanvasLayer node not found under Main")
        return

    var mesh_instance := canvas_layer.get_node_or_null("MeshInstance2D")
    if mesh_instance == null:
        _fail("MeshInstance2D node not found under CanvasLayer")
        return

    if mesh_instance.material == null or not (mesh_instance.material is ShaderMaterial):
        _fail("MeshInstance2D must have a ShaderMaterial")
        return

    var shader_material: ShaderMaterial = mesh_instance.material
    if shader_material.shader == null:
        _fail("ShaderMaterial must reference a shader")
        return

    var shader := shader_material.shader
    if shader.resource_path != "res://screen_effect/screen_effect.gdshader":
        _fail("Shader must be res://screen_effect/screen_effect.gdshader")
        return

    var shader_code := shader.code
    var required_snippets := [
        "shader_type canvas_item",
        "render_mode unshaded, skip_vertex_transform",
        "const float curvature = 7.0",
        "const float vignette_multiplier = 2.0",
        "uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap",
        "SCREEN_UV * 2.0 - 1.0",
        "centered_uv.yx / curvature",
        "step(abs(warped_uv.x), 1.0)",
        "step(abs(warped_uv.y), 1.0)",
        "sin(2.0 * warped_uv.y * 180.0)",
        "pow(abs(centered_uv), vec2(4.0)) / 3.0",
        "textureLod(screen_texture, (warped_uv + 1.0) / 2.0, 0.2)",
        "COLOR = vec4(screen_color, 1.0)"
    ]

    var missing := []
    for snippet in required_snippets:
        if shader_code.find(snippet) == -1:
            missing.append(snippet)

    if missing.size() > 0:
        _fail("Shader code missing required parts: %s" % ", ".join(missing))
        return

    print("VALIDATION_PASSED: Task completed successfully")
    get_tree().quit(0)

func _fail(message: String) -> void:
    print("VALIDATION_FAILED: %s" % message)
    get_tree().quit(1)
