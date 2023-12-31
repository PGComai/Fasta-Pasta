extends SubViewport

signal map_clicked(val)

var x_size := 1.0

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	x_size = size.x


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_size_changed():
	x_size = size.x
	print('bottom_viewport_size: ', str(x_size))

func _on_sub_viewport_container_gui_input(event: InputEvent):
	if event.is_action_pressed('click') and global.begun_analysis:
		emit_signal("map_clicked", remap(event.position.x, 0.0, x_size, 0.0, global.substring_viewer_saved_parameters[global.focused_string]['Line Length']))
