extends SceneTree

const FULL_TILE := PackedVector2Array([
	Vector2(-9, -9),
	Vector2(9, -9),
	Vector2(9, 9),
	Vector2(-9, 9),
])

const TARGETS := [
	Vector2i(11, 6), Vector2i(12, 6),
	Vector2i(13, 4), Vector2i(13, 5), Vector2i(13, 6),
	Vector2i(14, 4), Vector2i(14, 5), Vector2i(14, 6),
	Vector2i(15, 4), Vector2i(15, 5), Vector2i(15, 6),
	Vector2i(16, 0), Vector2i(16, 1), Vector2i(16, 2), Vector2i(16, 3),
	Vector2i(17, 0), Vector2i(17, 1), Vector2i(17, 2), Vector2i(17, 3),
	Vector2i(18, 0), Vector2i(18, 1), Vector2i(18, 2), Vector2i(18, 3),
	Vector2i(19, 0), Vector2i(19, 1), Vector2i(19, 2), Vector2i(19, 3),
]

func _init() -> void:
	var tile_set := load("res://assets/tile_set.tres") as TileSet
	assert(tile_set != null)
	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	assert(atlas != null)
	for coords in TARGETS:
		var tile_data := atlas.get_tile_data(coords, 0)
		assert(tile_data != null, "Missing target tile %s" % coords)
		assert(tile_data.get_collision_polygons_count(0) == 1, "Wrong polygon count at %s" % coords)
		assert(tile_data.get_collision_polygon_points(0, 0) == FULL_TILE, "Wrong polygon at %s" % coords)
	print("Verified %d target collision polygons." % TARGETS.size())
	quit()
