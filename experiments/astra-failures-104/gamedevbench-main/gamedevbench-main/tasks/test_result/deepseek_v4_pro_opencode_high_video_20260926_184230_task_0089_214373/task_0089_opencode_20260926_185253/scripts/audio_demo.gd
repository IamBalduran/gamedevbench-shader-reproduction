extends MarginContainer

@export_dir var sound_dir := "res://assets"

var _poppins_font: Font = null

func _ready() -> void:
	_poppins_font = load("res://assets/Poppins-Medium.ttf")
	var grid := $CenterContainer/GridContainer
	var dir := DirAccess.open(sound_dir)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".wav") or file_name.ends_with(".ogg")):
				var btn := Button.new()
				btn.text = file_name
				btn.add_theme_font_override("font", _poppins_font)
				btn.pressed.connect(on_audio_button_pressed.bind(btn))
				grid.add_child(btn)
			file_name = dir.get_next()
		dir.list_dir_end()


func on_audio_button_pressed(btn: Button) -> void:
	var file_path := sound_dir + "/" + btn.text
	var am = get_node("/root/AudioManager")
	am.play(file_path)


func _process(_delta: float) -> void:
	var am = get_node("/root/AudioManager")
	var label: Label = $CanvasLayer/HBoxContainer/Label
	label.text = "Available Streams: %d | Queue: %d" % [am.available.size(), am.queue.size()]