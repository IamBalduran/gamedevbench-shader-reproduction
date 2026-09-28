extends MarginContainer

@export var player: Player
@export var zoom: float = 10.0:
	set(value):
		zoom = clamp(value, 1.0, 50.0)

var _grid: TextureRect
var _player_marker: Sprite2D
var _mob_marker_prototype: Sprite2D
var _alert_marker_prototype: Sprite2D
var _markers: Dictionary = {}
var _grid_scale: Vector2
var _first_frame_done := false

func _ready():
	_grid = $Content/Grid
	_player_marker = $Content/Grid/PlayerMarker
	_mob_marker_prototype = $Content/Grid/MobMarker
	_alert_marker_prototype = $Content/Grid/AlertMarker

	gui_input.connect(_on_gui_input)

	_update_grid_scale()

func _update_grid_scale():
	var viewport_size = get_viewport().get_visible_rect().size
	_grid_scale = _grid.size / viewport_size * zoom

func _process(delta):
	if not _first_frame_done:
		_first_frame_done = true
		_player_marker.position = _grid.size / 2.0
		await get_tree().process_frame
		_create_object_markers()
		return

	if not player:
		return

	_player_marker.rotation = player.rotation + PI / 2.0

	var to_remove := []
	for obj in _markers:
		if not is_instance_valid(obj) or obj.is_queued_for_deletion():
			to_remove.append(obj)
			continue
		var marker = _markers[obj]
		var offset = obj.global_position - player.global_position
		var grid_pos = _grid.size / 2.0 + offset * _grid_scale
		marker.position = grid_pos.clamp(Vector2.ZERO, _grid.size)
		marker.rotation = player.rotation + PI / 2.0
		marker.scale = Vector2(0.75, 0.75)

	for obj in to_remove:
		if _markers.has(obj):
			_markers[obj].queue_free()
			_markers.erase(obj)

func _create_object_markers():
	var objects = get_tree().get_nodes_in_group("minimap_objects")
	for obj in objects:
		if not "minimap_icon" in obj:
			continue
		var icon = obj.minimap_icon
		var prototype = _get_prototype_for_icon(icon)
		if prototype:
			var marker = prototype.duplicate()
			marker.visible = true
			_grid.add_child(marker)
			_markers[obj] = marker

func _get_prototype_for_icon(icon: Texture2D) -> Sprite2D:
	if icon == _mob_marker_prototype.texture:
		return _mob_marker_prototype
	if icon == _alert_marker_prototype.texture:
		return _alert_marker_prototype
	return null

func _on_object_removed(obj):
	if obj in _markers:
		var marker = _markers[obj]
		marker.queue_free()
		_markers.erase(obj)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += 1.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= 1.0
		_update_grid_scale()