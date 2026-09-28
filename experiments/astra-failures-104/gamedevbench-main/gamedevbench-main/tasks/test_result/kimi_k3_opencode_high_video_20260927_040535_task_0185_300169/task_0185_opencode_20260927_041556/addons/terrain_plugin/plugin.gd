@tool
extends EditorPlugin

const PATH := 0
const GRASS := -1

func _set_bits(td: TileData, tl, tr, br, bl) -> void:
	td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, tl)
	td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, tr)
	td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, br)
	td.set_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, bl)

func _enter_tree() -> void:
	var ts: TileSet = load("res://assets/tile_set.tres")
	if ts == null:
		push_error("Failed to load tileset")
		return

	# Create terrain set 0 in Match Corners mode.
	ts.add_terrain_set(0)
	ts.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)

	# Single terrain named "Path".
	ts.add_terrain(0)
	ts.set_terrain_name(0, 0, "Path")
	ts.set_terrain_color(0, 0, Color(0.62, 0.39, 0.22, 1.0))

	var source: TileSetAtlasSource = ts.get_source(1)
	if source == null:
		push_error("Source 1 not found")
		return

	# Grass default tile (full-grass surroundings).
	var gtd: TileData = source.get_tile_data(Vector2i(0, 8), 0)
	gtd.terrain = GRASS
	_set_bits(gtd, GRASS, GRASS, GRASS, GRASS)

	# 15 autotile path tiles: [atlas_coords, TL, TR, BR, BL]
	var entries := [
		[Vector2i(0, 2),  1, 0, 0, 0],
		[Vector2i(1, 0),  0, 1, 0, 0],
		[Vector2i(2, 0),  1, 1, 0, 0],
		[Vector2i(1, 2),  0, 1, 0, 1],
		[Vector2i(2, 1),  1, 0, 1, 0],
		[Vector2i(0, 0),  1, 1, 1, 1],
		[Vector2i(0, 4),  0, 0, 1, 1],
		[Vector2i(1, 4),  1, 1, 0, 0],
		[Vector2i(2, 3),  1, 0, 0, 0],
		[Vector2i(2, 2),  0, 0, 1, 0],
		[Vector2i(0, 5),  0, 1, 1, 0],
		[Vector2i(1, 6),  0, 0, 0, 1],
		[Vector2i(0, 7),  0, 1, 0, 0],
		[Vector2i(0, 6),  1, 1, 0, 1],
		[Vector2i(1, 7),  1, 0, 0, 1],
	]

	for e in entries:
		var td: TileData = source.get_tile_data(e[0], 0)
		if td == null:
			push_error("No tile data at %s" % e[0])
			continue
		td.terrain = PATH
		_set_bits(td, e[1], e[2], e[3], e[4])

	var err := ResourceSaver.save(ts, "res://assets/tile_set.tres")
	if err != OK:
		push_error("Save failed: %s" % err)
	else:
		print("TERRAIN_APPLY_OK")
