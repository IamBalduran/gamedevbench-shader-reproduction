extends Node2D

var left_points: int = 0
var right_points: int = 0
const MAX_POINTS: int = 11

func _ready():
	reset_points()

func reset_points():
	left_points = 0
	right_points = 0
	$LeftLabel.text = "0"
	$RightLabl.text = "0"

func _update_label(label: Label, value: int):
	label.text = str(value)
	if value >= MAX_POINTS:
		reset_points()

func handle_right_point_up():
	right_points += 1
	_update_label($RightLabl, right_points)
	new_ball(true)

func handle_left_point_up():
	left_points += 1
	_update_label($LeftLabel, left_points)
	new_ball(false)

func new_ball(right_pointed: bool):
	$Ball.reset(right_pointed)
	$Camera2D.shake(right_pointed)

func _on_right_wall_left_point_up():
	handle_left_point_up()

func _on_left_wall_right_point_up():
	handle_right_point_up()
