extends "res://scenes/card_ui/card_states/card_state.gd"

var played := false


func enter() -> void:
	card_ui.state_label.text = "Released"
	played = not card_ui.targets.is_empty()
	if played:
		card_ui.play()


func on_input(_event: InputEvent) -> void:
	if not played:
		transition_requested.emit(self, State.BASE)
