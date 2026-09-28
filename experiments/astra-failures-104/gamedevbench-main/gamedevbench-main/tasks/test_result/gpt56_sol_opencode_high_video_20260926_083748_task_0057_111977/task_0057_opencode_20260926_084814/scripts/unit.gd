extends CharacterBody2D

@export var speed: float = 100.0

var target_radius: float = 10.0
var target: Variant = null
var selected: bool = false


func _ready() -> void:
	$Sprite2D.material = $Sprite2D.material.duplicate()
	set_selected(false)


func set_selected(value: bool) -> void:
	selected = value
	var material := $Sprite2D.material as ShaderMaterial
	if material:
		material.set_shader_parameter("aura_width", 1.0 if selected else 0.0)


func set_target(value: Variant) -> void:
	target = value


func avoid() -> Vector2:
	var avoidance := Vector2.ZERO
	for body in $Detect.get_overlapping_bodies():
		if body == self:
			continue
		var offset: Vector2 = global_position - body.global_position
		var distance := offset.length()
		if distance > 0.0:
			avoidance += offset.normalized() * (1.0 - min(distance / $Detect/CollisionShape2D.shape.radius, 1.0))
	return avoidance


func _physics_process(delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		return

	var target_position: Vector2
	if target is Node2D:
		target_position = target.global_position
	else:
		target_position = target

	var distance := global_position.distance_to(target_position)
	if distance <= target_radius:
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(target_position)
	var movement := direction + avoid()
	velocity = movement.normalized() * speed
	move_and_collide(velocity * delta)
