extends Label

@onready var viewer_module = $"../.."

var global: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var id = viewer_module.substring_id
	if viewer_module.using:
		var base_coord: int = int(remap(global.substring_viewer_saved_parameters[id]["X Adjustment"],
										global.substring_viewer_saved_parameters[id]["Line Length"],
										0.0,
										0.0,
										float(global.substring_viewer_saved_parameters[id]["Bases"])))
		var base_coord_snapped1 = snappedi(maxi(base_coord - 50, 0), 100)
		var base_coord_snapped2 = mini(snappedi(base_coord + 50, 100), global.substring_viewer_saved_parameters[id]["Bases"])
		var base_coord_string: String = str(global.format_score(str(base_coord_snapped1)), ' - ', global.format_score(str(base_coord_snapped2)))
		var match_array_coord: int = base_coord_snapped1 / 100
		text = str(id, ' -- Centered on bases: ', base_coord_string, ' -- ', global.match_dict[id][match_array_coord], '% match')

