extends MarginContainer
class_name Minimap

@export var player: Player
@export var zoom = 1.5:
	set = set_zoom

@onready var grid = $Content/Grid
@onready var player_marker = $Content/Grid/PlayerMarker
@onready var mob_marker = $Content/Grid/MobMarker
@onready var alert_marker = $Content/Grid/AlertMarker

@onready var icons = {
	"mob": mob_marker,
	"alert": alert_marker
}

var grid_scale
var markers = {}

func _ready():
	# Center the player marker after the first frame, when the grid
	# has been laid out and its size is final.
	await get_tree().process_frame
	player_marker.position = grid.size / 2
	# Scale factor between world units and minimap pixels.
	var map_size = player.map_limits.end * player.map_cell_size
	grid_scale = grid.size / (map_size * zoom)
	# Create a marker for every object in the "minimap_objects" group.
	var map_objects = get_tree().get_nodes_in_group("minimap_objects")
	for item in map_objects:
		var new_marker = icons[item.minimap_icon].duplicate()
		grid.add_child(new_marker)
		new_marker.show()
		markers[item] = new_marker

func _process(delta):
	if !player:
		return
	player_marker.rotation = player.rotation + PI/2
	for item in markers:
		var obj_pos = (item.position - player.position) * grid_scale + grid.size / 2
		if grid.get_rect().has_point(obj_pos + grid.position):
			markers[item].scale = Vector2(1, 1)
		else:
			markers[item].scale = Vector2(0.75, 0.75)
		obj_pos.x = clamp(obj_pos.x, 0, grid.size.x)
		obj_pos.y = clamp(obj_pos.y, 0, grid.size.y)
		markers[item].position = obj_pos

func _on_object_removed(object):
	if object in markers:
		markers[object].queue_free()
		markers.erase(object)

func set_zoom(value):
	zoom = clamp(value, 0.5, 5)
	var map_size = player.map_limits.end * player.map_cell_size
	grid_scale = grid.size / (map_size * zoom)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += 0.1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= 0.1