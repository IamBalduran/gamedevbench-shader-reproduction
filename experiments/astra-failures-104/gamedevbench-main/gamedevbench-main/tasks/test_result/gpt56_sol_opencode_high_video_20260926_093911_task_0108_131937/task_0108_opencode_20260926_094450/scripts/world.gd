extends Node2D
class_name World

enum TILE_TYPES { NONE, WATER, DIRT, GRASS }

@export var water_color: GradientTexture1D
@export var dirt_color: GradientTexture1D
@export var grass_color: GradientTexture1D

@onready var tile_map: TileMap = $TileMap
@onready var tile_gradients: Dictionary = {
	TILE_TYPES.WATER: water_color,
	TILE_TYPES.DIRT: dirt_color,
	TILE_TYPES.GRASS: grass_color,
}

static var _instance: World = null

func _ready():
	if _instance == null:
		_instance = self


static func get_tile_data_at(position: Vector2) -> TileData:
	var local_position: Vector2i = _instance.tile_map.local_to_map(position)
	return _instance.tile_map.get_cell_tile_data(0, local_position)


static func get_custom_data_at(position: Vector2, custom_data_name: String) -> Variant:
	var data = get_tile_data_at(position)
	if data == null:
		return null
	return data.get_custom_data(custom_data_name)


static func get_gradient_at(position: Vector2) -> GradientTexture1D:
	var tile_type = get_custom_data_at(position, "tile_type")
	return _instance.tile_gradients.get(tile_type)
