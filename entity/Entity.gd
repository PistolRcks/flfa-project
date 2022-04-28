extends KinematicBody2D
class_name Entity

## Combos ##
var combo_list = []
onready var combo_controller = $ComboController

const GRAVITY = 200		# Speed of gravity (in pixels/sec); always at max

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
export var jump_strength = 1600			# The initial velocity of the jump 
var velocity = Vector2(0,0)

func _ready():
	current_health = max_health + 0		# Duplicate but not

func _physics_process(delta):
	var momentum = Vector2()
	# Apply gravity while not on floor (and we're not moving faster than gravity)
	if not is_on_floor() and velocity.y < GRAVITY:
		momentum += Vector2(0, GRAVITY)
	
	velocity += momentum
	# Apply momentum
	move_and_slide(velocity, Vector2(0, -1))

""" Registers all combos from `combo_list` into the ComboController.
"""
func register_combos():
	for combo in combo_list:
		combo_controller.register_combo(combo)

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
	print("Performed combo " + combo)
