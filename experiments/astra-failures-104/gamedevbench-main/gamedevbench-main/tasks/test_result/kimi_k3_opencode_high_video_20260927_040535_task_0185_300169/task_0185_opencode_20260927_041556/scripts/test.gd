extends Node


func _ready() -> void:
	run_validation()


func _fail(message: String) -> void:
	print("VALIDATION_FAILED: %s" % message)
	get_tree().quit(1)


func _assert_or_fail(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true


func _neighbor_names() -> Dictionary:
	return {
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER: "bottom_right_corner",
		TileSet.CELL_NEIGHBOR_BOTTOM_CORNER: "bottom_corner",
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER: "bottom_left_corner",
		TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER: "top_left_corner",
		TileSet.CELL_NEIGHBOR_TOP_CORNER: "top_corner",
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER: "top_right_corner",
	}


func _expected_path_tiles() -> Dictionary:
	return {
		Vector2i(0, 0): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER],
		Vector2i(1, 0): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER],
		Vector2i(2, 0): [TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER],
		Vector2i(0, 1): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
		Vector2i(1, 1): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
		Vector2i(2, 1): [TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER],
		Vector2i(0, 2): [TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
		Vector2i(1, 2): [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
		Vector2i(2, 2): [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER],
		Vector2i(0, 3): [TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
		Vector2i(1, 3): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
		Vector2i(2, 3): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER],
		Vector2i(3, 3): [],
		Vector2i(0, 4): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_CORNER],
		Vector2i(1, 4): [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
		Vector2i(2, 4): [TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
	}


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
	if not _assert_or_fail(tile_set.get_terrain_sets_count() >= 1, "TileSet must define a terrain set"):
		return
	if not _assert_or_fail(tile_set.get_terrain_set_mode(0) == TileSet.TERRAIN_MODE_MATCH_CORNERS, "Terrain set 0 must use Match Corners mode"):
		return
	if not _assert_or_fail(tile_set.get_terrains_count(0) >= 1, "Terrain set 0 must contain the Path terrain"):
		return
	if not _assert_or_fail(tile_set.get_terrain_name(0, 0) == "Path", "Terrain 0 in terrain set 0 must be named Path"):
		return

	var source := tile_set.get_source(1)
	if not _assert_or_fail(source != null and source is TileSetAtlasSource, "TileSet source 1 must be a TileSetAtlasSource"):
		return
	source = source as TileSetAtlasSource

	var expected_tiles := _expected_path_tiles()
	var neighbor_names := _neighbor_names()
	var existing_tiles := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(3, 1),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2),
		Vector2i(3, 2),
		Vector2i(0, 3),
		Vector2i(1, 3),
		Vector2i(2, 3),
		Vector2i(3, 3),
		Vector2i(0, 4),
		Vector2i(1, 4),
		Vector2i(2, 4),
		Vector2i(0, 5),
		Vector2i(1, 5),
		Vector2i(0, 6),
		Vector2i(1, 6),
		Vector2i(0, 7),
		Vector2i(1, 7),
		Vector2i(0, 8),
	]

	for coords in existing_tiles:
		var tile_data: TileData = source.get_tile_data(coords, 0)
		if not _assert_or_fail(tile_data != null, "Atlas source must define tile data for %s" % coords):
			return

		if coords in expected_tiles:
			if not _assert_or_fail(tile_data.terrain_set == 0, "Path tile %s must belong to terrain set 0" % coords):
				return
			if not _assert_or_fail(tile_data.terrain == 0, "Path tile %s must use terrain 0" % coords):
				return

			var expected_neighbors: Array = expected_tiles[coords]
			for neighbor in neighbor_names.keys():
				var expected_value := 0 if neighbor in expected_neighbors else -1
				if not _assert_or_fail(tile_data.get_terrain_peering_bit(neighbor) == expected_value, "Path tile %s has incorrect peering bit for %s" % [coords, neighbor_names[neighbor]]):
					return
		else:
			if not _assert_or_fail(tile_data.terrain_set == -1, "Non-path tile %s must not belong to the Path terrain set" % coords):
				return

	print("VALIDATION_PASSED: Path terrain is configured correctly.")
	get_tree().quit(0)
