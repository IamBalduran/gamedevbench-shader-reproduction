extends SceneTree

func _init() -> void:
	print("MATCH_CORNERS=", TileSet.TERRAIN_MODE_MATCH_CORNERS)
	for constant in ClassDB.class_get_integer_constant_list("TileSet"):
		if "CORNER" in constant or "SIDE" in constant or "TERRAIN" in constant:
			print(constant, "=", ClassDB.class_get_integer_constant("TileSet", constant))
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_HALF_OFFSET_SQUARE
	tile_set.tile_size = Vector2i(28, 18)
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, 0, "Path")
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/sprites/tile_iso.png")
	atlas.texture_region_size = Vector2i(45, 20)
	tile_set.add_source(atlas, 1)
	atlas.create_tile(Vector2i.ZERO)
	var data := atlas.get_tile_data(Vector2i.ZERO, 0)
	data.terrain_set = 0
	data.terrain = 0
	for bit in range(16):
		if data.is_valid_terrain_peering_bit(bit):
			print("VALID BIT: ", bit)
			data.set_terrain_peering_bit(bit, 0)
	ResourceSaver.save(tile_set, "res://tmp_example.tres")
	for method in tile_set.get_method_list():
		var name: String = method["name"]
		if "terrain" in name or "source" in name:
			print(name)
	quit()
