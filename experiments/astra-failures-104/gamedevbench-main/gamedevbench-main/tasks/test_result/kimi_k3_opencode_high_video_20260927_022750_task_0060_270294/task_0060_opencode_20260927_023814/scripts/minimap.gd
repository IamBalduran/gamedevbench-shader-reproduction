extends MarginContainer

@export var player: Player
@export var zoom := 1.0:
	set(value):
		zoom = clampf(value, 0.5, 3.0)

var markers := {}

@onready var grid: TextureRect = $Content/Grid
@onready var _marker_prototypes := {
	"player": $Content/Grid/PlayerMarker,
	"mob": $Content/Grid/MobMarker,
	"alert": $Content/Grid/AlertMarker,
}

var grid_scale := 1.0

func _ready() -> void:
	await get_tree().process_frame
	_marker_prototypes["player"].position = grid.size / 2.0
	grid_scale = grid.size.x / get_viewport_rect().size.x
	for object in get_tree().get_nodes_in_group("minimap_objects"):
		if not _marker_prototypes.has(object.minimap_icon):
			continue
		var marker: Sprite2D = _marker_prototypes[object.minimap_icon].duplicate()
		grid.add_child(marker)
		marker.show()
		markers[object] = marker

func _process(_delta: float) -> void:
	if player == null:
		return
	_marker_prototypes["player"].rotation = player.rotation + PI / 2.0
	for object in markers:
		var offset: Vector2 = (object.global_position - player.global_position) * grid_scale * zoom
		var marker: Sprite2D = markers[object]
		var half_grid := grid.size / 2.0
		var clamped_offset := offset.clamp(-half_grid, half_grid)
		marker.scale = Vector2(1.0, 1.0) if offset == clamped_offset else Vector2(0.75, 0.75)
		marker.position = half_grid + clamped_offset

func _on_object_removed(object: Node2D) -> void:
	if markers.has(object):
		markers[object].queue_free()
		markers.erase(object)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += 0.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= 0.1
