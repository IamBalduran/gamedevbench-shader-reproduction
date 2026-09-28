extends Node

@export var initial_state: Node

var current_state
var states := {}


func init(card_ui) -> void:
	for child in get_children():
		states[child.state] = child
		child.card_ui = card_ui
		child.transition_requested.connect(_on_transition_requested)

	current_state = initial_state
	current_state.enter()


func on_input(event: InputEvent) -> void:
	current_state.on_input(event)


func on_gui_input(event: InputEvent) -> void:
	current_state.on_gui_input(event)


func on_mouse_entered() -> void:
	current_state.on_mouse_entered()


func on_mouse_exited() -> void:
	current_state.on_mouse_exited()


func _on_transition_requested(from, to: int) -> void:
	if from != current_state:
		return

	current_state.exit()
	current_state = states[to]
	current_state.enter()
