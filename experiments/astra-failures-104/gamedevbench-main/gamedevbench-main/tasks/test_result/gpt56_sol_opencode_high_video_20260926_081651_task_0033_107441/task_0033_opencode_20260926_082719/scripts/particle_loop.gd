extends Node3D

# This script continuously restarts the one-shot particle effects
# so they remain visible for demonstration and VLM analysis

var restart_timer: float = 0.0
const RESTART_INTERVAL: float = 3.5  # Slightly longer than particle lifetime

func _ready():
	# Start the particles immediately
	restart_particles()

func _process(delta):
	restart_timer += delta
	if restart_timer >= RESTART_INTERVAL:
		restart_timer = 0.0
		restart_particles()

func restart_particles():
	var arcing_chunks = $Explosion/ArcingChunks
	if arcing_chunks:
		arcing_chunks.restart()
