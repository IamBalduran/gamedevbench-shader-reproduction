extends Control

signal reparent_requested(which_card_ui)

@export var card_title := "Card" : set = _set_card_title

@onready var panel := $Panel
@onready var title_label := $Title
@onready var state_label := $State
@onready var drop_point_detector := $DropPointDetector
@onready var card_state_machine := $CardStateMachine

var targets: Array[Node] = []
var original_index := 0
var home_parent: Control
var tween: Tween


func _ready() -> void:
	card_state_machine.init(self)


func _input(event: InputEvent) -> void:
	card_state_machine.on_input(event)


func _on_gui_input(event: InputEvent) -> void:
	card_state_machine.on_gui_input(event)


func _on_mouse_entered() -> void:
	card_state_machine.on_mouse_entered()


func _on_mouse_exited() -> void:
	card_state_machine.on_mouse_exited()


func animate_to_position(new_position: Vector2, duration: float) -> void:
	tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", new_position, duration)


func play() -> void:
	queue_free()


func _set_card_title(value: String) -> void:
	card_title = value
	if not is_node_ready():
		await ready

	title_label.text = card_title


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)


func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)