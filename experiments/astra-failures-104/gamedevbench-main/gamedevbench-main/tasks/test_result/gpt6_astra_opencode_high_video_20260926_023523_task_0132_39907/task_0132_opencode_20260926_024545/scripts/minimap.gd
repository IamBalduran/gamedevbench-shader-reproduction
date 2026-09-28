extends MarginContainer
class_name Minimap

@export var player: Player
@export var zoom: float = 1.5:
	set = set_zoom

@onready var grid = $Content/Grid
@onready var player_marker = $Content/Grid/PlayerMarker
@onready var mob_marker = $Content/Grid/MobMarker
@onready var alert_marker = $Content/Grid/AlertMarker

@onready var icons = {
	"mob": mob_marker,
	"alert": alert_marker
}

var grid_scale = Vector2.ZERO
var markers = {}

func _ready():
	set_process(false)
	# Containers finish laying out their children on the first frame.
	await get_tree().process_frame
	_update_grid()
	grid.resized.connect(_update_grid)
	get_viewport().size_changed.connect(_update_grid)
	for object in get_tree().get_nodes_in_group("minimap_objects"):
		var marker = icons[object.minimap_icon].duplicate()
		grid.add_child(marker)
		marker.show()
		markers[object] = marker
	_process(0.0)
	set_process(true)

func _process(_delta):
	if not is_instance_valid(player):
		return
	player_marker.rotation = player.global_rotation + PI / 2
	var grid_rect = Rect2(Vector2.ZERO, grid.size)
	for object in markers.keys():
		if not is_instance_valid(object):
			_on_object_removed(object)
			continue
		var marker = markers[object]
		var marker_position = (object.global_position - player.global_position) * grid_scale + player_marker.position
		marker.scale = Vector2.ONE if grid_rect.has_point(marker_position) else Vector2(0.75, 0.75)
		marker.position = marker_position.clamp(Vector2.ZERO, grid.size)

func _on_object_removed(object):
	if markers.has(object):
		markers[object].queue_free()
		markers.erase(object)

func set_zoom(value):
	zoom = clampf(value, 0.5, 5.0)
	if is_instance_valid(grid):
		_update_grid()

func _update_grid():
	player_marker.position = grid.size / 2
	grid_scale = grid.size / get_viewport_rect().size * zoom

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom += 0.1
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= 0.1
				accept_event()
