extends Node

const CardState := preload("res://scenes/card_ui/card_states/card_state.gd")

@export var initial_state: CardState

var current_state: CardState
var states := {}


func init(card_ui) -> void:
	for child in get_children():
		if child is CardState:
			states[child.state] = child
			child.card_ui = card_ui
			child.transition_requested.connect(_on_transition_requested)

	if initial_state:
		current_state = initial_state
		current_state.enter()


func on_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_input(event)


func on_gui_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_gui_input(event)


func on_mouse_entered() -> void:
	if current_state:
		current_state.on_mouse_entered()


func on_mouse_exited() -> void:
	if current_state:
		current_state.on_mouse_exited()


func _on_transition_requested(from: CardState, to: int) -> void:
	if from != current_state:
		return

	var new_state: CardState = states.get(to)
	if not new_state or new_state == current_state:
		return

	current_state.exit()
	current_state = new_state
	current_state.enter()
