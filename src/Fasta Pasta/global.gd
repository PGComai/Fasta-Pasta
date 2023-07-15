extends Node

var number_of_available_substrings := 0
var number_of_viewing_instances := 0
var selected_substrings: Array[int] = []
var substring_viewer_saved_parameters := Dictionary()
#var substring_dict := {
#	"Viewing Position" : 0,
#	"Zoom" : 0.0,
#	"Line Length" : 0.0,
#	"Home X" : 0.0,
#	"X Adjustment" : 0.0,
#	"Zoomed Length" : 0.0,
#	"Zoom Home" : 0.0,
#	"Line Scale" : 0.0
#}
var substring_dict := Dictionary()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
