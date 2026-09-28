extends "res://scenes/card_ui/card_states/card_state.gd"

const DRAG_MINIMUM_THRESHOLD := 0.03

var time_dragged := 0.0


func _ready() -> void:
	set_process(false)


func enter() -> void:
	time_dragged = 0.0
	set_process(true)
	var float_layer: Node = card_ui.get_tree().get_first_node_in_group("float_layer")
	card_ui.reparent_requested.emit(card_ui)
	card_ui.reparent(float_layer)


func exit() -> void:
	set_process(false)


func _process(delta: float) -> void:
	time_dragged += delta
	card_ui.global_position = card_ui.get_global_mouse_position() - card_ui.size / 2


func on_input(event: InputEvent) -> void:
	if event.is_action_pressed("right_mouse"):
		transition_requested.emit(self, CardState.State.BASE)
	elif event.is_action_released("left_mouse") and time_dragged >= DRAG_MINIMUM_THRESHOLD:
		transition_requested.emit(self, CardState.State.RELEASED)
