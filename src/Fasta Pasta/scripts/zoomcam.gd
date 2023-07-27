extends Camera3D

var original_zoom := 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	original_zoom = size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_mesh_instance_3d_cam_position_x(pos):
	position.x = pos


func _on_mesh_instance_3d_cam_zoom(zoom):
	size = original_zoom / zoom
