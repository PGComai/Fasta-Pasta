extends MeshInstance3D

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	get_tree().root


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_control_make_line(arr: PackedVector3Array, colors: PackedColorArray, length: int, id: String, idx: int, map: bool):
	if id == global.focused_string:
		var len_array = length
		var line_length = float(len_array) / 1000.0
		var line_scale = 1000.0 / line_length
		# Initialize the ArrayMesh.
		var arr_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = arr.slice(0, length)
		
		var home_x = -float(line_length) / 2.0
		position.x = home_x * line_scale
		
		# Create the Mesh.
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
		mesh = arr_mesh
		
		scale.x = line_scale


func _on_control_make_map(arr, colors, length, id, idx, map):
	var len_array = length
	var line_length = float(len_array) / 1000.0
	var line_scale = 1000.0 / line_length
	# Initialize the ArrayMesh.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = arr.slice(0, length)
	
	var home_x = -float(line_length) / 2.0
	position.x = home_x * line_scale
	
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	mesh = arr_mesh
	
	scale.x = line_scale
