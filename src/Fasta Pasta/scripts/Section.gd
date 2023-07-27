extends SpinBox

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_section_limit(lim):
	pass
#	max_value = lim
#	suffix = ' / ' + str(lim) + ' 100-mers'
