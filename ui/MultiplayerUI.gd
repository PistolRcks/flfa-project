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
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")
	get_tree().connect("connected_to_server", self, "_on_client_connected_ok")
	get_tree().connect("connection_failed", self, "_on_client_connected_fail")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

## Chatting ##
# Sends a message to the chat client.
remotesync func send_message(message : String, is_me_style : bool = false, 
		user : String = username):
	
	message_history.append(Message.new(is_me_style, user, message))
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
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, 2)
	get_tree().network_peer = peer

# Joins a multiplayer server at the given address `addr` as a client
func join_as_client(addr : String):
	print("Joining as client!")
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(addr, port)
	get_tree().network_peer = peer

# Disconnects from the network.
func _handle_disconnect():
	rpc("send_message", "disconnected from the server.", true, username)
	get_tree().network_peer = null

## Handlers ##
# Handle pressing enter or the submit button in the UsernamePopup
func _handle_username_input(new_username : String):
	# Should check that usernames are one character or greater, but I honestly don't really care
	username = new_username
	$"%UsernamePopup".hide()
	rpc("send_message", "just joined the server!", true, username)
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

## Multiplayer ##
func _on_player_connected(id):
	print("Player with ID " + String(id) + " connected!")

func _on_player_disconnected(id):
	print("Player with ID " + String(id) + " disconnected!")

func _on_client_connected_ok():
	print("Connected to server successfully!")

func _on_client_connected_fail():
	print("Failed to connect to server!")

func _on_server_disconnected():
	send_message("disconnected.", true, "Server")

## Chat Windows ##
# Connect to when the user presses enter when typing into the chat window
func _on_TextInput_text_entered(new_text : String):
	rpc("send_message", new_text, false, username)
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
