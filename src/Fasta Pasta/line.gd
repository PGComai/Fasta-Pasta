extends MeshInstance3D

signal cam_position_x(pos)
signal cam_zoom(zoom)
signal made_mesh(msh, pos)
signal line_length_to_highlight(len)

var home_x := 0.0
var zoom_home := 0.0
var x_adjustment := 0.0
var zoom := 1.0
var len_array := 1
var line_length := 0.0
var zoomed_length := 0.0
var current_string: String

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scale.x = zoom
	zoom_home = home_x + remap(x_adjustment, -100.0, 100.0, -zoomed_length / 2.0, zoomed_length / 2.0)
	position.x = zoom_home


func _on_control_make_line(arr: PackedVector3Array, colors: PackedColorArray, length: int, set_pos: bool, id: String):
	current_string = id
	print('set_pos: ', str(set_pos))
	print('str id: ', id)
	len_array = length
	if set_pos:
		x_adjustment = 0
		zoom = 1.0
		line_length = float(len_array) / 1000.0
		home_x = -float(line_length)/ 2.0
		zoom_home = home_x
		position.x = home_x
		emit_signal("line_length_to_highlight", line_length)
		zoomed_length = line_length
		print('line length is ', str(line_length))
	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = arr.slice(0, length)
	arrays[Mesh.ARRAY_COLOR] = colors.slice(0, length)
	
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	mesh = arr_mesh

func _on_pan_slider_value_changed(value):
	x_adjustment = -value

func _on_range_1_value_changed(value):
	pass # Replace with function body.

func _on_range_2_value_changed(value):
	pass # Replace with function body.


func _on_zoom_slider_value_changed(value):
	zoom = value
	zoomed_length = line_length * zoom
	home_x = -zoomed_length / 2.0
