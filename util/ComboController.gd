extends Node

# Attacks are A and B (G stands for both A and B). Notation is keypad notation
var combo_list = [
	["A", "Punch"],
	["236A", "Fireball"],
	["623A", "Dragon Punch"]
]

var recent_inputs = " "

func _process(delta):
	# Read inputs, convert into numpad notation (maybe this should be done player-side? will fix later)
	var up = Input.is_action_pressed("up")
	var down = Input.is_action_pressed("down")
	var left = Input.is_action_pressed("left")
	var right = Input.is_action_pressed("right")
	var numpad # assume input is neutral
	var input_to_process = ""
	
	# 7 8 9
	# 4 5 6
	# 1 2 3
	
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
	
	input_to_process += str(numpad) if numpad else ""
	
	if Input.is_action_pressed("attack_a") and Input.is_action_pressed("attack_b"):
		input_to_process += "G"
	elif Input.is_action_pressed("attack_a"):
		input_to_process += "A"
	elif Input.is_action_pressed("attack_b"):
		input_to_process += "B"
	
	# don't repeat inputs
	if input_to_process != recent_inputs.right(recent_inputs.length()-input_to_process.length()):
		recent_inputs += input_to_process
	
	
	
	# Check if we finished a combo (FIXME: Doesn't work lmao)
	for combo in combo_list:
		var regex = RegEx.new()
		regex.compile(combo[1])
		var result = regex.search(recent_inputs)
		if result:
			print(combo[2] + " performed!")
			break
	
	# Send data to richtextlabel (temp)
	get_node("../MarginContainer/RichTextLabel").bbcode_text = recent_inputs
	pass
