extends MarginContainer

@export var player: Player
@export var zoom: float = 1.5:
	set(value):
		zoom = clampf(value, 0.5, 5.0)
		if is_node_ready():
			_update_grid_scale()

@onready var grid: TextureRect = $Content/Grid
@onready var player_marker: Sprite2D = $Content/Grid/PlayerMarker
@onready var mob_marker: Sprite2D = $Content/Grid/MobMarker
@onready var alert_marker: Sprite2D = $Content/Grid/AlertMarker
@onready var icons: Dictionary = {
	"mob": mob_marker,
	"alert": alert_marker,
}

var grid_scale := Vector2.ZERO
var markers: Dictionary = {}


func _ready() -> void:
	set_process(false)
	# Containers finish laying out their children on the first frame.
	await get_tree().process_frame
	_update_layout()
	grid.resized.connect(_update_layout)
	get_viewport().size_changed.connect(_update_grid_scale)

	for object in get_tree().get_nodes_in_group("minimap_objects"):
		var marker: Sprite2D = icons[object.minimap_icon].duplicate()
		grid.add_child(marker)
		marker.show()
		markers[object] = marker

	set_process(true)
	_process(0.0)


func _update_layout() -> void:
	player_marker.position = grid.size / 2.0
	_update_grid_scale()


func _update_grid_scale() -> void:
	grid_scale = grid.size / get_viewport_rect().size * zoom


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	player_marker.rotation = player.global_rotation + PI / 2.0
	var grid_rect := Rect2(Vector2.ZERO, grid.size)
	for object in markers:
		var marker: Sprite2D = markers[object]
		var marker_position: Vector2 = (
			(object.global_position - player.global_position) * grid_scale
			+ player_marker.position
		)
		if grid_rect.has_point(marker_position):
			marker.scale = Vector2.ONE
		else:
			marker.scale = Vector2.ONE * 0.75
		marker.position = marker_position.clamp(Vector2.ZERO, grid.size)


func _on_object_removed(object: Node2D) -> void:
	if markers.has(object):
		var marker: Sprite2D = markers[object]
		markers.erase(object)
		marker.queue_free()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom += 0.1
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= 0.1
				accept_event()
