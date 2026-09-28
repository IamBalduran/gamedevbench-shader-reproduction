extends Area2D

signal dropped(draggable, overlapping_areas)

var initial_position: Vector2
var initial_scale: Vector2
var is_dragging: bool = false

func _ready() -> void:
	initial_position = position
	initial_scale = scale
	play_spawn_animation()

func play_spawn_animation() -> void:
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", initial_scale, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		is_dragging = true

func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drop()

func _process(delta: float) -> void:
	if not is_dragging:
		return
	position = position.lerp(get_global_mouse_position(), 20.0 * delta)

func _drop() -> void:
	is_dragging = false
	var overlapping = get_overlapping_areas()
	dropped.emit(self, overlapping)
	var on_drop_target = false
	for area in overlapping:
		if area.name == "DropTarget":
			on_drop_target = true
			break
	if not on_drop_target:
		self_destruct()

func self_destruct() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)