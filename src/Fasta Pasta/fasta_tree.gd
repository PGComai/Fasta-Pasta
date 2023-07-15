extends Tree

var tree
var root
var tree_dict := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	tree = Tree.new()
	root = tree.create_item()
	#tree.hide_root = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_tree_add_item(item, parent):
	var chr = tree.create_item(root)
	chr.set_text(0, str(item))
