extends Node

func _ready():
	run_validation()

func fail(reason:String) -> int:
	print("VALIDATION_FAILED: %s" % reason)
	get_tree().quit(1)
	return 0

func run_validation():
	var main = get_node_or_null("Main")
	if not main:
		return fail("Main scene is missing")
	var hud = main.get_node_or_null("HUD")
	if not hud or not hud is CanvasLayer:
		return fail("HUD CanvasLayer not found")
	var margin := hud.get_node_or_null("MarginContainer")
	if not margin or not margin is MarginContainer:
		return fail("MarginContainer with HUD labels missing")
	if margin.get_theme_constant("margin_left") != 20:
		return fail("Top margin left padding must be 20")
	var hbox := margin.get_node_or_null("HBoxContainer")
	if not hbox or not hbox is HBoxContainer:
		return fail("HBoxContainer for labels missing")
	var health_label := hbox.get_node_or_null("Health")
	var score_label := hbox.get_node_or_null("Score")
	if not health_label or not score_label:
		return fail("Health/Score labels missing")
	if health_label.text != "Health: 100":
		return fail("Health label must default to 'Health: 100'")
	if score_label.text != "Score: 0":
		return fail("Score label must default to 'Score: 0'")
	var game_over := hud.get_node_or_null("GameOver")
	if not game_over or not game_over is MarginContainer:
		return fail("GameOver MarginContainer missing")
	if game_over.visible:
		return fail("GameOver must start hidden")
	if game_over.process_mode != Node.PROCESS_MODE_ALWAYS:
		return fail("GameOver process mode must be ALWAYS")
	if game_over.anchor_right != 1.0 or game_over.anchor_bottom != 1.0:
		return fail("GameOver anchors must stretch to viewport")
	if game_over.get_theme_constant("margin_left") != 70:
		return fail("GameOver margin left must be 70")
	if game_over.get_theme_constant("margin_bottom") != 100:
		return fail("GameOver margin bottom must be 100")
	var texture_rect := game_over.get_node_or_null("TextureRect")
	if not texture_rect or not texture_rect is TextureRect:
		return fail("GameOver needs a TextureRect background")
	if not texture_rect.texture or not texture_rect.texture is GradientTexture1D:
		return fail("TextureRect must use a GradientTexture1D")

	var labels_vbox := game_over.get_node_or_null("Labels")
	if not labels_vbox or not labels_vbox is VBoxContainer:
		return fail("Labels VBox missing")
	var title := labels_vbox.get_node_or_null("Label")
	var score_line := labels_vbox.get_node_or_null("Label2")
	var high_score_line := labels_vbox.get_node_or_null("Label3")
	if not title or not score_line or not high_score_line:
		return fail("GameOver labels missing")
	if title.text != "Game Over!!!":
		return fail("Title label must read 'Game Over!!!'")
	if score_line.text.strip_edges() != "your score is":
		return fail("Label2 text must mention current score")
	if high_score_line.text.strip_edges() != "your high score is":
		return fail("Label3 text must mention high score")

	var buttons_row := game_over.get_node_or_null("HBoxContainer")
	if not buttons_row or not buttons_row is HBoxContainer:
		return fail("Button row missing")
	var menu_button := buttons_row.get_node_or_null("menu")
	var restart_button := buttons_row.get_node_or_null("restart")
	if not menu_button or not restart_button:
		return fail("Menu and Restart buttons must exist")

	print("VALIDATION_PASSED: HUD GameOver overlay correctly built")
	get_tree().quit()
