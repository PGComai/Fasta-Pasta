extends CheckBox

@onready var viewer_module = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_viewer_module_forward_uncheck():
	set_pressed_no_signal(false)


func _on_viewer_module_check():
	set_pressed_no_signal(true)
