# Like an Entity, but handles basic player input
extends Entity
class_name PlayerEntity

""" Returns the local input that this node needs to operate. 
	
	This will only be called for nodes whose "network master"
	(set via `Node.set_network_master()`) matches the peer id of the current
	client. Not all nodes need input, in fact, most do not. This is used most
	commonly on the node representing a player. This input will be passed into
	`_network_process()`.
"""
func _get_local_input() -> Dictionary:
	var left = false
	var right = false
	var down = false
	var up = false
	var a = false
	
	# Inputs should be based on the controller, not the player number
	# These will be the same in a local scenario, but not necessarily in an
	# online scenario
	if (controller <= 1):
		left = Input.is_action_pressed("p" + str(controller + 1) + "_left")
		right = Input.is_action_pressed("p" + str(controller + 1) + "_right")
		down = Input.is_action_pressed("p" + str(controller + 1) + "_down")
		up = Input.is_action_pressed("p" + str(controller + 1) + "_up")
		a = Input.is_action_pressed("p" + str(controller + 1) + "_attack_a")
	
	return {
		left = left, 
		right = right, 
		down = down, 
		up = up,
		a = a
	}

""" Processes this node for the current tick. 

	The input will contain data from either `_get_local_input()`
	(if it's real user input) or `_predict_remote_input()` (if it's predicted).
	If this node doesn't implement those methods, it'll always be empty.
"""
func _network_process(input : Dictionary) -> void:
	# Call the parent (because parent virtuals don't get automatically called like with builtin virtuals) 
	._network_process(input)
	
	var left = input.get("left")
	var right = input.get("right")
	var up = input.get("up")
	var down = input.get("down")
	
	var delta = 1.0 / physics_fps
	var momentum = Vector2(0,0)
	
	# Process input (but only while actionable, and alive)
	if not combo_being_performed and not inactionable and not dead:
		# X Movement
		if left and right:
			velocity.x = 0
		elif left and velocity.x > -move_speed:
			momentum -= Vector2(move_speed, 0)
		elif right and velocity.x < move_speed:
			momentum += Vector2(move_speed, 0)
		
		# Crouching
		if not in_air and down:
			crouching = true
			# Travel to crouching state if need be
			if playback.get_current_node() == "stand":
				playback.travel("crouch")
		# Change state if we released the key while in crouchstate
		elif playback.get_current_node() == "crouch" and not down:
			playback.travel("stand")
		# Don't need to change state, and not pressing down
		# Technically, the character is still crouching until in the stand state
		else:
			crouching = false
	
		# Blocking (facing away)
		if ((left and facing_right) or (right and not facing_right)) \
				and not in_air:
			blocking = true
		else:
			blocking = false
	
		# Jump
		if not in_air and up:
			momentum += Vector2(0, -jump_strength)
	
	# Stop when we're not inputting
	if not (left or right):
		velocity.x = 0
	
	velocity += momentum
	
	# Now, process combos
	combo_controller._process_combos(input)
