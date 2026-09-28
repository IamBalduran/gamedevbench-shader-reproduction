extends Area2D

@export var speed := 400.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += Vector2(0, -speed) * delta

	if not get_viewport_rect().grow(50.0).has_point(global_position):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		get_node("/root/QuestManager").progress_quest("shoot_em_up", "kill_step")
		queue_free()
