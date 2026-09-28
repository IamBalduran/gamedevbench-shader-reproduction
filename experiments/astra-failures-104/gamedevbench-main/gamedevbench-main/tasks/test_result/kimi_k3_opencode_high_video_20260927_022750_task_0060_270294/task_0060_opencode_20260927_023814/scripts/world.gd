extends Node2D

@onready var minimap: MarginContainer = $CanvasLayer/Minimap

func _ready():
	minimap.player = $Player
	for object in get_tree().get_nodes_in_group("minimap_objects"):
		object.removed.connect(minimap._on_object_removed)
