extends Area2D

signal dropped(draggable: Area2D, overlapping_areas: Array[Area2D])

var initial_position: Vector2
var initial_scale: Vector2
var is_dragging := false


func _ready() -> void:
	initial_position = position
	initial_scale = scale
	play_spawn_animation()


func play_spawn_animation() -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", initial_scale, 0.45)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		is_dragging = true
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if is_dragging and event.is_action_released("click"):
		is_dragging = false
		var overlapping_areas := get_overlapping_areas()
		dropped.emit(self, overlapping_areas)
		if not _is_over_drop_target(overlapping_areas):
			self_destruct()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if is_dragging:
		var follow_weight := minf(1.0, delta * 12.0)
		global_position = global_position.lerp(get_global_mouse_position(), follow_weight)


func _is_over_drop_target(overlapping_areas: Array[Area2D]) -> bool:
	for area in overlapping_areas:
		if area.name == "DropTarget":
			return true
	return false


func self_destruct() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
