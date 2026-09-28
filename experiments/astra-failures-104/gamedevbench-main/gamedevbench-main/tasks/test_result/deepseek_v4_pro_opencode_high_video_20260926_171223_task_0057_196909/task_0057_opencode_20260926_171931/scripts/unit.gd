extends CharacterBody2D

@export var speed: float = 100.0
var target_radius: float = 10.0
var target: Vector2

func _ready():
	target = global_position
	$Sprite2D.material = $Sprite2D.material.duplicate()

func set_selected(selected: bool):
	$Sprite2D.material.set_shader_parameter("aura_width", 1.0 if selected else 0.0)

func set_target(new_target: Vector2):
	target = new_target

func _physics_process(delta: float):
	var direction = target - global_position
	if direction.length() > target_radius:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
	avoid()
	move_and_collide(velocity * delta)

func avoid():
	var bodies = $Detect.get_overlapping_bodies()
	for body in bodies:
		if body != self:
			var direction = global_position - body.global_position
			if direction.length() > 0:
				velocity += direction.normalized() * speed * 0.5