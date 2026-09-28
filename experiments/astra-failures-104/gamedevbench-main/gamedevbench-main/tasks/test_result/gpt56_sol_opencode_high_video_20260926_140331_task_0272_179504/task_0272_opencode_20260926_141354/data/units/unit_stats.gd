class_name UnitStats
extends Resource

enum Team {PLAYER, ENEMY}

const MAX_ATTACK_RANGE := 5
const TARGET = {Team.PLAYER: "saboteurs", Team.ENEMY: "workers"}

@export var team: Team
@export_range(1, MAX_ATTACK_RANGE) var attack_range: int = 1
