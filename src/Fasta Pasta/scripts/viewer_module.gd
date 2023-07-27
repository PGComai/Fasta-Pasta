extends VBoxContainer

signal foward_line(vec_array, color_array, length, id)
signal forward_match_ui(id)
signal forward_map_clicked(val)
signal set_label_name(id)
signal forward_check_toggle(pressed, id)
signal forward_uncheck
signal check

var substring_id: String
var viewer_index: int
var using := false

var global: Node

@onready var check_box = $TitleAndButton/CheckBox
@onready var sequence_id_label = $TitleAndButton/SequenceIDLabel
@onready var sub_viewport = $Viewer1HBox/SubViewportContainer/SubViewport
@onready var mesh_instance_3d = $Viewer1HBox/SubViewportContainer/SubViewport/Node3D/MeshInstance3D
@onready var zoom_scroll = $Viewer1HBox/ZoomScroll
@onready var pan_scroll = $PanScroll


# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node('/root/Global')
	var control = get_node("/root/Control")
	var map = get_node('/root/Control/HBoxContainer/MarginContainer/ViewerVStack/SubViewportContainer/MapSubViewport')
	control.make_line.connect(_on_control_make_line)
	control.match_ui_to.connect(_on_control_match_ui_to)
	control.clear_viewers.connect(_on_control_clear_viewers)
	control.uncheck_check_boxes.connect(_on_control_uncheck_check_boxes)
	map.map_clicked.connect(_on_map_clicked)
	viewer_index = get_tree().get_nodes_in_group('ViewerModules').size() - 1
	print('viewer module initiated with index: ', str(viewer_index))
	if viewer_index == 0:
		emit_signal("check")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_control_make_line(arr: PackedVector3Array, colors: PackedColorArray, length: int, id: String, idx: int, map: bool):
	if idx == viewer_index and !map:
		using = true
		substring_id = id
		emit_signal("foward_line", arr, colors, length, id, viewer_index)
		emit_signal('set_label_name', id)
		global.viewer_instances[viewer_index] = id
		if substring_id == global.focused_string:
			emit_signal("check")

func _on_control_match_ui_to(id: String):
	emit_signal('forward_match_ui', id, viewer_index)

func _on_map_clicked(val):
	if substring_id == global.focused_string:
		emit_signal('forward_map_clicked', val)

func _on_control_clear_viewers():
	if viewer_index != 0:
		queue_free()

func _on_check_box_toggled(button_pressed):
	if using:
		emit_signal("forward_check_toggle", button_pressed, substring_id)

func _on_control_uncheck_check_boxes():
	if substring_id != global.focused_string:
		emit_signal('forward_uncheck')
