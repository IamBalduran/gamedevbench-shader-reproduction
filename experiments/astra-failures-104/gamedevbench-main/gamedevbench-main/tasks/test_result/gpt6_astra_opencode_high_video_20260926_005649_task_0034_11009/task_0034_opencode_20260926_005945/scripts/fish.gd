extends CharacterBody2D

@onready var sprite_fish: Sprite2D = $SpriteFish
@onready var steer_component: Node2D = $SteerComponent

@export var max_speed: float = 120.0
@export var mass: float = 40.0

func _ready():
	if steer_component.has_method("set"):
		steer_component.set("debug_enabled", true)

func _physics_process(_delta):
	var target = get_global_mouse_position()
	if velocity.length() > 0.01:
		sprite_fish.rotation = velocity.angle()
	if steer_component.has_method("steer"):
		velocity = steer_component.steer(
			velocity,
			global_position,
			target,
			max_speed,
			mass
		)
	move_and_slide()
