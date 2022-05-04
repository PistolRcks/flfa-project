# Like an Entity, but handles basic player input
extends Entity
class_name PlayerEntity

export var jump_strength = 1600			# The initial velocity of the jump 

func _physics_process(delta):
	var momentum = Vector2(0,0)
	var left = Input.is_action_pressed("p" + str(player_number) + "_left")
	var right = Input.is_action_pressed("p" + str(player_number) + "_right")
	var down = Input.is_action_pressed("p" + str(player_number) + "_down")
	var up = Input.is_action_pressed("p" + str(player_number) + "_up")
	
	
	# Process input (but only while actionable)
	if not combo_being_performed and not inactionable:
		# X Movement
		if left and right:
			velocity.x = 0
		elif left and velocity.x > -move_speed:
			momentum -= Vector2(move_speed, 0)
		elif right and velocity.x < move_speed:
			momentum += Vector2(move_speed, 0)
		
		var playback = animation_tree["parameters/playback"]
		
		
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
