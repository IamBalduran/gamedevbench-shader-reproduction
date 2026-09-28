extends MarginContainer

@export_dir var sound_dir := "res://assets"

var _font: FontFile


func _ready() -> void:
	_font = load("res://assets/Poppins-Medium.ttf")
	var grid := $CenterContainer/GridContainer
	var dir := DirAccess.open(sound_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".wav") or file_name.ends_with(".ogg")):
			var btn := Button.new()
			btn.text = file_name
			btn.add_theme_font_override("font", _font)
			btn.pressed.connect(on_audio_button_pressed.bind(btn))
			grid.add_child(btn)
		file_name = dir.get_next()
	dir.list_dir_end()


func on_audio_button_pressed(btn: Button) -> void:
	AudioManager.play(sound_dir + "/" + btn.text)


func _process(_delta: float) -> void:
	$CanvasLayer/HBoxContainer/Label2.text = str(AudioManager.available.size())
	$CanvasLayer/HBoxContainer/Label3.text = str(AudioManager.queue.size())