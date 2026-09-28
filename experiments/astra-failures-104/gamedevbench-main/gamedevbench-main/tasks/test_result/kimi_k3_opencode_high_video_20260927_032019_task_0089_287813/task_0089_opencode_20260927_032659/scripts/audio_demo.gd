extends MarginContainer

@export_dir var sound_dir := "res://assets"

@onready var grid_container: GridContainer = $CenterContainer/GridContainer
@onready var streams_label: Label = $CanvasLayer/HBoxContainer/Label

const POPPINS := preload("res://assets/Poppins-Medium.ttf")
const LABEL_TEMPLATE := "Available Streams: {num_available_streams} | Queue: {num_queud_streams}"


func _ready() -> void:
	var dir := DirAccess.open(sound_dir)
	if dir == null:
		push_error("Could not open sound directory: %s" % sound_dir)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.get_extension() == "wav" or file_name.get_extension() == "ogg"):
			add_button(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	call_deferred("_debug_dump")


func add_button(file_name: String) -> void:
	var button := Button.new()
	button.text = file_name
	button.add_theme_font_override("font", POPPINS)
	button.pressed.connect(on_audio_button_pressed.bind(button))
	grid_container.add_child(button)


func on_audio_button_pressed(button: Button) -> void:
	AudioManager.play(sound_dir.path_join(button.text))


func _process(_delta: float) -> void:
	streams_label.text = LABEL_TEMPLATE.format({
		"num_available_streams": AudioManager.available.size(),
		"num_queud_streams": AudioManager.queue.size(),
	})

func _debug_dump() -> void:
	print("DEBUG sound_dir=", sound_dir)
	print("DEBUG grid children=", grid_container.get_child_count())
	print("DEBUG label text=", streams_label.text)
	print("DEBUG label pos=", streams_label.global_position, " size=", streams_label.size)
	print("DEBUG grid pos=", grid_container.global_position, " size=", grid_container.size)
	print("DEBUG root size=", size, " global_pos=", global_position)
	print("DEBUG center size=", $CenterContainer.size)
