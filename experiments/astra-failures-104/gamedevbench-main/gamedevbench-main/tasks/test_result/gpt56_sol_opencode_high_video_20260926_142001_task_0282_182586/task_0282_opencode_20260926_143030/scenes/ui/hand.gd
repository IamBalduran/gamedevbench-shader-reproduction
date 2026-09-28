extends HBoxContainer

const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")


func add_card(card_title: String) -> void:
	var new_card_ui = CARD_UI_SCENE.instantiate()
	add_child(new_card_ui)
	new_card_ui.home_parent = self
	new_card_ui.card_title = card_title
	new_card_ui.reparent_requested.connect(_on_card_reparent_requested)


func _on_card_reparent_requested(card_ui) -> void:
	if card_ui.get_parent() == self:
		return

	var original_index: int = card_ui.original_index
	card_ui.reparent(self)
	move_child(card_ui, clampi(original_index, 0, get_child_count() - 1))
