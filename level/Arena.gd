extends Node2D

onready var p1 = $Player1
onready var p2 = $Player2

func _ready():
	pass # Replace with function body.

func _process(delta):
	# Resolve facing
	# If player 1 is to the left of player 2
	if p1.position.x < p2.position.x:
		# Player 1 should be facing right, and player 2 should be facing left
		p1.update_facing(true)
		p2.update_facing(false)
	else:
		# Otherwise it's the other way around
		p1.update_facing(false)
		p2.update_facing(true)
