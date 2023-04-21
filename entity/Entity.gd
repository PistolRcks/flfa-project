# Takes damage, deals damage, is affected by gravity. Basis for player characters (PlayerEntity).
# See PlayerEntity for more info on player characters. 
extends KinematicBody2D
class_name Entity

## Combos ##
var combo_list = []
onready var combo_controller : ComboController = $MovementHelper/ComboController

const GRAVITY = 200		# Speed of gravity (in pixels/sec); always at max

## Hitboxes ##
onready var hitbox_scene = load("res://util/hitbox/Hitbox.tscn")
var hitboxes = []

## Character States ##
var facing_right = true						# Direction we're facing (normally right)
export var combo_being_performed = false	# If a combo is currently being performed
var blocking = false						# Whether or not the player is able to block 
											# (i.e., holding back; not in blockstun)
var inactionable = false					# Whether or not the entity can perform any actions 
											# (usually while in hit/blockstun)
var crouching = false						# Whether or not the entity is crouching
var in_air = true							# Whether or not the entity is in the air
var dead = false							# Whether the character is dead or not

## Animation ##
onready var animation_tree = $MovementHelper/AnimationTree
onready var playback = animation_tree["parameters/playback"]	# Root playback node of animation tree

## Character Stats ##
export var player_number = 1		# Which number the player is (1 or 2)
# Whether the entity is controlled by a player, the server, or by AI.
export(int, "P1", "P2", "Server", "AI") var controller = 0
export var full_name = "Fighter"	# The full name of the character (as displayed in the UI)
export var max_health = 100			# The maximum health of the character
var current_health
export var move_speed = 100			# The speed of movement (in pixels/sec)
export var jump_strength = 800		# The initial velocity of the jump 
var velocity = Vector2(0,0)
var stun_timer := 0.0				# How long the character is inactionable after being hit

## Other ##
var physics_fps = ProjectSettings.get_setting("physics/common/physics_fps")

## Signals ##
signal on_death(player)		# Fired when a player dies. Tells which player died.

func _ready():
	current_health = max_health + 0		# Duplicate but not
	
	# Update UI to reflect character
	get_tree().call_group("combat_ui", "update_name", player_number, full_name)
	get_tree().call_group("combat_ui", "update_health", player_number, 100)
	
	# Let the ComboController know which player we are
	combo_controller.update_assigned_player(player_number)
	update_combo_controller(controller if controller <= 1 else -1)
	
	# Make sure the hurtboxes are on the correct team
	for hurtbox in $MovementHelper/Hurtboxes.get_children():
		hurtbox.team = player_number
	
	# Add to `network_sync` to apply rollback
	add_to_group("network_sync")

## Rollback Virtual Methods ##
""" Returns the current node state.
	
	This same state will be passed to `_load_state()` when performing a rollback.
"""
func _save_state() -> Dictionary:
	return {
		pos_x = position.x,
		pos_y = position.y,
		vel_x = velocity.x,
		vel_y = velocity.y,
		cur_health = current_health,
		stun = stun_timer,
		facing_right = facing_right,
		combo_being_performed = combo_being_performed,
		blocking = blocking,
		inactionable = inactionable,
		crouching = crouching,
		in_air = in_air,
		dead = dead
	}

""" Called to roll the node back to a previous state, 
	which originated from this node's `_save_state()` method.
"""
func _load_state(state: Dictionary) -> void:
	position.x = state["pos_x"]
	position.y = state["pos_y"]
	velocity.x = state["vel_x"]
	velocity.y = state["vel_y"]
	current_health = state["cur_health"]
	stun_timer = state["stun"]
	update_facing(state["facing_right"])
	combo_being_performed = state["combo_being_performed"]
	blocking = state["blocking"]
	inactionable = state["inactionable"]
	crouching = state["crouching"]
	in_air = state["in_air"]
	dead = state["dead"]


