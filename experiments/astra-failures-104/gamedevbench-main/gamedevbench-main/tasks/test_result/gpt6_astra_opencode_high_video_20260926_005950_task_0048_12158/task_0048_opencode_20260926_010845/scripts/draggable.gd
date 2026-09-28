extends Area2D

signal dropped(draggable: Area2D, overlapping_areas: Array[Area2D])

const DRAG_SPEED := 20.0
const ANIMATION_DURATION := 0.25

var initial_position: Vector2
var initial_scale: Vector2
var dragging := false

var _destructing := false
var _scale_tween: Tween


func _ready() -> void:
	initial_position = position
	initial_scale = scale
	play_spawn_animation()


func play_spawn_animation() -> void:
	if _destructing:
		return
	if _scale_tween:
		_scale_tween.kill()
	scale = Vector2.ZERO
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", initial_scale, ANIMATION_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if dragging:
		global_position = global_position.lerp(
			get_global_mouse_position(), 1.0 - exp(-DRAG_SPEED * delta)
		)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click") and not _destructing:
		dragging = true
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# Handle release globally, even when the mouse has left the collision shape.
	if not dragging or not event.is_action_released("click"):
		return

	dragging = false
	var overlapping_areas := get_overlapping_areas()
	var inside_drop_target := false
	for area in overlapping_areas:
		if area.name == &"DropTarget":
			inside_drop_target = true
			break

	dropped.emit(self, overlapping_areas)
	if not inside_drop_target:
		self_destruct()


func self_destruct() -> void:
	if _destructing:
		return
	_destructing = true
	dragging = false
	input_pickable = false
	set_process_input(false)
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", Vector2.ZERO, ANIMATION_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_scale_tween.tween_callback(queue_free)
