extends Node2D

@export var projectile_scene: PackedScene

func _get_spawning_points() -> Node:
    return get_node_or_null("SpawningPoints")

func _get_markers() -> Array:
    var holder = _get_spawning_points()
    if holder:
        return holder.get_children()
    return []

func activate():
    if not projectile_scene:
        return
    for spawn in _get_markers():
        if spawn:
            var instance = projectile_scene.instantiate()
            spawn.call_deferred("add_child", instance)
