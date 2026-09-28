extends MarginContainer

@export var player: Player
@export_range(0.5, 5.0, 0.1) var zoom := 1.5:
	set(value):
		zoom = clampf(value, 0.5, 5.0)
		if is_node_ready():
			_update_grid_scale()

@onready var grid: TextureRect = $Content/Grid
@onready var player_marker: Sprite2D = $Content/Grid/PlayerMarker
@onready var marker_prototypes := {
	&"mob": $Content/Grid/MobMarker,
	&"alert": $Content/Grid/AlertMarker,
}

var grid_scale := Vector2.ZERO
var markers: Dictionary = {}


func _ready() -> void:
	await get_tree().process_frame
	player_marker.position = grid.size / 2.0
	_update_grid_scale()

	for object in get_tree().get_nodes_in_group(&"minimap_objects"):
		var icon_key: StringName = object.minimap_icon
		if not marker_prototypes.has(icon_key):
			push_warning("Unknown minimap icon '%s' for %s" % [icon_key, object.name])
			continue

		var marker: Sprite2D = marker_prototypes[icon_key].duplicate()
		grid.add_child(marker)
		marker.show()
		markers[object] = marker


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	player_marker.rotation = player.rotation + PI / 2.0
	var grid_rect := Rect2(Vector2.ZERO, grid.size)
	var grid_center := grid.size / 2.0

	for object in markers.keys():
		if not is_instance_valid(object):
			_on_object_removed(object)
			continue

		var marker: Sprite2D = markers[object]
		var marker_position: Vector2 = (object.global_position - player.global_position) \
			* grid_scale * zoom
		marker_position = grid_center + marker_position.rotated(-player.rotation)
		if grid_rect.has_point(marker_position):
			marker.scale = Vector2.ONE
		else:
			marker.scale = Vector2.ONE * 0.75
			marker_position = marker_position.clamp(Vector2.ZERO, grid.size)
		marker.position = marker_position


func _update_grid_scale() -> void:
	grid_scale = grid.size / get_viewport_rect().size


func _on_object_removed(object: Node) -> void:
	if not markers.has(object):
		return

	markers[object].queue_free()
	markers.erase(object)


func _on_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton or not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom += 0.1
		accept_event()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom -= 0.1
		accept_event()
