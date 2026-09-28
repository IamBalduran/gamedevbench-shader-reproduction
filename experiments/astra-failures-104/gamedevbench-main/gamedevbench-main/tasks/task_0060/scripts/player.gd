extends CharacterBody2D
class_name Player

var speed := 120.0
var rotation_speed := 2.0

func _physics_process(delta):
	velocity = transform.x * speed * delta
	move_and_slide()
