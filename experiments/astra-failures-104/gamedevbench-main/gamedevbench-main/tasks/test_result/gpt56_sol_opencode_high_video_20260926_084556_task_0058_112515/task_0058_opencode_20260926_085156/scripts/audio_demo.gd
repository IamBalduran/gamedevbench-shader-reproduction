extends MarginContainer

@export_dir var sound_dir := "res://assets"

const POPPINS_MEDIUM := preload("res://assets/Poppins-Medium.ttf")

@onready var grid_container: GridContainer = $CenterContainer/GridContainer
@onready var available_count: Label = $CanvasLayer/HBoxContainer/Label2
@onready var queue_count: Label = $CanvasLayer/HBoxContainer/Label3


func _ready() -> void:
	var directory := DirAccess.open(sound_dir)
	if directory == null:
		push_error("Unable to open sound directory: %s" % sound_dir)
		return

	for file_name in directory.get_files():
		var extension := file_name.get_extension().to_lower()
		if extension == "wav" or extension == "ogg":
			add_button(file_name)


func add_button(file_name: String) -> void:
	var button := Button.new()
	button.text = file_name
	button.add_theme_font_override("font", POPPINS_MEDIUM)
	button.pressed.connect(on_audio_button_pressed.bind(button))
	grid_container.add_child(button)


func on_audio_button_pressed(button: Button) -> void:
	AudioManager.play(sound_dir.path_join(button.text))


func _process(_delta: float) -> void:
	available_count.text = str(AudioManager.available.size())
	queue_count.text = str(AudioManager.queue.size())
