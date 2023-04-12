# Global variables/constants for gameplay
extends Node


# Debug variables
""" Whether or not to show hitboxes (the boxes created by combos which deal damage). """
var SHOW_HITBOXES = false

""" Whether or not to show hurtboxes (the boxes attached to entities which recieve damage). """
var SHOW_HURTBOXES = false

""" How long (in seconds) for rounds to last before issuing a draw on timeout. 
	Set as `-1` for infinite round lengths.
"""
var ROUND_LENGTH = -1

# Some all-purpose functions
func _process(delta):
	# Enable/disable hitboxes
	if Input.is_action_just_pressed("show_hitboxes"):
		SHOW_HITBOXES = not SHOW_HITBOXES
		get_tree().call_group("hitboxes", "setVisibility", SHOW_HITBOXES, "HIT")
	elif Input.is_action_just_pressed("show_hurtboxes"):
		SHOW_HURTBOXES = not SHOW_HURTBOXES
		get_tree().call_group("hitboxes", "setVisibility", SHOW_HURTBOXES, "HURT")
