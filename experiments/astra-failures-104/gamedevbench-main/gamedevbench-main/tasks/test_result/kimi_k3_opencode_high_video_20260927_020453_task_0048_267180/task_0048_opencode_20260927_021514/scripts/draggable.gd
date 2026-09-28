extends Area2D

## Emitted when the draggable is released. [param overlapping_areas] contains
## every Area2D currently overlapped by this draggable.
signal dropped(draggable, overlapping_areas)

const DRAG_LERP_SPEED := 12.0
const TWEEN_DURATION := 0.35

var initial_position: Vector2
var initial_scale: Vector2
var dragging := false

var _click_pressed := false

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape


func _ready() -> void:
	initial_position = position
	initial_scale = scale
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	play_spawn_animation()


func _process(delta: float) -> void:
	if dragging:
		position = position.lerp(get_global_mouse_position(), DRAG_LERP_SPEED * delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		if dragging:
			_click_pressed = true
	elif event.is_action_released("click"):
		_handle_release()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		_click_pressed = true
		dragging = true
	elif event.is_action_released("click"):
		_handle_release()


func _handle_release() -> void:
	if not _click_pressed:
		return
	_click_pressed = false
	if dragging:
		_release()


func _release() -> void:
	dragging = false
	var overlapping_areas := get_overlapping_areas()
	dropped.emit(self, overlapping_areas)
	if not _is_over_drop_target(overlapping_areas):
		self_destruct()


func _is_over_drop_target(overlapping_areas: Array) -> bool:
	for area in overlapping_areas:
		if area is Area2D and area.name == "DropTarget":
			return true
	return false


func play_spawn_animation() -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", initial_scale, TWEEN_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


func self_destruct() -> void:
	dragging = false
	_click_pressed = false
	set_process_input(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, TWEEN_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
