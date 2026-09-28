extends SceneTree


func _initialize() -> void:
	var scene := load("res://scenes/Player.tscn") as PackedScene
	assert(scene != null)
	var player := scene.instantiate()
	assert(player is Area2D)
	var sprite := player.get_node("Sprite2d") as Sprite2D
	assert(sprite != null and sprite.hframes == 6 and sprite.vframes == 4)
	assert(sprite.texture.resource_path == "res://assets/sokoban_character.png")
	var collision := player.get_node("CollisionShape2d") as CollisionShape2D
	assert(collision != null and collision.shape is RectangleShape2D)
	assert((collision.shape as RectangleShape2D).size == Vector2(64, 64))
	var ray := player.get_node("RayCast2d") as RayCast2D
	assert(ray != null and ray.collide_with_areas)
	var animation_player := player.get_node("AnimationPlayer") as AnimationPlayer
	assert(animation_player != null)
	var expected := {
		"down": [0, 1, 2, 3, 4, 5],
		"up": [6, 7, 8, 9, 10, 11],
		"left": [12, 13, 14, 15, 16, 17],
		"right": [18, 19, 20, 21, 22, 23],
	}
	for animation_name: String in expected:
		assert(animation_player.has_animation(animation_name))
		var animation := animation_player.get_animation(animation_name)
		assert(animation.get_track_count() == 1)
		assert(animation.track_get_path(0) == NodePath("Sprite2d:frame"))
		assert(animation.track_get_key_count(0) == 6)
		for key in 6:
			assert(animation.track_get_key_value(0, key) == expected[animation_name][key])
	print("Player scene validation passed")
	quit()
