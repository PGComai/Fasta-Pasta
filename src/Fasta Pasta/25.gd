extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-5000.0, -50.0, 0.0), Vector3(5000.0, -50.0, 0.0),
													Vector3(-5000.0, -100.0, 0.0), Vector3(5000.0, -100.0, 0.0),
													Vector3(-5000.0, 100.0, 0.0), Vector3(5000.0, 100.0, 0.0)])
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh = arr_mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
