extends Node2D

onready var p1 = $Player1
onready var p2 = $Player2

# Minimum and maximum zoom for the camera
const MIN_ZOOM = 0.15
const MAX_ZOOM = 0.5

var current_zoom = 0.15

# Distances required for zooming in/out
const MIN_ZOOM_DISTANCE = 100
const MAX_ZOOM_DISTANCE = 500

func _process(delta):
	# Resolve facing
	var p1_x = p1.position.x
	var p2_x = p2.position.x
	
	# If player 1 is to the left of player 2
	if p1_x < p2_x:
		# Player 1 should be facing right, and player 2 should be facing left
		p1.update_facing(true)
		p2.update_facing(false)
	else:
		# Otherwise it's the other way around
		p1.update_facing(false)
		p2.update_facing(true)
	
	# Place the camera in the middle, also adjust camera zoom
	$Camera.position.x = (p1_x + p2_x) / 2
	
	# Classic y = mx + b
	# Basically, we want to linearly shift between zooms of MAX_ZOOM and MIN_ZOOM, based on distance
	# It's just a clamped linear equation...
	var dist = abs(p1_x - p2_x)
	var dist_clamped = min(max(dist, MIN_ZOOM_DISTANCE), MAX_ZOOM_DISTANCE)
	var m = (MAX_ZOOM - MIN_ZOOM) / (MAX_ZOOM_DISTANCE - MIN_ZOOM_DISTANCE)
	var b = MIN_ZOOM - m * MIN_ZOOM_DISTANCE
	var zoom_mod = dist_clamped * m + b
	$Camera.zoom = Vector2(1, 1) * zoom_mod
