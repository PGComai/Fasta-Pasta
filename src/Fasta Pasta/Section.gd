extends SpinBox


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_section_limit(lim):
	max_value = lim
	suffix = ' / ' + str(lim) + ' 100-mers'
