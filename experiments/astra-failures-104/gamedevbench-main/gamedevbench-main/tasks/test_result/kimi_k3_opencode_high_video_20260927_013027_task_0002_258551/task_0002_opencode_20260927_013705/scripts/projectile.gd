extends Area2D

@export var speed := 400.0

func _ready():
	# Connect the overlap signal so the projectile reacts when it hits an enemy.
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	position += Vector2(0, -speed) * delta

	# Remove the projectile if it travels far off screen (50 pixels past any edge).
	var viewport_size = get_viewport_rect().size
	if position.y < -50 or position.y > viewport_size.y + 50 \
		or position.x < -50 or position.x > viewport_size.x + 50:
		queue_free()

func _on_area_entered(area):
	# Check if the overlapped area is an enemy.
	if area.is_in_group("enemy"):
		# Advance the Shoot Em Up quest's kill step.
		QuestManager.progress_quest("shoot_em_up", "kill_step")
		# Remove the projectile after the hit.
		queue_free()
