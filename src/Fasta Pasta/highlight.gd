extends MeshInstance3D

var line_length := 100.0
var line_scale := 1.0
var zoom := 1.0
var window_width := 1000.0
var zoom_value := 1.0

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_h_slider_value_changed(value):
	position.x = remap(value * (1000.0 / line_length), -100.0, 100.0, -line_length / 2.0, line_length / 2.0)


func _on_mesh_instance_3d_line_length_to_highlight(len):
	line_length = len
	line_scale = window_width / line_length

func _on_v_slider_value_changed(value):
	zoom_value = value
	zoom = value / line_scale
	scale.x = 1.0 / zoom

func _on_range_1_value_changed(value):
	pass # Replace with function body.

func _on_range_2_value_changed(value):
	pass # Replace with function body.

func _on_sub_viewport_viewport_resized(window_x):
	window_width = window_x
	line_scale = window_width / line_length
	zoom = zoom_value / line_scale
	scale.x = 1.0 / zoom
