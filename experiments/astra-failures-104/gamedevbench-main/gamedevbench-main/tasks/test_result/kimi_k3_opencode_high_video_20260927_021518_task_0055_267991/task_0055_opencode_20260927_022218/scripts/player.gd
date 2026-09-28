extends CharacterBody2D

var current_animation := "idle"
var speed := 200.0
var angle := 0

func _physics_process(delta: float) -> void:
	var mouse := get_local_mouse_position()
	var snapped_angle: float = snapped(mouse.angle(), PI / 4) / (PI / 4)
	angle = wrapi(int(snapped_angle), 0, 8)

	if Input.is_action_pressed("left_mouse") and mouse.length() > 10:
		current_animation = "run"
		velocity = mouse.normalized() * speed
	else:
		current_animation = "idle"
		velocity = Vector2.ZERO

	$AnimatedSprite2D.play(current_animation + str(angle))
	move_and_slide()
