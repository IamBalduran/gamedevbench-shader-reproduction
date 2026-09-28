extends Area2D

@export var speed := 400.0

func _ready():
	area_entered.connect(_on_area_2d_area_entered)

func _physics_process(delta):
	position += Vector2(0, -speed) * delta
	
	# Remove the projectile once it is 50 pixels above the screen.
	if position.y < -50:
		queue_free()

func _on_area_2d_area_entered(area):
	# Check if the area that entered is an enemy
	if area.is_in_group("enemy"):
		QuestManager.progress_quest("shoot_em_up", "kill_step")
		queue_free()
