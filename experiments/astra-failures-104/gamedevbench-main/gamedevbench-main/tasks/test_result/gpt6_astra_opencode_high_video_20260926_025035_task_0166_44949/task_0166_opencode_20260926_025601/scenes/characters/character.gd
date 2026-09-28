class_name Character
extends CharacterBody2D

const GRAVITY := 600.0

@export var damage : int
@export var jump_intensity : float
@export var knockback_intensity : float
@export var max_health : int
@export var speed : float

@onready var animation_player := $AnimationPlayer
@onready var character_sprite := $CharacterSprite
@onready var damage_emitter := $DamageEmitter
@onready var damage_receiver : DamageReceiver = $DamageReceiver

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LAND, JUMPKICK, HURT, KICK}

var anim_map := {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.ATTACK: "punch",
	State.KICK: "kick",
	State.TAKEOFF: "takeoff",
	State.JUMP: "jump",
	State.LAND: "land",
	State.JUMPKICK: "jumpkick",
	State.HURT: "hurt",
}
var current_health := 0
var height := 0.0
var height_speed := 0.0
var state_time := 0.0
var state := State.IDLE

func _ready() -> void:
	damage_emitter.area_entered.connect(on_emit_damage.bind())
	damage_receiver.damage_received.connect(on_receive_damage.bind())
	current_health = max_health

func _process(delta: float) -> void:
	handle_input()
	handle_movement()
	handle_animations()
	handle_state_transitions(delta)
	handle_air_time(delta)
	flip_sprites()
	character_sprite.position = Vector2.UP * height
	move_and_slide()

func handle_movement() -> void:
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK

func handle_input() -> void:
	pass

func handle_animations() -> void:
	if animation_player.has_animation(anim_map[state]):
		animation_player.play(anim_map[state])

func handle_state_transitions(delta: float) -> void:
	if state == State.TAKEOFF:
		state_time += delta
		if state_time >= 0.05:
			on_takeoff_complete()
	elif state == State.LAND:
		state_time += delta
		if state_time >= 0.05:
			on_land_complete()

func handle_air_time(delta: float) -> void:
	if state == State.JUMP or state == State.JUMPKICK:
		height += height_speed * delta
		if height < 0:
			height = 0
			set_state(State.LAND)
		else:
			height_speed -= GRAVITY * delta

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

func can_jumpkick() -> bool:
	return state == State.JUMP

func on_action_complete() -> void:
	set_state(State.IDLE)

func on_takeoff_complete() -> void:
	set_state(State.JUMP)
	height_speed = jump_intensity

func on_land_complete() -> void:
	set_state(State.IDLE)

func on_receive_damage(received_damage: int, direction: Vector2) -> void:
	current_health = clamp(current_health - received_damage, 0, max_health)
	if current_health <= 0:
		queue_free()
	else:
		set_state(State.HURT)
		velocity = direction * knockback_intensity

func on_emit_damage(target_damage_receiver: DamageReceiver) -> void:
	var direction := Vector2.LEFT if target_damage_receiver.global_position.x < global_position.x else Vector2.RIGHT
	target_damage_receiver.damage_received.emit(damage, direction)

func set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	state_time = 0.0
