extends Node

signal combo_performed(combo, player)

# FIXME: Fix accidental reinputting of direction input (line 56)

var combo_list = [] 

var assigned_player = 1		# Player assigned to this ComboController

var recent_inputs = " "
var inputs_updated = false
var combo_performed = ""

onready var input_holder = $InputHolder
var input_being_held = false
const INPUT_HOLD_TIME = 0.5	# The amount of time to pause after making a combo (currently only for testing purposes)

var neutral_wait_timer = 0
const NEUTRAL_WAIT_TIME = 0.016 # The amount of time to wait after inputting to register a neutral

var _testing = false

# Translate inputs to the player's counterpart
onready var nat_up = "p" + str(assigned_player) + "_up"
onready var nat_down = "p" + str(assigned_player) + "_down"
onready var nat_left = "p" + str(assigned_player) + "_left"
onready var nat_right = "p" + str(assigned_player) + "_right"
onready var nat_attack_a = "p" + str(assigned_player) + "_attack_a"
onready var nat_attack_b = "p" + str(assigned_player) + "_attack_b"


func _ready():
	# Set this if we're in the ComboTester
	_testing = (get_tree().get_current_scene().get_name() == "ComboTester")
	
	# For testing purposes, put in some sample combos;
	# otherwise, combo_list should be filled by a player's combos
	if _testing:
		combo_list = [
			Combo.new("236.?A$", "Fireball", []),		# Quartercircle Forward + A (additional char for ease of input)
			Combo.new("65?23.?A$", "Dragon Punch", []),	# Z motion forward (optional neutral) + A (additional char for ease of input)
			Combo.new("G$", "Forward Grab", []),
			Combo.new("5A$", "Jab", []),				# Just A (technically neutral A)
			Combo.new("6A$", "lmao 6P reference", []),	# Forward + A
			Combo.new("2A$", "Dickpunch (yes that's really what it's called in Tekken)", []),	# Down + A (yes that is actually what it is called)
			Combo.new("5656$", "Forward Dash", []),		# Doubletap Forward
		]

func _process(delta):
	# Read inputs, convert into numpad notation
	var up = Input.is_action_pressed(nat_up)
	var down = Input.is_action_pressed(nat_down)
	var left = Input.is_action_pressed(nat_left)
	var right = Input.is_action_pressed(nat_right)
	var numpad # assume input is neutral
	var input_to_process = ""
	
	# Update neutral wait timer (Timer node doesn't update in a fine enough manner)
	if neutral_wait_timer >= 0:
		neutral_wait_timer -= delta
	
	# Turn inputs into numpad notation (really awful form, don't care)
	# check for more complex inputs before less complex inputs so we don't need to make things 
	# longer than they have to be
	if up and left: numpad = 7
	elif up and right: numpad = 9
	elif up: numpad = 8
	elif left and down: numpad = 1
	elif right and down: numpad = 3
	elif left: numpad = 4
	elif right: numpad = 6
	elif down: numpad = 2
	
	# keep the neutral wait timer at max if we haven't pressed a key
	if left or right or up or down:
		neutral_wait_timer = NEUTRAL_WAIT_TIME
	# otherwise input a neutral if the timer is at zero
	elif neutral_wait_timer <= 0:
		numpad = 5
	
	input_to_process += str(numpad) if numpad else ""
	
	if Input.is_action_pressed(nat_attack_a) and Input.is_action_pressed(nat_attack_b):
		input_to_process += "G"
	elif Input.is_action_pressed(nat_attack_a):
		input_to_process += "A"
	elif Input.is_action_pressed(nat_attack_b):
		input_to_process += "B"
	
	# don't repeat inputs
	if input_to_process != recent_inputs.right(recent_inputs.length()-input_to_process.length()) \
			and not input_being_held:
		recent_inputs += input_to_process
		inputs_updated = true
	
	# Check if we finished a combo
	if not input_being_held:
		for combo in combo_list:
			# Check if the current combo we're looking at is what we performed
			var result = combo.regex.search(recent_inputs)
			if result:
				combo_performed = combo.name
				input_holder.start(INPUT_HOLD_TIME)
				# Make text green where the combo landed
				recent_inputs = recent_inputs.left(result.get_start()) + ">" + \
					recent_inputs.substr(result.get_start(), combo.inputs.length()) + "<"
				emit_signal("combo_performed", combo.name, 1)
				
				# Only hold input if we're testing
				if _testing:
					input_being_held = true
				break
	
	# Send data to richtextlabels (temp)
	# Only update when we need to
	if get_node_or_null("../MarginContainer/VSplitContainer"):
		if inputs_updated:
			get_node("../MarginContainer/VSplitContainer/Inputs").bbcode_text = input_text_to_images(recent_inputs)

			inputs_updated = false
		
		get_node("../MarginContainer/VSplitContainer/Combos").bbcode_text = combo_performed

""" Update the currently assigned player (and natural inputs) to `new_player`. """
func update_assigned_player(new_player : int):
	assigned_player = new_player
	
	nat_up = "p" + str(assigned_player) + "_up"
	nat_down = "p" + str(assigned_player) + "_down"
	nat_left = "p" + str(assigned_player) + "_left"
	nat_right = "p" + str(assigned_player) + "_right"
	nat_attack_a = "p" + str(assigned_player) + "_attack_a"
	nat_attack_b = "p" + str(assigned_player) + "_attack_b"

""" Convert input text to input images """
func input_text_to_images(text : String) -> String:
	var new_string = ""
	for c in text:
		# Only acceptable inputs (probably really shitty speed)
		if c in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "G"]:
			new_string += "[img]res://res/inputs/input_" + c + ".png[/img]"
		else:
			new_string += c
	return new_string

""" Adds combos to the combo list """
func register_combo(combo : Combo):
	combo_list.append(combo)

func _on_InputHolder_timeout():
	input_being_held = false
	recent_inputs = " "
	combo_performed = ""
