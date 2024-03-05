extends Control

signal add_item(item)
signal make_line(arr, colors, length, id, idx, map)
signal make_line2d(arr, colors, length, id, idx, map)
signal make_map(arr, colors, length, id, idx, map)
signal section_limit(lim)
signal section_slider_limit(lim)
signal section_slider_to(sec)
signal set_marker(x)
signal match_ui_to(id)
signal clear_viewers
signal uncheck_check_boxes()
signal new_focused_string
signal display_sample
signal new_sample_info

var filepath: String
var file: FileAccess
var filetxt: String

var rd := RenderingServer.create_local_rendering_device()

var selected_item := 0
var chr_dict: Dictionary
var final_num_results := 0
var section := 0
var analyze_section := 0
var computing := false
var first_compute := false
var analyzed_item := 0
var reset_mesh_pos := true
var auto_run := true
var global: Node
var waiting_for_viewers_to_leave := false
var waiting_for_new_map := false
var reference_section: PackedInt32Array
var queue_read := false
var queue_frames := 0
var substring_param := {
	"Viewing Position" : 0,
	"Zoom" : 0.0,
	"Line Length" : 0.0,
	"Bases" : 0,
	"Home X" : 0.0,
	"X Adjustment" : 0.0,
	"Last Sample Section" : 0,
	"Stored Info" : false
}

var viewer_box := preload("res://scenes/viewer_box.tscn")
var gc1 := GPUComputer.new()
var gc2 := GPUComputer.new()

@onready var loading = $HBoxContainer/FileVStack/Loading

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	gc1.shader_file = load("res://fasta_comp_binary.glsl")
	gc1._load_shader()
	gc2.shader_file = load("res://line.glsl")
	gc2._load_shader()
	#chr_dict = global.substring_dict


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if waiting_for_viewers_to_leave:
		_wait_for_viewers_to_leave()
	if waiting_for_new_map and !computing:
		_map_compute()
		waiting_for_new_map = false
	if queue_read:
		if queue_frames > 3:
			_read_fasta()
			queue_read = false
			queue_frames = 0
		else:
			queue_frames += 1

func _on_load_button_button_up():
	filepath = filepath.replace('"', '')
	if FileAccess.file_exists(filepath):
		loading.visible = true
		queue_read = true
	else:
		print('bad path')

func _on_file_path_text_changed(new_text):
	filepath = new_text
	filepath = filepath.replace('\\', '/')

func _on_file_path_text_submitted(new_text):
	filepath = new_text
	filepath = filepath.replace('\\', '/')
	filepath = filepath.replace('"', '')
	if FileAccess.file_exists(filepath):
		loading.visible = true
		queue_read = true
	else:
		print('bad path')

