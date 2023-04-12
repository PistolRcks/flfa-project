extends Control

# messages are unsafe lol
class Message:
	var sender : String
	var message : String
	# Defines whether to use `<user> <message>` or
	# `[<user>]: <message>` when formatting text
	var is_me_style : bool 
	
	func _init(_is_me_style : bool, _sender : String, _message : String):
		is_me_style = _is_me_style
		sender = _sender
		message = _message
	
	func format_message() -> String:
		if is_me_style:
			return sender + " " + message
		return "[" + sender + "]: " + message

var message_history : Array = []
var username = "User"
var port : int = 3000

# Called when the node enters the scene tree for the first time.
func _ready():
	$"%HostPopup".popup()

## Chatting ##
# Sends a message to the chat client.
func send_message(message : String, is_me_style : bool = false):
	message_history.append(Message.new(is_me_style, username, message))
	update_text_box()

# Updates the textbox with new info.
func update_text_box():
	$"%TextOutput".text = ""
	
	for message in message_history:
		$"%TextOutput".text += message.format_message() + "\n"

## Multiplayer ##
# Creates a multiplayer server
func join_as_host():
	print("Joining as host...")

# Joins a multiplayer server at the given address `addr` as a client
func join_as_client(addr : String):
	print("Joining as client...")

## Handlers ##
# Handle pressing enter or the submit button in the UsernamePopup
func _handle_username_input(new_username : String):
	# Should check that usernames are one character or greater, but I honestly don't really care
	username = new_username
	$"%UsernamePopup".hide()
	send_message("just joined the server!", true)
	$"%TextInput".grab_focus()

func _handle_port_input(is_host : bool, new_port : String):
	# After entering the port, should hide this popup and do the other one
	port = int(new_port)
	
	if is_host:
		join_as_host()
	else:
		if $"%ClientAddressInput".text:
			join_as_client($"%ClientAddressInput".text)
		else:
			printerr("ClientAddressInput was empty, try again...")
			return
	
	# Close this popup and put in the other one
	$"%HostPopup".hide()
	$"%UsernamePopup".popup()

## Chat Windows ##
# Connect to when the user presses enter when typing into the chat window
func _on_TextInput_text_entered(new_text : String):
	send_message(new_text)
	$"%TextInput".clear()

## Username Popup ##
# Connects to when the user presses enter when inputting a username
func _on_UsernameInput_text_entered(new_text : String):
	_handle_username_input(new_text)

# Connects to when the user presses the button after inputting a username
func _on_SubmitButton_pressed():
	_handle_username_input($"%UsernameInput".text)

# Connects to the Main Menu button (either on the HostPopup or the UsernamePopup)
func _on_MainMenuButton_pressed():
	get_tree().change_scene("res://ui/MainMenu.tscn")

## Client Input ##
# Connects to when the user presses enter when inputting a username
func _on_ClientAddressInput_text_entered(new_address : String):
	# Change focus to port entry
	$"%ClientPortInput".grab_focus()

# Connects to when the user presses enter when inputting a username
func _on_ClientPortInput_text_entered(new_port : String):
	_handle_port_input(false, new_port)

# Connects to when the user presses the "Join" button after inputting an address and port
func _on_ClientSubmit_pressed():
	_handle_port_input(false, $"%ClientPortInput".text)

## Host Input ##
# Connects to when the user presses enter when inputting a port for the host
func _on_HostPortInput_text_entered(new_port : String):
	_handle_port_input(true, new_port)

# Connects to when the user presses the "Host" button after inputting a port
func _on_HostSubmit_pressed():
	_handle_port_input(true, $"%HostPortInput".text)
