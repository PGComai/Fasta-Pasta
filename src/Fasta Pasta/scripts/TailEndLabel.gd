extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_sample_choice_value_changed(value):
	pass


func _on_section_slider_value_changed(value):
	text = ' to ' + str(value + 1) + ' x 100'


func _on_control_section_slider_to(sec):
	text = ' to ' + str(sec + 1) + ' x 100'
