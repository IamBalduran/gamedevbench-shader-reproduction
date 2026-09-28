extends Node

func _ready():
	run_validation()

func fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit()

func run_validation():
	var main_node := get_node("Main")
	if main_node == null:
		fail("Main scene not found")
		return

	var balloon_layer := main_node.get_node_or_null("PortraitBalloon")
	if balloon_layer == null:
		fail("PortraitBalloon CanvasLayer missing under Main")
		return

	var balloon := balloon_layer.get_node_or_null("Balloon")
	if balloon == null:
		fail("Balloon control missing")
		return

	var margin := balloon.get_node_or_null("MarginContainer")
	if margin == null:
		fail("Top-level MarginContainer missing")
		return

	var panel := margin.get_node_or_null("PanelContainer")
	if panel == null:
		fail("PanelContainer missing under MarginContainer")
		return

	var inner_margin := panel.get_node_or_null("MarginContainer")
	if inner_margin == null:
		fail("Inner MarginContainer missing in PanelContainer")
		return

	var hbox := inner_margin.get_node_or_null("HBoxContainer")
	if hbox == null:
		fail("HBoxContainer missing — add it to host the portrait slot")
		return

	if hbox.get_theme_constant("separation") != 30:
		fail("HBoxContainer separation must be exactly 30 pixels")
		return

	var portrait_texture := hbox.get_node_or_null("PortraitTexture")
	if portrait_texture == null:
		fail("TextureRect named PortraitTexture missing inside HBoxContainer")
		return

	if portrait_texture.custom_minimum_size != Vector2(150, 150):
		fail("PortraitTexture custom_minimum_size must be 150x150")
		return

	if not portrait_texture.is_unique_name_in_owner():
		fail("PortraitTexture must have unique_name_in_owner enabled")
		return

	var text_column := hbox.get_node_or_null("VBoxContainer")
	if text_column == null:
		fail("VBoxContainer for dialogue text missing inside HBoxContainer")
		return
	
	# order
	var portrait_appeared = false
	for node in hbox.get_children():
		if node == portrait_texture:
			portrait_appeared = true
		if node == text_column and portrait_appeared:
			fail("Portrait is not to the right of text")
			return

	if text_column.size_flags_horizontal != Control.SIZE_EXPAND_FILL:
		fail("Text VBox must expand horizontally (SIZE_EXPAND_FILL)")
		return

	var theme: Theme = balloon.theme
	if theme == null:
		fail("Balloon must use a Theme resource")
		return

	if theme.get_default_font_size() != 26:
		fail("Theme default font size must be 26")
		return

	var margin_left: int = theme.get_constant("margin_left", "MarginContainer")
	var margin_right: int = theme.get_constant("margin_right", "MarginContainer")
	var margin_top: int = theme.get_constant("margin_top", "MarginContainer")
	var margin_bottom: int = theme.get_constant("margin_bottom", "MarginContainer")
	for value in [margin_left, margin_right, margin_top, margin_bottom]:
		if value != 30:
			fail("All MarginContainer constants must be set to 30")
			return

	var panel_style: StyleBox = theme.get_stylebox("panel", "PanelContainer")
	if panel_style == null:
		fail("Theme must override PanelContainer panel style")
		return

	if panel_style.bg_color != Color(0.090196, 0.262745, 0.54902, 1.0):
		fail("Panel background color must be RPG blue (#1743 8C)")
		return

	var button_normal: StyleBox = theme.get_stylebox("normal", "Button")
	var button_focus: StyleBox = theme.get_stylebox("focus", "Button")
	if button_normal == null or button_focus == null:
		fail("Theme must override Button normal & focus styleboxes")
		return

	if button_normal.bg_color != Color(0.058824, 0.156863, 0.396078, 1.0):
		fail("Button normal style must use the darker blue color")
		return

	if button_focus.bg_color != Color(0.258824, 0.509804, 0.901961, 1.0):
		fail("Button focus style must use the lighter highlight blue")
		return

	print("VALIDATION_PASSED: Portrait balloon layout configured correctly")
	get_tree().quit(0)
