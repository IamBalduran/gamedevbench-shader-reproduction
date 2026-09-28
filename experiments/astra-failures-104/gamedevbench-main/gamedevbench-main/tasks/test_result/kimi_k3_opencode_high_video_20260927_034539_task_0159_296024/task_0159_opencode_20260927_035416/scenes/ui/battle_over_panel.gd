class_name BattleOverPanel
extends Panel

enum Type {WIN, LOSE}

@onready var label: Label = %Label
@onready var continue_button: Button = %ContinueButton
@onready var restart_button: Button = %RestartButton
@onready var vbox: VBoxContainer = $VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel_overlay := StyleBoxFlat.new()
	panel_overlay.bg_color = Color(0, 0, 0, 0.47)
	add_theme_stylebox_override("panel", panel_overlay)

	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -36.0
	vbox.offset_top = -36.0
	vbox.offset_right = 36.0
	vbox.offset_bottom = 36.0

	var label_theme := LabelSettings.new()
	label_theme.font_size = 31
	label.label_settings = label_theme
	label.text = 'Encounter Won'
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var button_minimum := Vector2(80, 28)
	continue_button.custom_minimum_size = button_minimum
	restart_button.custom_minimum_size = button_minimum
	continue_button.text = 'Next Round'
	restart_button.text = 'Reset Fight'

	continue_button.pressed.connect(get_tree().quit)
	restart_button.pressed.connect(get_tree().reload_current_scene)
	Events.battle_over_screen_requested.connect(show_screen)


func show_screen(text: String, type: Type) -> void:
	label.text = text
	continue_button.visible = type == Type.WIN
	restart_button.visible = type == Type.LOSE
	show()
	get_tree().paused = true
