extends MarginContainer

@export_dir var sound_dir := "res://assets"

const STATUS_TEMPLATE := "Available Streams: {num_available_streams} | Queue: {num_queud_streams}"
const POPPINS_MEDIUM := preload("res://assets/Poppins-Medium.ttf")

@onready var grid_container: GridContainer = %GridContainer
@onready var label: Label = %Label

func _ready() -> void:
	for file_name in DirAccess.get_files_at(sound_dir):
		if file_name.get_extension().to_lower() in ["wav", "ogg"]:
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
	label.text = STATUS_TEMPLATE.format({
		"num_available_streams": AudioManager.available.size(),
		"num_queud_streams": AudioManager.queue.size(),
	})
