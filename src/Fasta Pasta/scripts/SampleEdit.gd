extends LineEdit

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_display_sample():
	text = global.legible_sample

func _on_custom_sample_check_toggled(button_pressed):
	editable = button_pressed
	global.custom_sample_enabled = button_pressed
