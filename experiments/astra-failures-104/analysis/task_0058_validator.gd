extends Node

func _ready():
	run_validation()


func fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)


func run_validation() -> void:
	var demo := get_node("AudioDemo")
	if not (demo is MarginContainer):
		return fail("Root AudioDemo must be a MarginContainer")
	if not demo.get_script() or not demo.get_script().resource_path.ends_with("scripts/audio_demo.gd"):
		return fail("AudioDemo must use res://scripts/audio_demo.gd")
	if demo.sound_dir != "res://assets":
		return fail("sound_dir should default to res://assets")

	for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		if demo.get_theme_constant(margin) != 20:
			return fail("Margins should be 20 on all sides")

	var center := demo.get_node_or_null("CenterContainer")
	if not center or not (center is CenterContainer):
		return fail("CenterContainer not found")
	var grid := center.get_node_or_null("GridContainer")
	if not grid or not (grid is GridContainer):
		return fail("GridContainer not found")
	if grid.columns != 2:
		return fail("GridContainer should use two columns")
	if grid.get_theme_constant("h_separation") != 10 or grid.get_theme_constant("v_separation") != 10:
		return fail("GridContainer spacing should be 10")

	var canvas := demo.get_node_or_null("CanvasLayer")
	if not canvas:
		return fail("CanvasLayer missing")
	var bar := canvas.get_node_or_null("HBoxContainer")
	if not bar or not (bar is HBoxContainer):
		return fail("HBoxContainer missing")

	var labels := {
		"Label": "Available Streams:",
		"Label2": "0",
		"Label4": "Queue:",
		"Label3": "0",
	}
	for name in labels.keys():
		var label := bar.get_node_or_null(name)
		if not label or not (label is Label):
			return fail("%s label missing" % name)
		if label.text != labels[name]:
			return fail("%s text incorrect" % name)
		var font = label.get_theme_font("font")
		if not font or not font.resource_path.ends_with("assets/Poppins-Medium.ttf"):
			return fail("%s must use Poppins-Medium font" % name)
		if label.get_theme_font_size("font_size") != 24:
			return fail("%s font size should be 24" % name)

	if not get_node_or_null("/root/AudioManager"):
		return fail("AudioManager autoload must be present for the UI to work")

	var dir := DirAccess.open(demo.sound_dir)
	if not dir:
		return fail("sound_dir cannot be opened")
	var audio_files: Array = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.get_extension() in ["wav", "ogg"]:
			audio_files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	audio_files.sort()

	var buttons := []
	for child in grid.get_children():
		if child is Button:
			buttons.append(child)
	if buttons.size() != audio_files.size():
		return fail("Button count (%s) must match audio files (%s)" % [buttons.size(), audio_files.size()])

	var button_names := []
	for b in buttons:
		button_names.append(b.text)
		if not b.is_connected("pressed", Callable(demo, "on_audio_button_pressed")):
			return fail("Buttons must connect pressed to on_audio_button_pressed")
	button_names.sort()
	if button_names != audio_files:
		return fail("Button labels must list all audio filenames from sound_dir")

	# Reset AudioManager state and verify stats update logic.
	var audio_manager := get_node("/root/AudioManager")
	audio_manager.queue.clear()
	audio_manager.available.clear()
	audio_manager.available.append_array(audio_manager.get_children())

	demo._process(0.0)
	if bar.get_node("Label2").text != str(audio_manager.available.size()):
		return fail("Available count label must reflect AudioManager.available size")
	if bar.get_node("Label3").text != str(audio_manager.queue.size()):
		return fail("Queue label must reflect AudioManager.queue size")

	var first_button: Button = buttons[0]
	first_button.emit_signal("pressed")
	if audio_manager.queue.size() == 0:
		return fail("Button press should enqueue audio path via AudioManager.play")

	audio_manager._process(0.0)
	demo._process(0.0)
	if audio_manager.available.size() != audio_manager.num_players - 1:
		return fail("AudioManager should be using exactly one player after processing queue")
	if bar.get_node("Label2").text != str(audio_manager.available.size()):
		return fail("Available label should update after playback starts")
	if bar.get_node("Label3").text != str(audio_manager.queue.size()):
		return fail("Queue label should update after playback")

	print("VALIDATION_PASSED: Audio demo UI lists sounds, wires buttons, and reflects AudioManager stats")
	get_tree().quit()
