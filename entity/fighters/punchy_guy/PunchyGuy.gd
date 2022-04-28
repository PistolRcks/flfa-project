extends PlayerEntity

# Called when the node enters the scene tree for the first time.
func _ready():
	# Numpad notation:
	# 7 8 9 UL U UR
	# 4 5 6 L  N R
	# 1 2 3 DL D DR

	# Attacks are A and B (G stands for both A and B). Notation is numpad notation
	# Input combos higher to have more priority
	combo_list = [
		["236.?A$", "Fireball"],		# Quartercircle Forward + A (additional char for ease of input)
		["65?23.?A$", "Dragon Punch"],	# Z motion forward (optional neutral) + A (additional char for ease of input)
		["G$", "Forward Grab"],
		["5A$", "Punch"],				# Just A (technically neutral A)
		["6A$", "lmao 6P reference"],	# Forward + A
		["2A$", "Dickpunch (yes that's really what it's called in Tekken)"],	# Down + A (yes that is actually what it is called)
		["5656$", "Forward Dash"],		# Doubletap Forward
	]
	
	register_combos()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
