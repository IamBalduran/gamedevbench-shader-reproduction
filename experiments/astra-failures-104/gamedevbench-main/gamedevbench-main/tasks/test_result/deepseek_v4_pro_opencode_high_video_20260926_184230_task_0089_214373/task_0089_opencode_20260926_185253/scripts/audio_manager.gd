extends Node

var num_players := 8
var bus := "master"

var available: Array = []
var queue: Array = []


func _ready() -> void:
	# Build pooled AudioStreamPlayers so sounds can finish after emitters free themselves.
	for i in num_players:
		var player := AudioStreamPlayer.new()
		add_child(player)
		available.append(player)
		player.finished.connect(on_stream_finished.bind(player))
		player.bus = bus


func on_stream_finished(stream: AudioStreamPlayer) -> void:
	# Return finished players to the available pool.
	available.append(stream)


func play(sound_path: String) -> void:
	queue.append(sound_path)


func _process(_delta: float) -> void:
	# Consume queued paths whenever a pooled player is free.
	if not queue.is_empty() and not available.is_empty():
		var next_player: AudioStreamPlayer = available[0]
		next_player.stream = load(queue.pop_front())
		next_player.play()
		available.pop_front()