""" Processes this node for the current tick. 

	The input will contain data from either `_get_local_input()`
	(if it's real user input) or `_predict_remote_input()` (if it's predicted).
	If this node doesn't implement those methods, it'll always be empty.
"""
func _network_process(input: Dictionary) -> void:
	var delta = 1.0 / physics_fps
	var momentum = Vector2()
	# Apply gravity while not on floor (and we're not moving faster than gravity)
	if not is_on_floor() and velocity.y < GRAVITY:
		momentum += Vector2(0, GRAVITY)
	
	in_air = not is_on_floor()
	
	# Run stun timer down
	if stun_timer > 0:
		stun_timer -= delta
		inactionable = true
	else:
		# Move to the state we should be in again
		if playback.get_current_node() in ["hitstun", "blockstun"]:
			if in_air:
				playback.travel("air")
			elif crouching:
				playback.travel("crouch")
			else:	# Standing is neither in-air or crouching
				playback.travel("stand")
		inactionable = false
	
	# Die if you have no health
	if current_health <= 0:
		# Fire signal when we die (dead variable hasn't been set yet if it's the first time)
		if not dead:
			emit_signal("on_death", player_number)
		
		dead = true
		inactionable = true
		visible = false		# If I work on this in the future, a proper death anim would be good
	
	velocity += momentum
	# Apply momentum
	move_and_slide(velocity, Vector2(0, -1))

""" Returns predicted remote input based on the input from the previous tick,
	which may itself be predicted. 

	This will only be called for nodes whose
	"network master" DOES NOT match the peer id of the current client. If this
	method isn't provided, the same input from the last tick will be used as-is.
	This input will be passed into `_network_process()` when using predicted
	input. If `ticks_since_real_input` is negative, we haven't received any remote
	inputs yet, which happens at the very start of the game.
"""
#func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
#	return {}	# Stub!

## Getters ##
func get_combo_controller() -> ComboController:
	return (combo_controller as ComboController)

## Setters ##
""" Sets a new name for the Entity; also updates the CombatUI to reflect this.
"""
func set_name(new_name : String):
	full_name = new_name
	get_tree().call_group("combat_ui", "update_name", player_number, full_name)

## Combos ##
# Lets the ComboController know who is controlling it
# The ComboController will always be controlled by `player_number`.
func update_combo_controller(new_controller : int):
	if new_controller <= 1:
		print("Setting combo controller for player " + String(player_number) + " to " + String(new_controller))
		combo_controller.update_controlling_player(new_controller + 1)
	else:
		# The computer should handle this
		combo_controller.update_controlling_player(-1)

""" Registers all combos from `combo_list` into the ComboController.
"""
func register_combos():
	for combo in combo_list:
		combo_controller.register_combo(combo)

## Hitboxes ##
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
	add_child_below_node($MovementHelper/Hitboxes, new_instance)
	
	# Set exports
	new_instance.debugColor = Color(1.0, 0.0, 0.0, 0.5)
	new_instance.type = "HIT"
	new_instance.team = team
	new_instance.metadata = metadata.duplicate() # Fuckin GDScript with by-reference assignment (duplicate performs by-value assignment)
	new_instance.metadata["source"] = get_path()	# Automatically set source
	
	new_instance.scale = size
	new_instance.global_position = global_coord

""" Creates a hitbox with a specific `Area2D`'s global position and size.
	
	Parameters:
		`NodePath` area_nodepath - The nodepath to an Area2D.
			(Can't use actual NodePath because it's local to the Player when I
			call it from the animation)
		`Dictionary` metadata - The metadata of the Hitbox.
"""
func create_hitbox_with_nodepath(area_nodepath : NodePath, metadata : Dictionary):
	var area = get_node(area_nodepath)
	create_hitbox(area.global_position, area.scale, player_number, metadata)

