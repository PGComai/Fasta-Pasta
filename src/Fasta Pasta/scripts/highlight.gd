extends MeshInstance3D

var line_length := 100.0
var top_line_scale := 1.0
var bottom_line_scale := 1.0
var zoom := 1.0
var window_width := 1000.0
var window_height := 1000.0
var zoom_value := 1.0
var x_adjustment := 0.0
var using := false
var current_string: String

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global.begun_analysis:
		window_width = global.top_viewport_width
		window_height = global.top_viewport_height
		current_string = global.focused_string
		x_adjustment = -global.substring_viewer_saved_parameters[global.focused_string]['X Adjustment']
		line_length = global.substring_viewer_saved_parameters[global.focused_string]['Line Length']
		zoom = global.substring_viewer_saved_parameters[global.focused_string]['Zoom']
		var zoomed_length = line_length * zoom
		var window_ratio = window_width / 1000.0
		position.x = ((x_adjustment + (line_length / 2.0)) * (1000.0 / line_length))
		mesh.size.x = ((1000.0 * window_width) / zoomed_length) / (window_height / 300.0)
