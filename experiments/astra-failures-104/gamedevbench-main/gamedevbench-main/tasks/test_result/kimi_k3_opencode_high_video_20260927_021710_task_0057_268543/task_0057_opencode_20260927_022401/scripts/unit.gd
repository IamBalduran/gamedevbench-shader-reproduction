extends CharacterBody2D

## Movement speed in pixels per second.
@export var speed := 60.0

## Distance to the target position at which the unit stops moving.
var target_radius := 4.0

## World position this unit is moving toward.
var target := Vector2.ZERO

## Whether this unit is currently selected (aura highlight visible).
var selected := false


func _ready() -> void:
	# Give each unit instance its own ShaderMaterial so that toggling the
	# aura highlight on one unit does not affect the others.
	$Sprite2D.material = $Sprite2D.material.duplicate()
	target = global_position
	set_selected(selected)


## Toggles the selection aura shader highlight.
func set_selected(value: bool) -> void:
	selected = value
	var mat := $Sprite2D.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("aura_width", 1.0 if selected else 0.0)


## Sets the position this unit should move toward.
func set_target(value: Vector2) -> void:
	target = value


func _physics_process(_delta: float) -> void:
	if global_position.distance_to(target) > target_radius:
		var direction := global_position.direction_to(target)
		var motion := (direction * speed + avoid()) * _delta
		move_and_collide(motion)


## Returns a steering offset that pushes this unit away from any other
## bodies overlapping the Detect area.
func avoid() -> Vector2:
	var steering := Vector2.ZERO
	for body in $Detect.get_overlapping_bodies():
		if body != self:
			steering -= global_position.direction_to(body.global_position) * speed
	return steering
