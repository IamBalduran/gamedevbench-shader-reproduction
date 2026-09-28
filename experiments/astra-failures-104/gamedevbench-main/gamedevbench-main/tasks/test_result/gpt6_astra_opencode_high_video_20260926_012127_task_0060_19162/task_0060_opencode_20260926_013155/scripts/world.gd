extends Node2D

func _ready() -> void:
	var minimap = $CanvasLayer/Minimap
	minimap.player = $Player
	for object in get_tree().get_nodes_in_group("minimap_objects"):
		object.removed.connect(minimap._on_object_removed)
