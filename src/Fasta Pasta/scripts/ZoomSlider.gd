extends VSlider

var global: Node

@onready var viewer_module = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_value_changed(value):
	if viewer_module.using:
		global.substring_viewer_saved_parameters[viewer_module.substring_id]['Zoom'] = value

func _on_viewer_module_forward_match_ui(id, idx):
	set_value_no_signal(global.substring_viewer_saved_parameters[id]['Zoom'])
