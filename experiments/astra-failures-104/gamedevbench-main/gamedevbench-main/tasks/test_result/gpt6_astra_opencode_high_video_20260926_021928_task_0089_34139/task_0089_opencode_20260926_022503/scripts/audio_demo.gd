extends MarginContainer

@export_dir var sound_dir := "res://assets"

const POPPINS_FONT := preload("res://assets/Poppins-Medium.ttf")
const STREAM_LABEL_TEMPLATE := "Available Streams: {num_available_streams} | Queue: {num_queud_streams}"

@onready var sound_grid: GridContainer = $CenterContainer/GridContainer
@onready var stream_label: Label = $CanvasLayer/HBoxContainer/Label


func _ready() -> void:
	var sound_files := DirAccess.get_files_at(sound_dir)
	sound_files.sort()
	for file_name in sound_files:
		var lower_name := file_name.to_lower()
		if lower_name.ends_with(".wav") or lower_name.ends_with(".ogg"):
			add_button(file_name)
	_update_stream_label()


func add_button(file_name: String) -> void:
	var button := Button.new()
	button.text = file_name
	button.custom_minimum_size = Vector2(220, 48)
	button.add_theme_font_override("font", POPPINS_FONT)
	button.set_meta("audio_path", sound_dir.path_join(file_name))
	button.pressed.connect(on_audio_button_pressed.bind(button))
	sound_grid.add_child(button)


func on_audio_button_pressed(button: Button) -> void:
	var audio_path: String = button.get_meta("audio_path", "")
	if not audio_path.is_empty():
		AudioManager.play(audio_path)


func _process(_delta: float) -> void:
	_update_stream_label()


func _update_stream_label() -> void:
	stream_label.text = STREAM_LABEL_TEMPLATE.format({
		"num_available_streams": AudioManager.available.size(),
		"num_queud_streams": AudioManager.queue.size(),
	})
