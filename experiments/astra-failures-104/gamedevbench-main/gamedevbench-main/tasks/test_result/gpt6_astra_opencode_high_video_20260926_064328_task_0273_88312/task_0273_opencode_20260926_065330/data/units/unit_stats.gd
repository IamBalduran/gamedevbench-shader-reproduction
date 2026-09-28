class_name UnitStats
extends Resource

enum Team {PLAYER, ENEMY}

const TARGET = {Team.PLAYER: "raiders", Team.ENEMY: "sentries"}
const MAX_ATTACK_RANGE := 5

@export var team: Team
@export_range(1, MAX_ATTACK_RANGE) var attack_range: int = 1
