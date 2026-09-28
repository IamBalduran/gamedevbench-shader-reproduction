extends Node


func _ready() -> void:
	run_validation()


func _expected_vertices() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(14, 9),
		Vector2(-14, 9),
		Vector2(-14, -9),
		Vector2(14, -9),
	])


func _expected_outline() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-14, -9),
		Vector2(-14, 9),
		Vector2(14, 9),
		Vector2(14, -9),
	])


func _fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)


func _assert_or_fail(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _is_expected_navigation_polygon(polygon: NavigationPolygon) -> bool:
	if polygon == null:
		return false
	if polygon.vertices != _expected_vertices():
		return false
	if polygon.get_outline_count() != 1:
		return false
	if polygon.get_outline(0) != _expected_outline():
		return false
	return true


func _is_empty_navigation_polygon(polygon: NavigationPolygon) -> bool:
	return polygon != null and polygon.vertices.is_empty() and polygon.get_outline_count() == 0


func run_validation() -> void:
	var main := get_node_or_null("Main")
	if not _assert_or_fail(main != null, "Main node not found"):
		return

	var tile_map := main.get_node_or_null("TileMap/Base")
	if not _assert_or_fail(tile_map != null and tile_map is TileMapLayer, "TileMap/Base layer missing"):
		return

	var tile_set: TileSet = tile_map.tile_set
	if not _assert_or_fail(tile_set != null, "TileMap layer must have a TileSet assigned"):
		return
	if not _assert_or_fail(tile_set.get_navigation_layers_count() >= 1, "TileSet must define a navigation layer"):
		return
	if not _assert_or_fail(tile_set.get_navigation_layer_layers(0) == 1, "Navigation layer 0 must use navigation map layer 1"):
		return

	var source := tile_set.get_source(1)
	if not _assert_or_fail(source != null and source is TileSetAtlasSource, "TileSet source 1 must be a TileSetAtlasSource"):
		return
	source = source as TileSetAtlasSource

	var walkable_ground_tiles := {
		Vector2i(0, 0): true,
		Vector2i(1, 0): true,
		Vector2i(2, 0): true,
		Vector2i(0, 1): true,
		Vector2i(0, 2): true,
		Vector2i(1, 2): true,
		Vector2i(0, 3): true,
		Vector2i(1, 3): true,
		Vector2i(0, 4): true,
	}
	var excluded_tiles := {
		Vector2i(1, 1): true,
		Vector2i(3, 0): true,
		Vector2i(3, 1): true,
		Vector2i(3, 2): true,
	}
	var existing_tiles := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(3, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(3, 2),
		Vector2i(0, 3),
		Vector2i(1, 3),
		Vector2i(0, 4),
	]

	for coords in existing_tiles:
		var tile_data: TileData = source.get_tile_data(coords, 0)
		if not _assert_or_fail(tile_data != null, "Atlas source must define tile data for %s" % coords):
			return

		var polygon: NavigationPolygon = tile_data.get_navigation_polygon(0)
		if coords in walkable_ground_tiles:
			if not _assert_or_fail(_is_expected_navigation_polygon(polygon), "Ground tile %s must use the expected rectangular navigation polygon" % coords):
				return
		elif coords in excluded_tiles:
			if polygon != null and not _is_empty_navigation_polygon(polygon):
				if not _assert_or_fail(false, "Excluded tile %s must not have a walkable navigation polygon" % coords):
					return

	print("VALIDATION_PASSED: navigation polygons are configured correctly for the isometric ground tiles.")
	get_tree().quit(0)
