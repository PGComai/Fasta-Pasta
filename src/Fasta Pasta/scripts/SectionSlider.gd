extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_control_section_slider_limit(lim):
	max_value = lim


func _on_control_section_slider_to(sec):
	set_value_no_signal(sec)


func _on_sample_choice_value_changed(val):
	value = val

func _on_custom_sample_check_toggled(button_pressed):
	editable = !button_pressed
