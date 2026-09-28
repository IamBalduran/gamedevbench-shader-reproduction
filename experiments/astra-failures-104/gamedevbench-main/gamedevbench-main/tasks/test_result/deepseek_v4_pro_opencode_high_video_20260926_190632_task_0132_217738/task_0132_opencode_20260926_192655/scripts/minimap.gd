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
	await get_tree().process_frame
	player_marker.position = grid.size / 2.0
	grid_scale = grid.size.x / (get_viewport().size.x * zoom)

	for object in get_tree().get_nodes_in_group("minimap_objects"):
		var icon_key = object.minimap_icon
		if icons.has(icon_key):
			var prototype = icons[icon_key]
			var marker = prototype.duplicate()
			marker.visible = true
			grid.add_child(marker)
			markers[object] = marker

func _process(delta):
	if not player:
		return

	player_marker.rotation = player.rotation + PI / 2.0
	grid_scale = grid.size.x / (get_viewport().size.x * zoom)

	for object in markers.keys():
		if not is_instance_valid(object):
			markers[object].queue_free()
			markers.erase(object)
			continue

		var marker = markers[object]
		var offset = (object.global_position - player.global_position) * grid_scale
		marker.position = player_marker.position + offset
		marker.rotation = player.rotation + PI / 2.0
		marker.scale = Vector2(0.75, 0.75)

		marker.position.x = clamp(marker.position.x, 0.0, grid.size.x)
		marker.position.y = clamp(marker.position.y, 0.0, grid.size.y)

func _on_object_removed(object):
	if markers.has(object):
		markers[object].queue_free()
		markers.erase(object)

func set_zoom(value):
	zoom = clamp(value, 0.5, 5.0)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += 0.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= 0.1