func _read_csv():
	filepath = filepath.replace('"', '')
	print(filepath)
	var csv_array := []
	if FileAccess.file_exists(filepath):
		file = FileAccess.open(filepath, FileAccess.READ)
		while file.get_position() < file.get_length():
			csv_array.append(file.get_csv_line())
		#_compute_compress(chr_dict[chr_k])
	else:
		print('bad path')
	print(len(csv_array))
	var pos_array := PackedInt32Array()
	var repeat_array := PackedInt32Array()
	var count_array := PackedInt32Array()
	
	var tick = false
	for line in csv_array:
		if !tick:
			tick = true
		else:
			pos_array.append(int(line[0]))
			repeat_array.append(int(line[1]))
			count_array.append(int(line[2]))
	var data_length = pos_array.size()
	var full_array_size := 27000
	pos_array.resize(full_array_size)
	repeat_array.resize(full_array_size)
	count_array.resize(full_array_size)
	var param_array := PackedFloat32Array([float(data_length), 4000.0])
	
	### shader time ###
	
	# Load GLSL shader
	var shader_file := load("res://arnie_scott_comp.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var input_pos_bytes := pos_array.to_byte_array()
	var input_repeat_bytes := repeat_array.to_byte_array()
	var input_count_bytes := count_array.to_byte_array()
	var input_param_bytes := param_array.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	var buffer_pos := rd.storage_buffer_create(input_pos_bytes.size(), input_pos_bytes)
	var buffer_repeat := rd.storage_buffer_create(input_repeat_bytes.size(), input_repeat_bytes)
	var buffer_count := rd.storage_buffer_create(input_count_bytes.size(), input_count_bytes)
	var buffer_param := rd.storage_buffer_create(input_param_bytes.size(), input_param_bytes)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform_pos := RDUniform.new()
	uniform_pos.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_pos.binding = 0 # this needs to match the "binding" in our shader file
	uniform_pos.add_id(buffer_pos)
	var uniform_repeat := RDUniform.new()
	uniform_repeat.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_repeat.binding = 1 # this needs to match the "binding" in our shader file
	uniform_repeat.add_id(buffer_repeat)
	var uniform_count := RDUniform.new()
	uniform_count.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_count.binding = 2 # this needs to match the "binding" in our shader file
	uniform_count.add_id(buffer_count)
	var uniform_param := RDUniform.new()
	uniform_param.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_param.binding = 3 # this needs to match the "binding" in our shader file
	uniform_param.add_id(buffer_param)
	
	var img2d := Image.create(4000, 1080, false, Image.FORMAT_RGBA8)
	img2d.fill(Color('white'))

	var image_size = img2d.get_size()
	var read_data = img2d.get_data()

	var tex_read_format := RDTextureFormat.new()
	tex_read_format.width = image_size.x
	tex_read_format.height = image_size.y
	tex_read_format.depth = 4
	tex_read_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tex_read_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	)
	var tex_view := RDTextureView.new()
	var texture_read = rd.texture_create(tex_read_format, tex_view, [read_data])

	# Create uniform set using the read texture
	var read_uniform := RDUniform.new()
	read_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	read_uniform.binding = 4
	read_uniform.add_id(texture_read)

	# Initialize write data
	var write_data = read_data
	#write_data.resize(read_data.size())

	var tex_write_format := RDTextureFormat.new()
	tex_write_format.width = image_size.x
	tex_write_format.height = image_size.y
	tex_write_format.depth = 4
	tex_write_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	tex_write_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	var texture_write = rd.texture_create(tex_write_format, tex_view, [write_data])

	# Create uniform set using the write texture
	var write_uniform := RDUniform.new()
	write_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	write_uniform.binding = 5
	write_uniform.add_id(texture_write)
	
	var uniform_set := rd.uniform_set_create([uniform_pos, uniform_repeat, uniform_count, uniform_param, read_uniform, write_uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	
	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 30, 30, 30)
	rd.compute_list_end()
	
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	read_data = rd.texture_get_data(texture_write, 0)
	var image := Image.create_from_data(image_size.x, image_size.y, false, Image.FORMAT_RGBA8, read_data)
	image.save_png("C:/Users/comai/Documents/arnie-scott stuff/dr_counts.png")

func _read_fasta():
	print(filepath)
	file = FileAccess.open(filepath, FileAccess.READ)
	filetxt = file.get_as_text()
	print(len(filetxt))
	var chrs = filetxt.split('>')
	print(len(chrs))
	for chr in chrs:
		var newsplit = chr.split('\n', true, 1)
		if len(newsplit) == 1:
			pass
		else:
			var newstr = newsplit[1].strip_escapes()
			global.chr_dict[newsplit[0]] = Array(newstr.split('')).map(acgt_to_int)
			global.match_dict[newsplit[0]] = []
	print(global.chr_dict.keys())
	var count := 0
	for chr_k in global.chr_dict.keys():
		global.all_substrings.append(count)
		emit_signal('add_item', str(chr_k, ' - ', global.format_score(str(len(global.chr_dict[chr_k]))), ' bases'))
		global.substring_viewer_saved_parameters[str(chr_k)] = substring_param.duplicate()
		global.substring_viewer_saved_parameters[str(chr_k)]["Bases"] = len(global.chr_dict[chr_k])
		count += 1
	loading.visible = false

func _single_binary_compute(id: String, workgroup_size: int, viewer_idx: int, map: bool):
	var data_array := PackedInt32Array(global.chr_dict[id])
	
	var length : int = ceili(data_array.size() / 100.0)
	
	var line_length = float(length) / 1000.0
	var line_scale = 1000.0 / line_length
	var home_x = (-float(line_length) / 2.0)
	
	print('data_array_size: ', str(data_array.size()))
	
	var full_array_size: int = pow(workgroup_size, 3.0) * 100
	var result_array_size: int = full_array_size / 100
	
	print('full_array_size: ', str(full_array_size))
	print('result_array_size: ', str(result_array_size))
	
	var data_filler := PackedInt32Array()
	data_filler.resize(full_array_size - data_array.size())
	data_filler.fill(0)
	data_array.append_array(data_filler)
	
	var result_array := PackedInt32Array()
	result_array.resize(result_array_size)
	result_array.fill(0)
	
	var param_array := PackedInt32Array()
	param_array.resize(1)
	param_array.fill(mini(length, maxi(section, 0)))
	
	var sample_array := PackedInt32Array(global.sample)
	
	var input_result := result_array
	var input_result_bytes := input_result.to_byte_array()
	var input_data := data_array
	var input_data_bytes := input_data.to_byte_array()
	var input_param := param_array
	var input_param_bytes := input_param.to_byte_array()
	var input_sample_bytes := sample_array.to_byte_array()
	
	gc1._add_buffer(0, 0, input_result_bytes)
	gc1._add_buffer(0, 1, input_data_bytes)
	gc1._add_buffer(0, 2, input_param_bytes)
	gc1._add_buffer(0, 3, input_sample_bytes)
	
	gc1._make_pipeline(Vector3i(workgroup_size, workgroup_size, workgroup_size), true)
	
	gc1._submit()
	gc1._sync()
	
	var output_result_bytes := gc1.output(0, 0)
	var output_result := output_result_bytes.to_int32_array()
	
	gc1._free_rid(0, 0)
	gc1._free_rid(0, 1)
	gc1._free_rid(0, 2)
	gc1._free_rid(0, 3)
	
	global.match_dict[id] = Array(output_result).slice(0, length)
	
	_compute_linemesh(output_result, length, id, result_array_size, workgroup_size, viewer_idx, map)

func _compute_linemesh(chr: PackedInt32Array, len_arr: int, id: String, result_array_size: int, workgroup_size: int, viewer_idx: int, map: bool):
	var value_array : PackedInt32Array = chr
	var pos_x_array := PackedFloat32Array()
	var pos_y_array := PackedFloat32Array()
	var pos_z_array := PackedFloat32Array()
	var color_r_array := PackedFloat32Array()
	var color_g_array := PackedFloat32Array()
	var color_b_array := PackedFloat32Array()
	pos_x_array.resize(result_array_size)
	pos_y_array.resize(result_array_size)
	pos_z_array.resize(result_array_size)
	color_r_array.resize(result_array_size)
	color_g_array.resize(result_array_size)
	color_b_array.resize(result_array_size)
	pos_x_array.fill(0.0)
	pos_y_array.fill(0.0)
	pos_z_array.fill(0.0)
	color_r_array.fill(255.0)
	color_g_array.fill(255.0)
	color_b_array.fill(255.0)
	
	var input_value_bytes := value_array.to_byte_array()
	var input_pos_x_bytes := pos_x_array.to_byte_array()
	var input_pos_y_bytes := pos_y_array.to_byte_array()
	var input_pos_z_bytes := pos_z_array.to_byte_array()
	var input_color_r_bytes := color_r_array.to_byte_array()
	var input_color_g_bytes := color_r_array.to_byte_array()
	var input_color_b_bytes := color_r_array.to_byte_array()
	
	gc2._add_buffer(0, 0, input_pos_x_bytes)
	gc2._add_buffer(0, 1, input_pos_y_bytes)
	gc2._add_buffer(0, 2, input_pos_z_bytes)
	gc2._add_buffer(0, 3, input_value_bytes)
	
	gc2._add_buffer(1, 0, input_color_r_bytes)
	gc2._add_buffer(1, 1, input_color_g_bytes)
	gc2._add_buffer(1, 2, input_color_b_bytes)
	
	gc2._make_pipeline(Vector3i(workgroup_size, workgroup_size, workgroup_size), true)
	
	gc2._submit()
	gc2._sync()
	
	var output_pos_x_bytes := gc2.output(0, 0)
	var output_pos_y_bytes := gc2.output(0, 1)
	var output_pos_z_bytes := gc2.output(0, 2)
	
	var output_color_r_bytes := gc2.output(1, 0)
	var output_color_g_bytes := gc2.output(1, 1)
	var output_color_b_bytes := gc2.output(1, 2)
	
	gc2._free_rid(0, 0)
	gc2._free_rid(0, 1)
	gc2._free_rid(0, 2)
	gc2._free_rid(0, 3)
	gc2._free_rid(1, 0)
	gc2._free_rid(1, 1)
	gc2._free_rid(1, 2)
	
	var output_pos_x := output_pos_x_bytes.to_float32_array()
	var output_pos_y := output_pos_y_bytes.to_float32_array()
	var output_pos_z := output_pos_z_bytes.to_float32_array()
	
	var output_color_r := output_color_r_bytes.to_float32_array()
	var output_color_g := output_color_g_bytes.to_float32_array()
	var output_color_b := output_color_b_bytes.to_float32_array()
	
	var vec_array := PackedVector3Array()
	var vec2_array := PackedVector2Array()
	var color_array := PackedColorArray()
	
	for i in result_array_size:
		vec2_array.append(Vector2(output_pos_x[i], output_pos_y[i]))
		vec_array.append(Vector3(output_pos_x[i], output_pos_y[i], output_pos_z[i]))
		color_array.append(Color(output_color_r[i], output_color_g[i], output_color_b[i]))
	
	if !map:
		emit_signal('make_line', vec_array, color_array, len_arr, id, viewer_idx, map)
		emit_signal('make_line2d', vec2_array, color_array, len_arr, id, viewer_idx, map)
	else:
		print('make map')
		emit_signal('make_map', vec_array, color_array, len_arr, id, viewer_idx, map)
	
	first_compute = true
	
func acgt_to_int(letter: String):
	letter = letter.to_lower()
	if letter == 'a':
		return 1
	elif letter == 'c':
		return 2
	elif letter == 'g':
		return 3
	elif letter == 't':
		return 4
	else:
		return 5

func int_to_acgt(number: int):
	if number == 1:
		return 'a'
	elif number == 2:
		return 'c'
	elif number == 3:
		return 'g'
	elif number == 4:
		return 't'
	else:
		return 'x'

func int_array_to_acgt_string(arr: Array):
	var result = arr.map(int_to_acgt)
	return ''.join(result)

func get_reference_section():
	pass

func _queue_compute():
	computing = true
	emit_signal("clear_viewers")
	waiting_for_viewers_to_leave = true

func calc_wg_size(length: int):
	if length <= 12500000:
		return 50
	elif length <= 42187500:
		return 75
	elif length <= 100000000:
		return 100
	else:
		return 115

func _map_compute():
	computing = true
	
	#var retrieve_section = global.substring_viewer_saved_parameters[global.focused_string]['Last Sample Section']
	var length_to_compute = global.chr_dict[global.focused_string].size()
	print('length to compute: ', str(length_to_compute))
	var wg_size = calc_wg_size(length_to_compute)
	print('chosen workgroup size: ', str(wg_size))
	#emit_signal('match_ui_to', global.chr_dict.keys()[analyzed_item])
	var length : int = ceili(length_to_compute / 100.0)
	emit_signal('section_slider_limit', maxi(length - 1, 0))
	_single_binary_compute(global.focused_string, wg_size, 0, true)
	emit_signal('section_slider_to', 0)
	
	computing = false

func _on_analyze_button_button_up():
	if !computing:
#		print('beginning memory optimization')
#		print('all substrings: ', global.all_substrings)
#		print('selected substrings: ', global.selected_substrings)
#		for substr in global.all_substrings:
#			if global.selected_substrings.has(substr):
#				global.chr_dict[global.chr_dict.keys()[substr]] = Array(global.chr_dict[global.chr_dict.keys()[substr]])
#			else:
#				global.chr_dict[global.chr_dict.keys()[substr]] = PackedInt32Array(global.chr_dict[global.chr_dict.keys()[substr]])
#		print('memory optimization complete')
		_queue_compute()

func _wait_for_viewers_to_leave():
	if get_tree().get_nodes_in_group('ViewerModules').size() < 2:
		global.focused_string = global.chr_dict.keys()[global.selected_substrings[0]]
		var viewer_count := 0
		if !global.begun_analysis:
			_get_sample()
			emit_signal("display_sample")
			emit_signal('new_sample_info')
		for sel_idx in global.selected_substrings:
			if viewer_count > 0:
				var vb = viewer_box.instantiate()
				vb.forward_check_toggle.connect(_on_vb_forward_check_toggle)
				$HBoxContainer/MarginContainer/ViewerVStack/ExtraViewerBox.add_child(vb)
			else:
				#global.focused_string = global.chr_dict.keys()[sel_idx]
				emit_signal('new_focused_string')
			var length_to_compute = global.chr_dict[global.chr_dict.keys()[sel_idx]].size()
			print('length to compute: ', str(length_to_compute))
			var wg_size = calc_wg_size(length_to_compute)
			print('chosen workgroup size: ', str(wg_size))
			emit_signal('match_ui_to', global.chr_dict.keys()[sel_idx])
			_single_binary_compute(global.chr_dict.keys()[sel_idx], wg_size, viewer_count, false)
			viewer_count += 1
		var length : int = ceili(global.chr_dict[global.focused_string].size() / 100.0)
		emit_signal('section_slider_limit', maxi(length - 1, 0))
		#var retrieve_section = global.substring_viewer_saved_parameters[global.focused_string]['Last Sample Section']
		#emit_signal('section_slider_to', retrieve_section)
#		var marker_x = remap(float(section), 0.0, float(length), -line_length / 2.0, line_length / 2.0) * line_scale
#		emit_signal('set_marker', marker_x)
		global.computed_substrings = global.selected_substrings
		computing = false
		waiting_for_new_map = true
		global.begun_analysis = true
		waiting_for_viewers_to_leave = false

#func _on_chr_list_item_selected(index):
#	if !global.selected_substrings.has(index):
#		global.selected_substrings.append(index)
#	selected_item = index
#	print('selected item: ', str(selected_item))
#	var length : int = ceili(global.chr_dict[global.chr_dict.keys()[selected_item]].size() / 100.0)
#	emit_signal('section_limit', maxi(length - 1, 0))

func _on_section_value_changed(value):
	pass
	#section = value

func _on_section_slider_drag_ended(value_changed):
	if value_changed and first_compute and !computing and auto_run:
		var viewer_count := 0
		_get_sample()
		emit_signal("display_sample")
		emit_signal('new_sample_info')
		for sel_idx in global.computed_substrings:
			global.substring_viewer_saved_parameters[global.chr_dict.keys()[sel_idx]]['Last Sample Section'] = global.section_to_analyze
			#var retrieve_section = global.substring_viewer_saved_parameters[global.chr_dict.keys()[sel_idx]]['Last Sample Section']
			var length_to_compute = global.chr_dict[global.chr_dict.keys()[sel_idx]].size()
			print('length to compute: ', str(length_to_compute))
			var wg_size = calc_wg_size(length_to_compute)
			print('chosen workgroup size: ', str(wg_size))
			emit_signal('match_ui_to', global.chr_dict.keys()[sel_idx])
			_single_binary_compute(global.chr_dict.keys()[sel_idx], wg_size, viewer_count, false)
			viewer_count += 1
#		var marker_x = remap(float(section), 0.0, float(length), -line_length / 2.0, line_length / 2.0) * line_scale
#		emit_signal('set_marker', marker_x)
		computing = false

func _on_section_slider_value_changed(value):
	if first_compute:
		global.section_to_analyze = value
		if !global.low_memory_mode:
			_get_sample()

func _get_sample():
	global.sample = Array(global.chr_dict[global.focused_string]).slice(global.section_to_analyze * 100, (global.section_to_analyze + 1) * 100)
	global.sample_id = global.focused_string
	global.sample_from = global.section_to_analyze * 100
	global.sample_to = (global.section_to_analyze + 1) * 100
	global.legible_sample = int_array_to_acgt_string(global.sample)

func _on_re_analyze_button_button_up():
	if first_compute and !computing:
		var viewer_count := 0
		if !global.custom_sample_enabled:
			global.substring_viewer_saved_parameters[global.focused_string]['Last Sample Section'] = global.section_to_analyze
			global.sample = Array(global.chr_dict[global.focused_string]).slice(global.section_to_analyze * 100, (global.section_to_analyze + 1) * 100)
			global.sample_id = global.focused_string
			global.sample_from = global.section_to_analyze * 100
			global.sample_to = (global.section_to_analyze + 1) * 100
			global.legible_sample = int_array_to_acgt_string(global.sample)
		else:
			global.sample = Array(global.custom_sample_string.split('')).map(acgt_to_int)
			global.sample_id = 'custom'
			global.legible_sample = global.custom_sample_string
		emit_signal("display_sample")
		emit_signal('new_sample_info')
		for sel_idx in global.computed_substrings:
			#var retrieve_section = global.substring_viewer_saved_parameters[global.chr_dict.keys()[sel_idx]]['Last Sample Section']
			var length_to_compute = global.chr_dict[global.chr_dict.keys()[sel_idx]].size()
			print('length to compute: ', str(length_to_compute))
			var wg_size = calc_wg_size(length_to_compute)
			print('chosen workgroup size: ', str(wg_size))
			emit_signal('match_ui_to', global.chr_dict.keys()[sel_idx])
			_single_binary_compute(global.chr_dict.keys()[sel_idx], wg_size, viewer_count, false)
			viewer_count += 1
#		var marker_x = remap(float(section), 0.0, float(length), -line_length / 2.0, line_length / 2.0) * line_scale
#		emit_signal('set_marker', marker_x)
		computing = false

func _on_check_button_toggled(button_pressed):
	auto_run = button_pressed

func _on_vb_forward_check_toggle(button_pressed, id):
	if button_pressed:
		global.focused_string = id
		print('refocusing to: ', id)
		var length : int = ceili(global.chr_dict[id].size() / 100.0)
		emit_signal('section_slider_limit', maxi(length - 1, 0))
		var retrieve_section = global.substring_viewer_saved_parameters[id]['Last Sample Section']
		emit_signal('section_slider_to', retrieve_section)
		emit_signal('uncheck_check_boxes')
		waiting_for_new_map = true
