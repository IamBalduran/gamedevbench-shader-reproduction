extends SceneTree

func _init() -> void:
	var tile_set := load("res://assets/tile_set.tres") as TileSet
	print("shape=", tile_set.tile_shape, " layout=", tile_set.tile_layout, " offset=", tile_set.tile_offset_axis)
	print("valid peering bits:")
	for bit in range(16):
		if tile_set.is_valid_terrain_peering_bit(0, bit):
			print(bit)
	quit()
