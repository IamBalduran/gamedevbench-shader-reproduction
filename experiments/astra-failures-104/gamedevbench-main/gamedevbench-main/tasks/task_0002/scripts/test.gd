extends Node

func _ready():
	run_validation()

func run_validation():
	var qm = _get_qm()
	qm.wipe_player_data()
	var quest_res = load("res://quests/shoot_em_up_quest.tres")
	qm.add_quest("Shoot Em Up", quest_res)
	var projectile_scene = load("res://scenes/projectile.tscn")
	var projectile = projectile_scene.instantiate()
	add_child(projectile)
	var issues = []
	projectile.position.y = -80
	projectile._physics_process(0.016)
	if not projectile.is_queued_for_deletion():
		issues.append("Projectile should free itself when leaving the play area")
	var enemy = Area2D.new()
	enemy.add_to_group("enemy")
	add_child(enemy)
	var quest = qm.get_player_quest("Shoot Em Up")
	var before = quest.quest_steps[quest.first_step].collected
	projectile = projectile_scene.instantiate()
	add_child(projectile)
	if projectile.has_method("_on_area_entered"):
		projectile._on_area_entered(enemy)
		var after = qm.get_player_quest("Shoot Em Up").quest_steps[quest.first_step].collected
		if after != before + 1:
			issues.append("Colliding with enemies must increment the kill step")
		if not projectile.is_queued_for_deletion():
			issues.append("Projectile should remove itself after damaging an enemy")
	else:
		issues.append("Projectile must react to enemies inside _on_area_entered")

	# Check UI elements exist for visual feedback
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	var ui = main.get_node_or_null("UI")
	if not ui:
		issues.append("Main scene must have a UI CanvasLayer for displaying quest progress")
	else:
		var quest_label = ui.get_node_or_null("QuestProgress")
		if not quest_label:
			issues.append("UI must have a QuestProgress Label node for displaying progress")
		elif not quest_label is Label:
			issues.append("QuestProgress must be a Label")
	main.free()

	qm.wipe_player_data()
	if issues.is_empty():
		print("VALIDATION_PASSED: Projectile updates quest steps correctly and UI is present for visual feedback")
	else:
		print("VALIDATION_FAILED: %s" % "; ".join(issues))
	get_tree().quit()

func _get_qm():
	return get_tree().root.get_node("QuestManager")
