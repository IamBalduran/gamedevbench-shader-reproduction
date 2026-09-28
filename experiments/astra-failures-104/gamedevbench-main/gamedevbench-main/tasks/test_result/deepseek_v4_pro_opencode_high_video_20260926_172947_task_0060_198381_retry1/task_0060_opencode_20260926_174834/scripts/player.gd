extends CharacterBody2D
class_name Player

var speed := 120.0
var rotation_speed := 2.0

func _physics_process(delta):
	if Input.is_action_pressed("ui_left"):
		rotation -= rotation_speed * delta
	if Input.is_action_pressed("ui_right"):
		rotation += rotation_speed * delta
	if Input.is_action_pressed("ui_up"):
		velocity = transform.x * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()