class_name Character
extends CharacterBody2D

@export var damage : int
@export var knockback_intensity : float
@export var max_health : int
@export var speed : float
@export var jump_speed : float = 100.0
@export var jump_gravity : float = 300.0

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver : DamageReceiver = $DamageReceiver
@onready var grounded_sprite_y : float = $CharacterSprite.position.y

enum State {IDLE, WALK, ATTACK, HURT, TAKEOFF, JUMP, LAND}

var anim_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.ATTACK: "punch",
	State.HURT: "hurt",
	State.TAKEOFF: "takeoff",
	State.JUMP: "jump",
	State.LAND: "land",
}
var current_health := 0
var state := State.IDLE
var jump_height := 0.0
var jump_velocity := 0.0

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage.bind())
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	current_health = max_health

func _process(delta: float) -> void:
	handle_input()
	handle_movement()
	handle_jump(delta)
	handle_animations()
	flip_sprites()
	move_and_slide()

func handle_movement() -> void:
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK

func handle_input() -> void:
	if not can_move() and not can_attack():
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if can_move():
		velocity = direction * speed
	if can_attack() and Input.is_action_just_pressed("attack"):
		state = State.ATTACK
	elif can_move() and Input.is_action_just_pressed("jump"):
		state = State.TAKEOFF

func handle_jump(delta: float) -> void:
	if state != State.JUMP:
		return

	# Height is separate from movement along the ground and the shadow.
	jump_height += jump_velocity * delta - 0.5 * jump_gravity * delta * delta
	jump_velocity -= jump_gravity * delta
	if jump_height <= 0.0:
		jump_height = 0.0
		jump_velocity = 0.0
		velocity = Vector2.ZERO
		state = State.LAND
	character_sprite.position.y = grounded_sprite_y - jump_height

func handle_animations() -> void:
	if animation_player.has_animation(anim_map[state]):
		animation_player.play(anim_map[state])

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
	return state == State.IDLE or state == State.WALK

func on_action_complete() -> void:
	state = State.IDLE

func on_takeoff_complete() -> void:
	if state == State.TAKEOFF:
		jump_velocity = jump_speed
		state = State.JUMP

func on_land_complete() -> void:
	if state == State.LAND:
		character_sprite.position.y = grounded_sprite_y
		state = State.IDLE

func on_receive_damage(received_damage: int, direction: Vector2) -> void:
	current_health = clamp(current_health - received_damage, 0, max_health)
	if current_health <= 0:
		queue_free()
	else:
		jump_height = 0.0
		jump_velocity = 0.0
		character_sprite.position.y = grounded_sprite_y
		state = State.HURT
		velocity = direction * knockback_intensity

func on_emit_damage(target_damage_receiver: DamageReceiver) -> void:
	var direction := Vector2.LEFT if target_damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	target_damage_receiver.damage_received.emit(damage, direction)
