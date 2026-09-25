extends Node3D

@onready var view_model_container: Node3D = $ViewModel

func _ready() -> void:
	pass

func apply_clip_and_fov_shader_to_view_model(node3d: Node3D, fov_or_negative_for_unchanged := -1.0) -> void:
	pass
