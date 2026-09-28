class_name Player
extends Character

func handle_input() -> void:
	if state == State.JUMP and Input.is_action_just_pressed("attack"):
		set_state(State.JUMPKICK)
		return

	if not can_move() and not can_attack():
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if can_move():
		velocity = direction * speed
		if Input.is_action_just_pressed("jump"):
			set_state(State.TAKEOFF)
			return
	if can_attack() and Input.is_action_just_pressed("attack"):
		if state == State.WALK:
			set_state(State.KICK)
			velocity = Vector2.ZERO
		else:
			set_state(State.ATTACK)
