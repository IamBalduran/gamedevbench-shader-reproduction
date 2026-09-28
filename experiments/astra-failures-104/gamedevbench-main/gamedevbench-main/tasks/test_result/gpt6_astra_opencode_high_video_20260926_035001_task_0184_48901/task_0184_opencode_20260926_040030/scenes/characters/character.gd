extends CharacterBody2D

@export var damage : int
@export var health : int
@export var speed : float
@export var knockback_speed : float = 40.0

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver := $DamageReceiver

enum State {IDLE, WALK, ATTACK, HURT}

var state := State.IDLE
var remove_after_hurt := false

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage)
	damage_receiver.damage_received.connect(on_receive_damage)

func _process(_delta: float) -> void:
	handle_input()
	handle_movement()
	handle_animations()
	flip_sprites()
	move_and_slide()

func handle_movement() -> void:
	if state == State.HURT:
		return
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK
	else:
		velocity = Vector2.ZERO

func handle_input() -> void:
	if state == State.HURT:
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.ATTACK

func handle_animations() -> void:
	if state == State.IDLE:
		play_animation("idle")
	elif state == State.WALK:
		play_animation("walk")
	elif state == State.ATTACK:
		play_animation("punch")
	elif state == State.HURT:
		play_animation("hurt")

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
	if state == State.ATTACK:
		state = State.IDLE

func on_hurt_complete() -> void:
	if state != State.HURT:
		return
	if remove_after_hurt:
		queue_free()
	else:
		velocity = Vector2.ZERO
		state = State.IDLE

func play_animation(animation_name: StringName) -> void:
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)

func on_emit_damage(damage_receiver: DamageReceiver) -> void:
	var direction := Vector2.LEFT if damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	damage_receiver.damage_received.emit(damage, direction)

func on_receive_damage(received_damage: int, direction: Vector2) -> void:
	if state == State.HURT:
		return
	health -= received_damage
	state = State.HURT
	remove_after_hurt = health <= 0
	velocity = direction.normalized() * knockback_speed
	animation_player.play("hurt")
