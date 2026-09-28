extends Node2D

func _ready():
	var minimap = $CanvasLayer/Minimap
	minimap.player = $Player

	for obj in get_tree().get_nodes_in_group("minimap_objects"):
		if obj.has_signal("removed"):
			obj.removed.connect(minimap._on_object_removed.bind(obj))