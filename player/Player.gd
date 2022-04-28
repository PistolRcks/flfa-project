extends KinematicBody2D

## Combos ##
# Numpad notation:
# 7 8 9 UL U UR
# 4 5 6 L  N R
# 1 2 3 DL D DR

# Attacks are A and B (G stands for both A and B). Notation is numpad notation
# Input combos higher to have more priority
var combo_list = [
	["236.?A$", "Fireball"],		# Quartercircle Forward + A (additional char for ease of input)
	["65?23.?A$", "Dragon Punch"],	# Z motion forward (optional neutral) + A (additional char for ease of input)
	["G$", "Forward Grab"],
	["5A$", "Punch"],				# Just A (technically neutral A)
	["6A$", "lmao 6P reference"],	# Forward + A
	["2A$", "Dickpunch (yes that's really what it's called in Tekken)"],	# Down + A (yes that is actually what it is called)
	["5656$", "Forward Dash"],		# Doubletap Forward
]
onready var combo_controller = $ComboController

## Hitboxes ##
onready var hitbox_scene = load("res://util/hitbox/Hitbox.tscn")
var hitboxes = []

## Character States ##
var facing_right = true					# Direction we're facing (normally right)
var combo_being_performed = false		# If a combo is currently being performed

## Character Stats ##
export var max_health = 100				# The maximum health of the character
var current_health
export var move_speed = 100				# The speed of movement (in pixels/sec)


func _ready():
	current_health = max_health + 0		# Duplicate but not
	for combo in combo_list:
		combo_controller.register_combo(combo)

func _physics_process(delta):
	# Process movement
	var momentum = Vector2(0,0)
	var left = Input.is_action_pressed("left")
	var right = Input.is_action_pressed("right")
	
	if left and right:
		pass
	elif left:
		momentum -= Vector2(move_speed * delta, 0)
	elif right:
		momentum += Vector2(move_speed * delta, 0)
	
	# Apply momentum
	print(move_and_collide(momentum))

""" Creates a new Hitbox.

	Ideally, this is performed by an animation. In the previous game this was snatched from,
	there were design documents detailing `team` and `metadata`, but those are not currently
	present for this game.
	
	Parameters:
		`Vector2` global_coord - The global coordinates where the hitbox will be 
			placed (NB: the coordinate is located at the center!)
		`Vectpr2` size - The size of the Hitbox.
		`int` team - The team the Hitbox is on. 
		`Dictionary` metadata - The metadata of the Hitbox.
"""
func create_hitbox(global_coord : Vector2, size : Vector2, team : int, 
		metadata : Dictionary):
	var new_instance : Hitbox = hitbox_scene.instance()
	
	hitboxes.append(new_instance)
	# TODO: Maybe this should be a child of any node? Could child it to
	# the player then, and then you wouldn't have to deal with global coords
	# Probably shouldn't even be instanced where the Weapon is, since the 
	# position will be moved with the parent
	add_child_below_node($Hitboxes, new_instance)
	
	# Set exports
	new_instance.debugColor = Color(1.0, 0.0, 0.0, 0.5)
	new_instance.type = "HIT"
	new_instance.team = team
	new_instance.metadata = metadata.duplicate() # Fuckin GDScript with by-reference assignment (duplicate performs by-value assignment)
	new_instance.metadata["source"] = get_path()	# Automatically set source
	
	# Not going to use Hitbox::setSize since scaling makes the positioning much
	# nicer. Size is divided by 20 due to the extents of the Hitbox's underlying
	# CollisionShape being 10x10 (multiplied by 2, since extents are kinda like
	# radius)
	new_instance.scale = size/20
	new_instance.global_position = global_coord

""" Creates a hitbox with a specific `Area2D`'s global position and size.
	
	Parameters:
		`String` area_nodepath - The GLOBAL NodePath to the Area2D to copy from,
			OR the NodePath relative to the Weapon.
			(Can't use actual NodePath because it's local to the Player when I
			call it from the animation)
		`int` team - The team the Hitbox is on.
		`Dictionary` metadata - The metadata of the Hitbox.
"""
func create_hitbox_with_nodepath(area_nodepath : String, team : int, metadata : Dictionary):
	var area = get_node(area_nodepath)
	create_hitbox(area.global_position, area.scale, team, metadata)

func _on_ComboController_combo_performed(combo, player):
	# Perform animation here...
	pass
