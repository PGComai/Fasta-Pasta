extends Label

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_control_new_sample_info():
	if global.sample_id == 'custom':
		text = 'Custom Sample'
	else:
		text = str('Sample is from ', str(global.sample_id), ' | ', global.format_score(str(global.sample_from)), ' - ', global.format_score(str(global.sample_to)))
