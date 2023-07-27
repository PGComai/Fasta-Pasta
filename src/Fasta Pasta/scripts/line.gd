extends MeshInstance3D

signal cam_position_x(pos)
signal cam_zoom(zoom)
signal made_mesh(msh, pos)
signal line_length_to_highlight(len, string)
signal set_pan_slider_bounds

var home_x := 0.0
var zoom_home := 0.0
var x_adjustment := 0.0
var zoom := 1.0
var len_array := 1
var line_length := 0.0
var zoomed_length := 0.0
var current_string: String
var using := false

var global: Node

@onready var viewer_module = $"../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if using:
		x_adjustment = global.substring_viewer_saved_parameters[current_string]['X Adjustment']
		zoom = global.substring_viewer_saved_parameters[current_string]['Zoom']
		line_length = global.substring_viewer_saved_parameters[current_string]['Line Length']
		zoomed_length = line_length * zoom
		home_x = -zoomed_length / 2.0
		scale.x = zoom
		zoom_home = home_x + remap(x_adjustment, 0.0, line_length, -zoomed_length / 2.0, zoomed_length / 2.0)
		position.x = zoom_home

func _on_viewer_module_foward_line(vec_array, color_array, length, id, idx):
	current_string = id
	using = true
	print('str id: ', id)
	len_array = length
	print('stored info: ', str(global.substring_viewer_saved_parameters[current_string]['Stored Info']))
	if !global.substring_viewer_saved_parameters[current_string]['Stored Info']:
		global.substring_viewer_saved_parameters[current_string]['Zoom'] = 1.0
		line_length = float(len_array) / 1000.0
		home_x = -float(line_length) / 2.0
		global.substring_viewer_saved_parameters[current_string]['Home X'] = home_x
		global.substring_viewer_saved_parameters[current_string]['Line Length'] = line_length
		global.substring_viewer_saved_parameters[current_string]['X Adjustment'] = line_length / 2.0
		zoom_home = home_x
		position.x = home_x
		zoomed_length = line_length
	#emit_signal("line_length_to_highlight", line_length, current_string)
	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vec_array.slice(0, length)
	arrays[Mesh.ARRAY_COLOR] = color_array.slice(0, length)
	
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	mesh = arr_mesh
	
	global.substring_viewer_saved_parameters[current_string]['Stored Info'] = true
	emit_signal("set_pan_slider_bounds")
