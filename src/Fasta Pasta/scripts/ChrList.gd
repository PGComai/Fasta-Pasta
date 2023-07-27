extends ItemList

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_control_add_item(item):
	add_item(item)

func _on_multi_selected(index, selected):
	var selected_items: Array = get_selected_items()
	global.selected_substrings = selected_items
