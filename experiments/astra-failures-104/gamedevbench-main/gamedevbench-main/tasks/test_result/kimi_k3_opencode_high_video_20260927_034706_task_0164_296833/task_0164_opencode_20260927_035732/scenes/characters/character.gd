class_name Character
extends CharacterBody2D

@export var damage : int
@export var knockback_intensity : float
@export var max_health : int
@export var speed : float

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver : DamageReceiver = $DamageReceiver

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
var jump_height : float = 0.0
var time_since_takeoff : float = 0.0
var grounded_sprite_y : float = 0.0

const JUMP_DURATION : float = 0.45
const JUMP_PEAK : float = 24.0

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage.bind())
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	current_health = max_health
	grounded_sprite_y = character_sprite.position.y

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
	if can_jump() and Input.is_action_just_pressed("jump"):
		state = State.TAKEOFF
	elif can_attack() and Input.is_action_just_pressed("attack"):
		state = State.ATTACK

func handle_jump(delta: float) -> void:
	if state == State.JUMP:
		time_since_takeoff += delta
		var t : float = clamp(time_since_takeoff / JUMP_DURATION, 0.0, 1.0)
		jump_height = sin(t * PI) * JUMP_PEAK
		character_sprite.position.y = grounded_sprite_y - jump_height
		if t >= 1.0:
			jump_height = 0.0
			character_sprite.position.y = grounded_sprite_y
			state = State.LAND
	elif state == State.TAKEOFF:
		time_since_takeoff = 0.0

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

func can_jump() -> bool:
	return state == State.IDLE or state == State.WALK

func on_action_complete() -> void:
	state = State.IDLE

func on_takeoff_complete() -> void:
	if state == State.TAKEOFF:
		time_since_takeoff = 0.0
		state = State.JUMP

func on_land_complete() -> void:
	if state == State.LAND:
		state = State.IDLE

func on_receive_damage(received_damage: int, direction: Vector2) -> void:
	current_health = clamp(current_health - received_damage, 0, max_health)
	if current_health <= 0:
		queue_free()
	else:
		state = State.HURT
		velocity = direction * knockback_intensity

func on_emit_damage(target_damage_receiver: DamageReceiver) -> void:
	var direction := Vector2.LEFT if target_damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	target_damage_receiver.damage_received.emit(damage, direction)
