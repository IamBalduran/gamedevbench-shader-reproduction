extends Node

const PANEL_SCENE := "res://scenes/ui/battle_over_panel.tscn"
const PANEL_SCRIPT := "res://scenes/ui/battle_over_panel.gd"


func _ready() -> void:
	run_validation()


func run_validation() -> void:
	if not ResourceLoader.exists(PANEL_SCENE):
		print("VALIDATION_FAILED: battle_over_panel.tscn not found")
		get_tree().quit(1)
		return

	if not ResourceLoader.exists(PANEL_SCRIPT):
		print("VALIDATION_FAILED: battle_over_panel.gd not found")
		get_tree().quit(1)
		return

	var packed: PackedScene = load(PANEL_SCENE)
	if not packed:
		print("VALIDATION_FAILED: battle_over_panel.tscn failed to load")
		get_tree().quit(1)
		return

	var panel = packed.instantiate()
	if not (panel is Panel):
		print("VALIDATION_FAILED: BattleOverPanel root must be a Panel")
		get_tree().quit(1)
		return

	if panel.name != "BattleOverPanel":
		print("VALIDATION_FAILED: BattleOverPanel root must be named BattleOverPanel")
		get_tree().quit(1)
		return

	if panel.process_mode != Node.PROCESS_MODE_ALWAYS:
		print("VALIDATION_FAILED: BattleOverPanel process_mode must be Always")
		get_tree().quit(1)
		return

	if panel.anchor_right != 1.0 or panel.anchor_bottom != 1.0:
		print("VALIDATION_FAILED: BattleOverPanel must stretch to full rect")
		get_tree().quit(1)
		return

	var stylebox = panel.get("theme_override_styles/panel")
	if not stylebox or not (stylebox is StyleBoxFlat):
		print("VALIDATION_FAILED: BattleOverPanel must override panel style with StyleBoxFlat")
		get_tree().quit(1)
		return

	if stylebox.bg_color != Color(0, 0, 0, 0.47):
		print("VALIDATION_FAILED: BattleOverPanel background color must be rgba(0,0,0,0.47)")
		get_tree().quit(1)
		return

	var vbox = panel.get_node("VBoxContainer")
	if not (vbox is VBoxContainer):
		print("VALIDATION_FAILED: VBoxContainer missing under BattleOverPanel")
		get_tree().quit(1)
		return

	if vbox.anchor_left != 0.5 or vbox.anchor_top != 0.5 or vbox.anchor_right != 0.5 or vbox.anchor_bottom != 0.5:
		print("VALIDATION_FAILED: VBoxContainer must be centered with 0.5 anchors")
		get_tree().quit(1)
		return

	if vbox.offset_left != -36.0 or vbox.offset_top != -36.0 or vbox.offset_right != 36.0 or vbox.offset_bottom != 36.0:
		print("VALIDATION_FAILED: VBoxContainer offsets must be -36/-36/36/36")
		get_tree().quit(1)
		return

	var label = vbox.get_node("Label")
	if not (label is Label):
		print("VALIDATION_FAILED: Label missing in VBoxContainer")
		get_tree().quit(1)
		return

	if label.text != 'Encounter Won':
		print("VALIDATION_FAILED: Label text must be 'Encounter Won'")
		get_tree().quit(1)
		return

	if not label.label_settings or label.label_settings.font_size != 31:
		print("VALIDATION_FAILED: Label must use LabelSettings with font_size 31")
		get_tree().quit(1)
		return

	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER or label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		print("VALIDATION_FAILED: Label alignment must be centered")
		get_tree().quit(1)
		return

	var continue_button = vbox.get_node("ContinueButton")
	if not (continue_button is Button):
		print("VALIDATION_FAILED: ContinueButton missing in VBoxContainer")
		get_tree().quit(1)
		return

	if continue_button.text != 'Next Round':
		print("VALIDATION_FAILED: ContinueButton text must be 'Next Round'")
		get_tree().quit(1)
		return

	if continue_button.custom_minimum_size != Vector2(80, 28):
		print("VALIDATION_FAILED: ContinueButton custom_minimum_size must be (80, 28)")
		get_tree().quit(1)
		return

	if continue_button.size_flags_horizontal != 2:
		print("VALIDATION_FAILED: ContinueButton size_flags_horizontal must be Expand")
		get_tree().quit(1)
		return

	var restart_button = vbox.get_node("RestartButton")
	if not (restart_button is Button):
		print("VALIDATION_FAILED: RestartButton missing in VBoxContainer")
		get_tree().quit(1)
		return

	if restart_button.text != 'Reset Fight':
		print("VALIDATION_FAILED: RestartButton text must be 'Reset Fight'")
		get_tree().quit(1)
		return

	if restart_button.custom_minimum_size != Vector2(80, 28):
		print("VALIDATION_FAILED: RestartButton custom_minimum_size must be (80, 28)")
		get_tree().quit(1)
		return

	if restart_button.size_flags_horizontal != 2:
		print("VALIDATION_FAILED: RestartButton size_flags_horizontal must be Expand")
		get_tree().quit(1)
		return

	if panel.get_script() == null or panel.get_script().resource_path != PANEL_SCRIPT:
		print("VALIDATION_FAILED: BattleOverPanel must use battle_over_panel.gd")
		get_tree().quit(1)
		return

	var script: Script = panel.get_script()
	if script.get_global_name() != "BattleOverPanel":
		print("VALIDATION_FAILED: Script must have class_name BattleOverPanel")
		get_tree().quit(1)
		return

	if not "Type" in panel:
		print("VALIDATION_FAILED: Script must define enum Type")
		get_tree().quit(1)
		return

	if not panel.has_method("show_screen"):
		print("VALIDATION_FAILED: Script must have show_screen method")
		get_tree().quit(1)
		return

	add_child(panel)
	panel.hide()
	get_tree().paused = false

	panel.show_screen("You Win!", 0)

	if label.text != "You Win!":
		print("VALIDATION_FAILED: show_screen must update label text")
		get_tree().quit(1)
		return

	if not continue_button.visible:
		print("VALIDATION_FAILED: show_screen with WIN must show ContinueButton")
		get_tree().quit(1)
		return

	if restart_button.visible:
		print("VALIDATION_FAILED: show_screen with WIN must hide RestartButton")
		get_tree().quit(1)
		return

	if not panel.visible:
		print("VALIDATION_FAILED: show_screen must show the panel")
		get_tree().quit(1)
		return

	if not get_tree().paused:
		print("VALIDATION_FAILED: show_screen must pause the scene tree")
		get_tree().quit(1)
		return

	panel.hide()
	get_tree().paused = false
	panel.show_screen("You Lose!", 1)

	if label.text != "You Lose!":
		print("VALIDATION_FAILED: show_screen must update label text for LOSE")
		get_tree().quit(1)
		return

	if continue_button.visible:
		print("VALIDATION_FAILED: show_screen with LOSE must hide ContinueButton")
		get_tree().quit(1)
		return

	if not restart_button.visible:
		print("VALIDATION_FAILED: show_screen with LOSE must show RestartButton")
		get_tree().quit(1)
		return

	panel.hide()
	get_tree().paused = false
	Events.battle_over_screen_requested.emit("Signal Test", 0)

	if not panel.visible:
		print("VALIDATION_FAILED: Script must connect Events.battle_over_screen_requested to show_screen")
		get_tree().quit(1)
		return

	get_tree().paused = false

	print("VALIDATION_PASSED: Task completed successfully")
	get_tree().quit(0)
