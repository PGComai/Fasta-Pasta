extends Label

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_sample_edit_text_changed(new_text):
	text = str(new_text.length(), ' / 100')
	global.custom_sample_string = new_text
	
