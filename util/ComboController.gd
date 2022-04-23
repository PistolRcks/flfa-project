extends Node

signal combo_performed(combo, player)

# TODO: Make neutral inputs less likely to happen accidentally
# FIXME: Fix accidental reinputting of direction input (line 56)

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

var recent_inputs = " "
var inputs_updated = false
var combo_performed = ""

onready var input_holder = $InputHolder
var input_being_held = false
const INPUT_HOLD_TIME = 0.5	# The amount of time to pause after making a combo (currently only for testing purposes)

onready var neutral_wait_timer = $NeutralWaitTimer
const NEUTRAL_WAIT_TIME = 0.15 # The amount of time to wait after inputting to register a neutral

func _process(delta):
	# Read inputs, convert into numpad notation (maybe this should be done player-side? will fix later)
	var up = Input.is_action_pressed("up")
	var down = Input.is_action_pressed("down")
	var left = Input.is_action_pressed("left")
	var right = Input.is_action_pressed("right")
	var numpad = 5 # assume input is neutral
	var input_to_process = ""
	
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
	else: neutral_wait_timer.start(NEUTRAL_WAIT_TIME)
	
	input_to_process += str(numpad) if numpad else ""
	
	if Input.is_action_pressed("attack_a") and Input.is_action_pressed("attack_b"):
		input_to_process += "G"
	elif Input.is_action_pressed("attack_a"):
		input_to_process += "A"
	elif Input.is_action_pressed("attack_b"):
		input_to_process += "B"
	
	# don't repeat inputs
	if input_to_process != recent_inputs.right(recent_inputs.length()-input_to_process.length()) \
			and not input_being_held:
		recent_inputs += input_to_process
		inputs_updated = true
	
	# Check if we finished a combo
	if not input_being_held:
		for combo in combo_list:
			var regex = RegEx.new()
			regex.compile(combo[0])
			var result = regex.search(recent_inputs)
			if result:
				combo_performed = combo[1]
				input_holder.start(INPUT_HOLD_TIME)
				# Make text green where the combo landed
				recent_inputs = recent_inputs.left(result.get_start()) + ">" + \
					recent_inputs.substr(result.get_start(), combo[0].length()) + "<"
				emit_signal("combo_performed", combo[1], 1)
				input_being_held = true
				break
	
	# Send data to richtextlabels (temp)
	# Only update when we need to
	if inputs_updated:
		get_node("../MarginContainer/VSplitContainer/Inputs").bbcode_text = input_text_to_images(recent_inputs)
		print("updating")
		inputs_updated = false
	
	get_node("../MarginContainer/VSplitContainer/Combos").bbcode_text = combo_performed
	pass

# Convert input text to input images
func input_text_to_images(text : String) -> String:
	var new_string = ""
	for c in text:
		# Only acceptable inputs (probably really shitty speed)
		if c in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "G"]:
			new_string += "[img]res://res/inputs/input_" + c + ".png[/img]"
		else:
			new_string += c
	return new_string

func _on_InputHolder_timeout():
	input_being_held = false
	recent_inputs = " "
	combo_performed = ""

func _on_NeutralWaitTimer_timeout():
	recent_inputs += "5"
