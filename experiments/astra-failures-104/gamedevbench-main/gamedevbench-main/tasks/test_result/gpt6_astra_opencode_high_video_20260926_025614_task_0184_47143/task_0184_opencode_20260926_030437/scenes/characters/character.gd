extends CharacterBody2D

@export var damage : int
@export var health : int
@export var speed : float
@export var knockback_intensity : float = 60.0

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver := $DamageReceiver

enum State {IDLE, WALK, ATTACK, HURT}

var state := State.IDLE

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage)
	damage_receiver.damage_received.connect(on_receive_damage)
	animation_player.animation_finished.connect(on_animation_finished)

func _physics_process(delta: float) -> void:
	if state == State.HURT:
		move_and_slide()
		velocity = velocity.move_toward(Vector2.ZERO, knockback_intensity * 3.0 * delta)
		return
	if can_move():
		handle_input()
	handle_movement()
	handle_animations()
	flip_sprites()
	move_and_slide()

func handle_movement() -> void:
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK
	else:
		velocity = Vector2.ZERO

func handle_input() -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.ATTACK

func handle_animations() -> void:
	if state == State.IDLE:
		animation_player.play("idle")
	elif state == State.WALK:
		animation_player.play("walk")
	elif state == State.ATTACK:
		animation_player.play("punch")
	elif state == State.HURT:
		animation_player.play("hurt")

func flip_sprites() -> void:
	if velocity.x > 0:
		character_sprite.flip_h = false
		damage_emitter.scale.x = 1
	elif velocity.x < 0:
		character_sprite.flip_h = true
		damage_emitter.scale.x = -1

func can_move() -> bool:
	return state == State.IDLE or state == State.WALK

func can_attack() -> bool:
	return state == State.IDLE or state == State.ATTACK

func on_action_complete() -> void:
	if state == State.HURT:
		return
	state = State.IDLE

func on_emit_damage(damage_receiver: DamageReceiver) -> void:
	if state != State.ATTACK or health <= 0:
		return
	var direction := Vector2.LEFT if damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	damage_receiver.damage_received.emit(damage, direction)

func on_receive_damage(amount: int, direction: Vector2) -> void:
	if state == State.HURT or health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	state = State.HURT
	velocity = direction.normalized() * knockback_intensity
	damage_emitter.set_deferred("monitoring", false)
	animation_player.play("hurt")

func on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"hurt" and state == State.HURT:
		if health <= 0:
			queue_free()
		else:
			velocity = Vector2.ZERO
			state = State.IDLE
