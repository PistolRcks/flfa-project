extends Control

const DummyNetworkAdaptor = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

func _ready():
	$"%QuitModal".set_title("Quit Game")
	$"%QuitModal".set_info("Are you sure you want to quit the game?")

""" Changes the scene to the TestingArena. """
func _on_LocalButton_pressed():
	# Start the SyncManager just for the timer
	SyncManager.network_adaptor = DummyNetworkAdaptor.new()
	SyncManager.start()
	get_tree().change_scene("res://level/basic_arena/TestingArena.tscn")

func _on_OnlineButton_pressed():
	# This will be changed in the future.
	get_tree().change_scene("res://ui/MultiplayerUI.tscn")

""" Prompts the user if they want to quit the game. """
func _on_ExitButton_pressed():
	$"%QuitModal".popup()

""" Closes the quit modal. """
func _on_QuitModal_no_pressed():
	$"%QuitModal".hide()

""" Quits the game. """
func _on_QuitModal_yes_pressed():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
	get_tree().quit()
