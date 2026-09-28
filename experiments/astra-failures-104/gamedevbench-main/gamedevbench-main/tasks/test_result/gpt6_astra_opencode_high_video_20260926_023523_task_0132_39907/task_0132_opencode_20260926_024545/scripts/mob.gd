extends CharacterBody2D
class_name Mob

signal removed(object: Node2D)

var speed = 50
@export_enum("mob", "alert") var minimap_icon = "mob"
	
	
func _ready():
	rotation = randf_range(0, 2*PI)
	
	
func _physics_process(delta):
	velocity = transform.x * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()).rotated(randf_range(-PI/4, PI/4))
	rotation = velocity.angle()

func _exit_tree():
	removed.emit(self)
