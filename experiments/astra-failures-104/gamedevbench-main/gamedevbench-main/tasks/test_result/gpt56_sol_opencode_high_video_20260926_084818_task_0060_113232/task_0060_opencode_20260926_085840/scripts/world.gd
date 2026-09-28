extends Node2D

@onready var minimap = $CanvasLayer/Minimap
@onready var player: Player = $Player


func _ready() -> void:
	minimap.player = player
	for object in get_tree().get_nodes_in_group(&"minimap_objects"):
		object.removed.connect(minimap._on_object_removed)
