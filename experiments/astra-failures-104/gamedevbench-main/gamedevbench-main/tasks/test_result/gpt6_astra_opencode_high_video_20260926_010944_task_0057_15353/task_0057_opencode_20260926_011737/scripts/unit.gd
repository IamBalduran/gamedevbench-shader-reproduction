extends CharacterBody2D

@export var speed: float = 100.0

var target_radius: float = 5.0
var target: Vector2 = Vector2.ZERO
var has_target: bool = false
var selected: bool = false


func _ready() -> void:
	# Each unit needs an independent shader instance so selection is per-unit.
	$Sprite2D.material = $Sprite2D.material.duplicate()
	set_selected(selected)


func _physics_process(delta: float) -> void:
	if not has_target:
		velocity = Vector2.ZERO
		return

	var distance_to_target := global_position.distance_to(target)
	if distance_to_target <= target_radius:
		has_target = false
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(target)
	var avoidance := avoid()
	if avoidance != Vector2.ZERO:
		direction = (direction + avoidance).normalized()

	velocity = direction * speed
	var motion := (velocity * delta).limit_length(distance_to_target)
	move_and_collide(motion)


func set_selected(value: bool) -> void:
	selected = value
	var material := $Sprite2D.material as ShaderMaterial
	if material:
		material.set_shader_parameter("aura_width", 1.0 if selected else 0.0)


func set_target(value: Vector2) -> void:
	target = value
	has_target = true


func avoid() -> Vector2:
	var avoidance := Vector2.ZERO
	for body: Node2D in $Detect.get_overlapping_bodies():
		if body == self:
			continue
		var offset := global_position - body.global_position
		var distance := offset.length()
		if distance > 0.0:
			avoidance += offset.normalized() / distance

	return avoidance.normalized() if avoidance != Vector2.ZERO else Vector2.ZERO
