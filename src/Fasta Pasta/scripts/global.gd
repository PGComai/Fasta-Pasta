extends Node

var number_of_available_substrings := 0
var number_of_viewing_instances := 0
var all_substrings := []
var selected_substrings := []
var computed_substrings := []
var substring_viewer_saved_parameters := Dictionary()
var begun_analysis := false
var focused_string: String
var top_viewport_width: int
var top_viewport_height: int
var bottom_viewport_width: int
var chr_dict := Dictionary()
var match_dict := Dictionary()
var viewer_instances := Dictionary()
var section_to_analyze := 0
var sample_id: String
var sample_from: int
var sample_to: int
var sample: Array
var legible_sample: String
var custom_sample_string: String
var custom_sample_enabled := false
var low_memory_mode := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# https://ask.godotengine.org/18559/how-to-add-commas-to-an-integer-or-float-in-gdscript
func format_score(score : String) -> String:
	var i : int = score.length() - 3
	while i > 0:
		score = score.insert(i, ",")
		i = i - 3
	return score
