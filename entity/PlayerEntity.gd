# Like an Entity, but handles basic player input
extends Entity
class_name PlayerEntity

export var jump_strength = 1600			# The initial velocity of the jump 

func _physics_process(delta):
	# Process movement, but only when a combo is not being performed
	var momentum = Vector2(0,0)
	var left = Input.is_action_pressed("left")
	var right = Input.is_action_pressed("right")
	
	# Process input
	if not combo_being_performed:
		# X Movement
		if left and right:
			velocity.x = 0
		elif left and velocity.x > -move_speed:
			momentum -= Vector2(move_speed, 0)
		elif right and velocity.x < move_speed:
			momentum += Vector2(move_speed, 0)
	
		# Jump
		if is_on_floor() and Input.is_action_pressed("up"):
			momentum += Vector2(0, -jump_strength)
	
	# Stop when we're not inputting
	if not (left or right):
		velocity.x = 0
	
	velocity += momentum
