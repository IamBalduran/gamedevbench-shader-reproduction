extends CharacterBody2D

var current_animation := "idle"
var speed := 200.0
var angle := 0

func _physics_process(_delta: float) -> void:
	var mouse_vector := get_local_mouse_position()
	angle = wrapi(int(round(mouse_vector.angle() / (PI / 4.0))), 0, 8)

	current_animation = "idle"
	velocity = Vector2.ZERO
	if Input.is_action_pressed("left_mouse") and mouse_vector.length() > 10.0:
		current_animation = "run"
		velocity = mouse_vector.normalized() * speed

	$AnimatedSprite2D.play(current_animation + str(angle))
	move_and_slide()