""" Creates a hitbox with a specific `Area2D`'s global position and size. Metadata is filled based
	on which combo is currently being performed, and which hitbox to produce in that animation.
	
	NB: The metadata should already exist for that specific combo, or else an IndexError is thrown.
	
	Parameters:
		`NodePath` area_nodepath - The nodepath to an Area2D.
			(Can't use actual NodePath because it's local to the Player when I
			call it from the animation)
		`int` combo_idx - The index of the combo (from `combo_list`) which is currently
			being performed.
		`int` meta_idx - The index of the metadata for this hitbox (the third portion of the 
			combo tuple). This should be the number of the hitbox being produced by this animation
			(i.e. 1 for the first hitbox, 2 for the second, etc.)
"""
func create_hitbox_via_combo(area_nodepath: NodePath, combo_idx: int, meta_idx: int):
	create_hitbox_with_nodepath(area_nodepath, combo_list[combo_idx].metas[meta_idx])

""" Removes all hitboxes produced by this entity. """
func remove_all_hitboxes():
	for hitbox in hitboxes:
		if hitbox: # Make sure the hitbox hasn't been cleared already
			hitbox.queue_free()
	
	# Empty the array
	hitboxes.clear()

## Other Gameplay ##
""" Updates assets to reflect facing.
	Call this instead of updating `facing_right`.

	Parameters:
		`bool` new_facing - Whether or not the player is facing right 
			(i.e. true = facing right; false = facing left).
"""
func update_facing(new_facing: bool):
	if new_facing != facing_right:
		# Flip asset
		scale.x *= -1
		combo_controller.inputs_flipped = not combo_controller.inputs_flipped
	
	facing_right = new_facing

func apply_knockback(amount):
	pass # STUB!

## Process Handling ##
""" Stops all `*_process` functions for the Entity and its ComboController. 
	Called when the Entity dies. 
"""
func stop_all_processes():
	combo_controller.set_process(false)
	set_process(false)
	set_physics_process(false)

func resume_all_processes():
	combo_controller.set_process(true)
	set_process(true)
	set_physics_process(true)

## Signal Handlers ##
# Perform animations if combos are performed
func _on_ComboController_combo_performed(combo_idx, combo):
	# Only perform combos if one isn't already being performed (also if we can do stuff)
	if not combo_being_performed and not inactionable:
		# Get current state
		var state = playback.get_current_node()	
		
		# "Cheat" which state we're in based on combo lenience (see Combo.gd)
		if (combo.lenience == "GROUND" and state in ["crouch", "stand", "crouch_trans"]) \
				or combo.lenience == "ANY":
			state = combo.state.to_lower()
			playback.start(combo.state.to_lower())
		
		# Only perform the combo if we're in the correct state for the combo
		if state.to_upper() == combo.state:
			# Combo index should be the same index the state of the Transition node to be switched to
			animation_tree["parameters/" + state + "/Transition/current"] = combo_idx
			
			# Fire the animation
			animation_tree["parameters/" + state + "/OneShot/active"] = true
			
			combo_being_performed = true

# Perform whenever we are hit
func _on_hit(area, type, team, metadata):
	# Make sure this is an enemy hitbox (also you can't receive damage if you're dead)
	if team != player_number and type == "HIT" and not dead:
		var loc = metadata["location"] # Easier this way

		# Blocking while standing defends against mid and high attacks
		# Crouching (which is an implicit low-block) defends against mids and lows
		# Nothing can block unblockables
		if (blocking and (loc == "MID" or loc == "HIGH")) \
				or (crouching and (loc == "MID" or loc == "LOW")):
			# Recieve chip damage and blockstun on-block, but not knockback
			stun_timer = metadata["blockstun"]
			# You cannot be killed by chip damage
			current_health = max(current_health - metadata["chip"], 0.1)
			# Move to blockstun node
			playback.travel("blockstun")
		else:			# Receive full damage and hitstun on-hit *and* knockback
			stun_timer = metadata["hitstun"]
			current_health -= metadata["damage"]
			apply_knockback(metadata["knockback"])
			# Move to hitstun node
			playback.travel("hitstun")
		
		# Reflect changes in the UI
		get_tree().call_group("combat_ui", "update_health", player_number, current_health)
