extends Node3D

@export_node_path("Light3D") var optional_light_path: NodePath
@export var light_duration := 0.2
var optional_light: Light3D

func _ready() -> void:
	optional_light = get_node_or_null(optional_light_path)
	var max_duration := 0.0
	for child in get_children():
		if child is GPUParticles3D:
			var particles := child as GPUParticles3D
			max_duration = max(max_duration, particles.lifetime)
			particles.one_shot = true
			particles.emitting = true
		elif child is CPUParticles2D:
			var cpu := child as CPUParticles2D
			max_duration = max(max_duration, cpu.lifetime)
			cpu.one_shot = true
			cpu.emitting = true

	if optional_light:
		var tween := create_tween()
		tween.tween_property(optional_light, "light_energy", 0.0, light_duration)
		if optional_light is OmniLight3D:
			tween.tween_property(optional_light, "omni_range", 0.0, light_duration)

	var wait_time := max_duration if max_duration > 0.01 else 0.1
	get_tree().create_timer(wait_time).timeout.connect(queue_free)
