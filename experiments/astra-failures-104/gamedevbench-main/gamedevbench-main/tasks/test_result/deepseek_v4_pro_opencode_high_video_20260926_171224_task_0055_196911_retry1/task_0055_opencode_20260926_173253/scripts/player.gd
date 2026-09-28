extends CharacterBody2D

var current_animation := "idle"
var speed := 200.0
var angle := 0

func _physics_process(delta: float) -> void:
	var mouse_pos: Vector2 = get_local_mouse_position()
	var dist: float = mouse_pos.length()
	var moving: bool = Input.is_action_pressed("left_mouse") and dist > 10.0

	if moving:
		velocity = mouse_pos.normalized() * speed
		current_animation = "run"
	else:
		velocity = Vector2.ZERO
		current_animation = "idle"

	var raw_angle: float = rad_to_deg(mouse_pos.angle())
	var snapped_angle: float = snapped(raw_angle, 45.0)
	angle = wrapi(int(snapped_angle / 45.0), 0, 8)

	$AnimatedSprite2D.play(current_animation + str(angle))

	move_and_slide()
