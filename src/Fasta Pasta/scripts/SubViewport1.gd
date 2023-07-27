extends SubViewport

signal viewport_resized(window_x)

var x_size := 1

var global: Node

var got_global := false

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_size_changed():
	if !got_global:
		global = get_node("/root/Global")
		got_global = true
	x_size = size.x
	global.top_viewport_width = size.x
	global.top_viewport_height = size.y
	print('top_viewport_size: ', str(x_size))
	#emit_signal('viewport_resized', (size.x * 300.0) / size.y)

func _on_sub_viewport_container_gui_input(event):
	if event.is_action_pressed('click'):
		pass
		# figure out bounds for this
		#emit_signal("map_clicked", remap(event.position.x, 0.0, x_size, -100.0, 100.0))
