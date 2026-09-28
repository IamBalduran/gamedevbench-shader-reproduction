extends Node

func _ready():
	await get_tree().process_frame
	run_validation()

func fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)

func assert_condition(condition: bool, message: String) -> void:
	if not condition:
		fail(message)

func has_property(obj: Object, name: String) -> bool:
	for prop in obj.get_property_list():
		if prop.name == name:
			return true
	return false

func run_validation():
	var main = get_node_or_null("Main")
	assert_condition(main != null, "Main scene not found")

	var minimap = main.get_node_or_null("CanvasLayer/Minimap")
	assert_condition(minimap != null, "Minimap not found under CanvasLayer")
	assert_condition(minimap.has_method("_process"), "Minimap must be a script instance")

	var grid: TextureRect = minimap.get_node_or_null("Content/Grid")
	assert_condition(grid != null, "Grid TextureRect missing")
	var player_marker: Sprite2D = grid.get_node_or_null("PlayerMarker")
	assert_condition(player_marker != null, "PlayerMarker missing")

	var player = main.get_node_or_null("Player")
	assert_condition(player != null, "Player node missing")

	# Core exports and cached nodes
	assert_condition(has_property(minimap, "player"), "Minimap must export player")
	assert_condition(has_property(minimap, "zoom"), "Minimap must export zoom")
	assert_condition(minimap.has_method("set_zoom"), "Minimap must define set_zoom")
	assert_condition(has_property(minimap, "grid_scale"), "grid_scale property missing")
	assert_condition(has_property(minimap, "markers"), "markers dictionary missing")

	var expected_center: Vector2 = grid.size / 2.0
	var center_delta = (player_marker.position - expected_center).length()
	assert_condition(center_delta <= 0.5, "PlayerMarker should start centered on Grid")

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var expected_scale: Vector2 = grid.size / (viewport_rect.size * minimap.zoom)
	assert_condition((minimap.grid_scale - expected_scale).length() < 0.01, "grid_scale must be derived from grid size, viewport, and zoom")

	# Markers duplicated for minimap_objects
	var mob: Node2D = main.get_node_or_null("Mobs/Mob")
	var crate: Node2D = main.get_node_or_null("Crates/Crate")
	assert_condition(mob != null and crate != null, "Mob and Crate nodes must exist")
	var markers: Dictionary = minimap.markers
	assert_condition(markers.has(mob), "Mob should have a duplicated marker tracked")
	assert_condition(markers.has(crate), "Crate should have a duplicated marker tracked")
	var mob_marker: Sprite2D = markers[mob]
	var crate_marker: Sprite2D = markers[crate]
	assert_condition(mob_marker.get_parent() == grid and crate_marker.get_parent() == grid, "Duplicated markers must be added under Grid")
	assert_condition(mob_marker.visible and crate_marker.visible, "Duplicated markers should be visible by default")

	# Rotation and scale behavior inside/outside grid
	player.rotation = PI / 4.0
	mob.position = player.position + Vector2(10, 10)
	minimap._process(0.016)
	assert_condition(abs(player_marker.rotation - (player.rotation + PI / 2.0)) < 0.001, "Player marker must rotate relative to player heading")
	assert_condition(mob_marker.scale.is_equal_approx(Vector2.ONE), "Marker inside grid should keep scale 1")

	mob.position = Vector2(10000, 10000)
	minimap._process(0.016)
	assert_condition(mob_marker.position.is_equal_approx(grid.size), "Marker positions must clamp to grid bounds")
	assert_condition(mob_marker.scale.is_equal_approx(Vector2(0.75, 0.75)), "Markers outside grid should scale down")

	# Zoom changes via gui_input
	var initial_zoom = minimap.zoom
	var initial_scale = minimap.grid_scale
	var event_up := InputEventMouseButton.new()
	event_up.button_index = MOUSE_BUTTON_WHEEL_UP
	event_up.pressed = true
	minimap._on_gui_input(event_up)
	assert_condition(minimap.zoom > initial_zoom, "Wheel up should increase zoom")
	assert_condition(not minimap.grid_scale.is_equal_approx(initial_scale), "grid_scale should update when zoom changes")

	var event_down := InputEventMouseButton.new()
	event_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event_down.pressed = true
	minimap._on_gui_input(event_down)
	assert_condition(minimap.zoom <= initial_zoom + 0.1, "Wheel down should reduce zoom")

	# Removal handling
	minimap._on_object_removed(crate)
	assert_condition(not minimap.markers.has(crate), "Removed object should be erased from markers")

	print("VALIDATION_PASSED: Minimap marker logic and zoom control implemented")
	get_tree().quit()
