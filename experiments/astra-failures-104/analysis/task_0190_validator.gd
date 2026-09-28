extends Node


const EXPECTED_POINTS := [
	Vector2(-9, -9),
	Vector2(9, -9),
	Vector2(9, 9),
	Vector2(-9, 9),
]


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


func _has_expected_collision(tile_data: TileData) -> bool:
	if tile_data.get_collision_polygons_count(0) != 1:
		return false
	return tile_data.get_collision_polygon_points(0, 0) == PackedVector2Array(EXPECTED_POINTS)


func _expected_collision_tiles() -> Dictionary:
	var coords := {}
	var always_solid := [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5), Vector2i(0, 6), Vector2i(0, 7),
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7),
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(2, 4), Vector2i(2, 5), Vector2i(2, 6), Vector2i(2, 7),
		Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4), Vector2i(3, 5), Vector2i(3, 6), Vector2i(3, 7),
		Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 5),
		Vector2i(5, 0), Vector2i(5, 1),
		Vector2i(6, 0), Vector2i(6, 1),
		Vector2i(7, 2),
		Vector2i(8, 1), Vector2i(8, 2),
		Vector2i(9, 0), Vector2i(9, 1), Vector2i(9, 2),
		Vector2i(10, 0), Vector2i(10, 1), Vector2i(10, 2),
		Vector2i(11, 0), Vector2i(11, 1),
		Vector2i(12, 0),
		Vector2i(13, 0),
		Vector2i(14, 0),
		Vector2i(15, 0),
	]
	for coord in always_solid:
		coords[coord] = true

	var newly_solid := [
		Vector2i(12, 6),
		Vector2i(13, 4), Vector2i(13, 5), Vector2i(13, 6),
		Vector2i(14, 4), Vector2i(14, 5), Vector2i(14, 6),
		Vector2i(15, 4), Vector2i(15, 5), Vector2i(15, 6),
		Vector2i(16, 0), Vector2i(16, 1), Vector2i(16, 2), Vector2i(16, 3),
		Vector2i(17, 0), Vector2i(17, 1), Vector2i(17, 2), Vector2i(17, 3), Vector2i(17, 4),
		Vector2i(18, 0), Vector2i(18, 1), Vector2i(18, 2), Vector2i(18, 3),
		Vector2i(19, 0), Vector2i(19, 1), Vector2i(19, 2), Vector2i(19, 3),
	]
	for coord in newly_solid:
		coords[coord] = true
	return coords


func run_validation() -> void:
	var main := get_node_or_null("Main")
	if not _assert_or_fail(main != null, "Main node not found"):
		return

	var tile_map := main.get_node_or_null("TileMap")
	if not _assert_or_fail(tile_map != null and tile_map is TileMap, "TileMap node missing under Main"):
		return

	var tile_set: TileSet = tile_map.tile_set
	if not _assert_or_fail(tile_set != null, "TileMap must have a TileSet assigned"):
		return

	var source := tile_set.get_source(0)
	if not _assert_or_fail(source != null and source is TileSetAtlasSource, "TileSet source 0 must be a TileSetAtlasSource"):
		return
	source = source as TileSetAtlasSource

	var expected_collision_tiles := _expected_collision_tiles()

	for y in range(9):
		for x in range(20):
			var coord := Vector2i(x, y)
			var tile_data: TileData = source.get_tile_data(coord, 0)
			if not _assert_or_fail(tile_data != null, "Atlas source must define tile data for (%d, %d)" % [x, y]):
				return

			if coord in expected_collision_tiles:
				if not _assert_or_fail(_has_expected_collision(tile_data), "Solid tile (%d, %d) must use the standard full-tile collision polygon" % [x, y]):
					return
			else:
				if not _assert_or_fail(tile_data.get_collision_polygons_count(0) == 0, "Tile (%d, %d) must remain without collision" % [x, y]):
					return

	print("VALIDATION_PASSED: collision polygons are configured correctly for the newly solid tiles.")
	get_tree().quit(0)
