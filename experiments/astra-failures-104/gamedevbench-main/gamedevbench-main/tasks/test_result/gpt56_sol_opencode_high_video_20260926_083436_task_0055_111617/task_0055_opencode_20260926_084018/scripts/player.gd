extends CharacterBody2D

var current_animation := "idle0"
var speed := 200.0
var angle := 0

func _physics_process(delta: float) -> void:
	var mouse_vector := get_local_mouse_position()
	if mouse_vector.length() > 0.0:
		angle = wrapi(roundi(mouse_vector.angle() / (TAU / 8.0)), 0, 8)

	var is_running := Input.is_action_pressed("left_mouse") and mouse_vector.length() > 10.0
	var animation_prefix := "run" if is_running else "idle"
	var animation_name := animation_prefix + str(angle)
	if animation_name != current_animation:
		current_animation = animation_name
		$AnimatedSprite2D.play(current_animation)

	if is_running:
		velocity = mouse_vector.normalized() * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
