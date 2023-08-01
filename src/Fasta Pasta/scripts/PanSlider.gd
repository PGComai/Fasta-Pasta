extends HSlider

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
		global.substring_viewer_saved_parameters[viewer_module.substring_id]['X Adjustment'] = max_value - value

func _on_viewer_module_forward_match_ui(id, idx):
	pass
#	if viewer_module.using:
#		set_value_no_signal(global.substring_viewer_saved_parameters[id]['X Adjustment'])

func _on_viewer_module_forward_map_clicked(val):
	value = val

func _on_mesh_instance_3d_set_pan_slider_bounds():
	max_value = global.substring_viewer_saved_parameters[viewer_module.substring_id]['Line Length']
	print('pan max value: ', str(max_value))
	print('pan set value: ', str(max_value - global.substring_viewer_saved_parameters[viewer_module.substring_id]['X Adjustment']))
	set_value_no_signal(max_value - global.substring_viewer_saved_parameters[viewer_module.substring_id]['X Adjustment'])


func _on_pan_step_left_button_up():
	if viewer_module.using:
		global.substring_viewer_saved_parameters[viewer_module.substring_id]['X Adjustment'] += 0.001
		set_value_no_signal(max_value - global.substring_viewer_saved_parameters[viewer_module.substring_id]['X Adjustment'])


func _on_pan_step_right_button_up():
	if viewer_module.using:
		global.substring_viewer_saved_parameters[viewer_module.substring_id]['X Adjustment'] -= 0.001
		set_value_no_signal(max_value - global.substring_viewer_saved_parameters[viewer_module.substring_id]['X Adjustment'])
