extends MarginContainer

@export_dir var sound_dir := "res://assets"

const POPPINS_FONT: Font = preload("res://assets/Poppins-Medium.ttf")

@onready var _grid: GridContainer = $CenterContainer/GridContainer
@onready var _available_label: Label = $CanvasLayer/HBoxContainer/Label2
@onready var _queue_label: Label = $CanvasLayer/HBoxContainer/Label3


func _ready() -> void:
	var dir := DirAccess.open(sound_dir)
	if dir == null:
		push_error("Could not open sound directory: %s" % sound_dir)
		return
	var files: Array[String] = []
	for file_name in dir.get_files():
		var lower := file_name.to_lower()
		if lower.ends_with(".wav") or lower.ends_with(".ogg"):
			files.append(file_name)
	files.sort()
	for file_name in files:
		add_button(file_name)


func add_button(file_name: String) -> void:
	var button := Button.new()
	button.text = file_name
	button.add_theme_font_override("font", POPPINS_FONT)
	button.pressed.connect(on_audio_button_pressed.bind(button))
	_grid.add_child(button)


func on_audio_button_pressed(button: Button) -> void:
	AudioManager.play(sound_dir.path_join(button.text))


func _process(_delta: float) -> void:
	_available_label.text = str(AudioManager.available.size())
	_queue_label.text = str(AudioManager.queue.size())
