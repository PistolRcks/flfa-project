extends PlayerEntity

# Called when the node enters the scene tree for the first time.
func _ready():
	# Numpad notation:
	# 7 8 9 UL U UR
	# 4 5 6 L  N R
	# 1 2 3 DL D DR

	# There is only one attack (A). Notation is numpad notation (as described above)
	# Place combos higher to have more priority when determining which combo to perform
	combo_list = [
		Combo.new("236.?A$", "Fireball", "STAND", "GROUND", [
			{ # Quartercircle Forward + A (additional char for ease of input)
				"damage" 	: 35,
				"chip"		: 10,
				"hitstun" 	: 1,
				"blockstun" : 0.5,
				"knockback" : 1,
				"location" 	: "MID"
			}
		]),
		Combo.new("65?23.?A$", "Dragon Punch", "STAND", "GROUND", [
			{	# Z motion forward (optional neutral) + A (additional char for ease of input)
				"damage" 	: 15,
				"chip"		: 2,
				"hitstun" 	: 0.166,
				"blockstun" : 0.083,
				"knockback" : 1,
				"location" 	: "HIGH"
			}
		]),
		Combo.new("5A$", "Jab", "STAND", "STRICT", [
			{	# Just A (technically neutral A)
				"damage" 	: 6,		# Damage to deal on hit
				"chip"		: 1,		# Damage to deal on block
				"hitstun" 	: 0.067,	# Amount of time to force inactivity on hit (in sec)
				"blockstun" : 0.016,	# Amount of time to force inactivity on block (in sec)
				"knockback" : 1,		# Force of knockback to deal on hit
				"location" 	: "MID"		# The location which the hitbox targets (HIGH, MID, LOW, or UNBLOCK (unblockable))
			}
		]),
		Combo.new("[123]A$", "Sweep", "CROUCH", "STRICT", [
			{	# Any Down + A (while crouching)
				"damage" 	: 25,
				"chip"		: 5,
				"hitstun" 	: 0.25,
				"blockstun" : 0.125,
				"knockback" : 1,
				"location" 	: "LOW"
			}
		]),
		#Combo.new("5656$", "Forward Dash", "STAND", "STRICT", []),		# Doubletap Forward
	]
	
	register_combos()
