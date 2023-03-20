class_name Modal
extends PopupDialog

# TODO: Later, you should be able to change the "yes" and "no" text.

signal yes_pressed()
signal no_pressed()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

""" Sets a new title for the modal.
	Params:
		`String` new_title - The new title to be put on the modal. BBCode may be used.
"""
func set_title(new_title: String) -> void:
	$"%ModalTitle".bbcode_text = "[center]" + new_title + "[/center]"

""" Sets new information for the modal.
	Params:
		`String` new_info - The new information to be put on the modal. BBCode may be used.
"""
func set_info(new_info: String) -> void:
	$"%ModalInfo".bbcode_text = "[center]" + new_info + "[/center]"

# Pass on event occurrences upwards
func _on_YesButton_pressed():
	emit_signal("yes_pressed")

func _on_NoButton_pressed():
	emit_signal("no_pressed")
