extends CharacterBody2D

var speed := 200.0
var angle := 0

func _physics_process(delta: float) -> void:
	var mouse_vec: Vector2 = get_local_mouse_position()
	var angle_rad: float = snapped(mouse_vec.angle(), PI / 4.0)
	var stepped: int = int(round(angle_rad / (PI / 4.0)))
	var direction: int = wrapi(stepped, 0, 8)

	var anim_name: String
	if Input.is_action_pressed("left_mouse") and mouse_vec.length() > 10.0:
		anim_name = "run"
		velocity = mouse_vec.normalized() * speed
		move_and_slide()
	else:
		anim_name = "idle"
		velocity = Vector2.ZERO

	var animation: String = anim_name + str(direction)
	if $AnimatedSprite2D.animation != animation:
		$AnimatedSprite2D.play(animation)
