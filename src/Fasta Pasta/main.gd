extends Control

signal add_item(item)
signal make_line(arr, colors, length, set_pos, id)
signal section_limit(lim)
signal section_slider_limit(lim)
signal section_slider_to(sec)
signal set_marker(x)
signal reset_zoom

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
var workgroup_cube_size := 115
var substring_param := {
	"Viewing Position" : 0,
	"Zoom" : 0.0,
	"Line Length" : 0.0,
	"Home X" : 0.0,
	"X Adjustment" : 0.0,
	"Zoomed Length" : 0.0,
	"Zoom Home" : 0.0,
	"Line Scale" : 0.0,
	"Sample Section" : 0
}

# Called when the node enters the scene tree for the first time.
func _ready():
	global = get_node("/root/Global")
	chr_dict = global.substring_dict


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_load_button_button_up():
	_read_fasta()


func _on_file_path_text_changed(new_text):
	filepath = new_text
	filepath = filepath.replace('\\', '/')


func _on_file_path_text_submitted(new_text):
	_read_fasta()

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
	filepath = filepath.replace('"', '')
	print(filepath)
	if FileAccess.file_exists(filepath):
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
				chr_dict[newsplit[0]] = Array(newstr.split('')).map(acgt_to_int)
		print(chr_dict.keys())
		for chr_k in chr_dict.keys():
			emit_signal('add_item', str(chr_k, ' - ', len(chr_dict[chr_k])))
			global.substring_viewer_saved_parameters[str(chr_k)] = substring_param
		print(global.substring_viewer_saved_parameters)
	else:
		print('bad path')

func _single_binary_compute(chr: Array, section: int, id: String, workgroup_size: int):
	var data_array := PackedInt32Array(chr)
	
	var length : int = ceili(data_array.size() / 100.0)
	
	var line_length = float(length) / 1000.0
	var line_scale = 1000.0 / line_length
	var home_x = (-float(line_length) / 2.0)
	
	var marker_x = remap(float(section), 0.0, float(length), -line_length / 2.0, line_length / 2.0) * line_scale
	
	emit_signal('set_marker', marker_x)
	
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
	
	# Load GLSL shader
	var shader_file := load("res://fasta_comp_binary.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var input_result := result_array
	var input_result_bytes := input_result.to_byte_array()
	var input_data := data_array
	var input_data_bytes := input_data.to_byte_array()
	var input_param := param_array
	var input_param_bytes := input_param.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	var buffer_result := rd.storage_buffer_create(input_result_bytes.size(), input_result_bytes)
	var buffer_data := rd.storage_buffer_create(input_data_bytes.size(), input_data_bytes)
	var buffer_param := rd.storage_buffer_create(input_param_bytes.size(), input_param_bytes)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform_result := RDUniform.new()
	uniform_result.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_result.binding = 0 # this needs to match the "binding" in our shader file
	uniform_result.add_id(buffer_result)
	var uniform_data := RDUniform.new()
	uniform_data.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_data.binding = 1 # this needs to match the "binding" in our shader file
	uniform_data.add_id(buffer_data)
	var uniform_param := RDUniform.new()
	uniform_param.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_param.binding = 2 # this needs to match the "binding" in our shader file
	uniform_param.add_id(buffer_param)
	
	var uniform_set := rd.uniform_set_create([uniform_result, uniform_data, uniform_param], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	
	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, workgroup_size, workgroup_size, workgroup_size)
	rd.compute_list_end()
	
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	# Read back the data from the buffer
	var output_result_bytes := rd.buffer_get_data(buffer_result)
	var output_result := output_result_bytes.to_int32_array()
	#print(output_result.slice(0, 100))
	
	rd.free_rid(buffer_result)
	rd.free_rid(buffer_data)
	rd.free_rid(buffer_param)
	
	_compute_linemesh(output_result, length, id, result_array_size, workgroup_size)

func _compute_linemesh(chr: Array, len_arr: int, id: String, result_array_size: int, workgroup_size: int):
	var value_array := PackedInt32Array(chr)
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
	
	var shader_file := load("res://line.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	var input_value_bytes := value_array.to_byte_array()
	var input_pos_x_bytes := pos_x_array.to_byte_array()
	var input_pos_y_bytes := pos_y_array.to_byte_array()
	var input_pos_z_bytes := pos_z_array.to_byte_array()
	var input_color_r_bytes := color_r_array.to_byte_array()
	var input_color_g_bytes := color_r_array.to_byte_array()
	var input_color_b_bytes := color_r_array.to_byte_array()
	
	var buffer_value := rd.storage_buffer_create(input_value_bytes.size(), input_value_bytes)
	var buffer_pos_x := rd.storage_buffer_create(input_pos_x_bytes.size(), input_pos_x_bytes)
	var buffer_pos_y := rd.storage_buffer_create(input_pos_y_bytes.size(), input_pos_y_bytes)
	var buffer_pos_z := rd.storage_buffer_create(input_pos_z_bytes.size(), input_pos_z_bytes)
	var buffer_color_r := rd.storage_buffer_create(input_color_r_bytes.size(), input_color_r_bytes)
	var buffer_color_g := rd.storage_buffer_create(input_color_g_bytes.size(), input_color_g_bytes)
	var buffer_color_b := rd.storage_buffer_create(input_color_b_bytes.size(), input_color_b_bytes)
	
	var uniform_pos_x := RDUniform.new()
	uniform_pos_x.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_pos_x.binding = 0 # this needs to match the "binding" in our shader file
	uniform_pos_x.add_id(buffer_pos_x)
	var uniform_pos_y := RDUniform.new()
	uniform_pos_y.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_pos_y.binding = 1 # this needs to match the "binding" in our shader file
	uniform_pos_y.add_id(buffer_pos_y)
	var uniform_pos_z := RDUniform.new()
	uniform_pos_z.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_pos_z.binding = 2 # this needs to match the "binding" in our shader file
	uniform_pos_z.add_id(buffer_pos_z)
	var uniform_value := RDUniform.new()
	uniform_value.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_value.binding = 3 # this needs to match the "binding" in our shader file
	uniform_value.add_id(buffer_value)
	
	var uniform_set := rd.uniform_set_create([uniform_pos_x, uniform_pos_y, uniform_pos_z, uniform_value], shader, 0)
	
	var uniform_color_r := RDUniform.new()
	uniform_color_r.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_color_r.binding = 0 # this needs to match the "binding" in our shader file
	uniform_color_r.add_id(buffer_color_r)
	var uniform_color_g := RDUniform.new()
	uniform_color_g.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_color_g.binding = 1 # this needs to match the "binding" in our shader file
	uniform_color_g.add_id(buffer_color_g)
	var uniform_color_b := RDUniform.new()
	uniform_color_b.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_color_b.binding = 2 # this needs to match the "binding" in our shader file
	uniform_color_b.add_id(buffer_color_b)
	
	var uniform_set_1 := rd.uniform_set_create([uniform_color_r, uniform_color_g, uniform_color_b], shader, 1)
	
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_1, 1)
	rd.compute_list_dispatch(compute_list, workgroup_size, workgroup_size, workgroup_size)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()
	
	var output_pos_x_bytes := rd.buffer_get_data(buffer_pos_x)
	var output_pos_y_bytes := rd.buffer_get_data(buffer_pos_y)
	var output_pos_z_bytes := rd.buffer_get_data(buffer_pos_z)
	
	var output_pos_x := output_pos_x_bytes.to_float32_array()
	var output_pos_y := output_pos_y_bytes.to_float32_array()
	var output_pos_z := output_pos_z_bytes.to_float32_array()
	
	var output_color_r_bytes := rd.buffer_get_data(buffer_color_r)
	var output_color_g_bytes := rd.buffer_get_data(buffer_color_g)
	var output_color_b_bytes := rd.buffer_get_data(buffer_color_b)
	
	var output_color_r := output_color_r_bytes.to_float32_array()
	var output_color_g := output_color_g_bytes.to_float32_array()
	var output_color_b := output_color_b_bytes.to_float32_array()
	
	var vec_array := PackedVector3Array()
	var color_array := PackedColorArray()
	
	for i in result_array_size:
		vec_array.append(Vector3(output_pos_x[i], output_pos_y[i], output_pos_z[i]))
		color_array.append(Color(output_color_r[i], output_color_g[i], output_color_b[i]))
	
	print(vec_array.slice(0, 10))
	print(color_array.slice(0, 10))
	emit_signal('make_line', vec_array, color_array, len_arr, reset_mesh_pos, id)
	
	rd.free_rid(buffer_value)
	rd.free_rid(buffer_pos_x)
	rd.free_rid(buffer_pos_y)
	rd.free_rid(buffer_pos_z)
	rd.free_rid(buffer_color_r)
	rd.free_rid(buffer_color_g)
	rd.free_rid(buffer_color_b)
	
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

func _on_analyze_button_button_up():
	#_compute(chr_dict[chr_dict.keys()[selected_item]], 100)
	#_compute_compress(chr_dict[chr_dict.keys()[selected_item]])
	if !computing:
		if (analyzed_item != selected_item) or !first_compute:
			reset_mesh_pos = true
			emit_signal('reset_zoom')
		computing = true
		analyzed_item = selected_item
		var length : int = ceili(chr_dict[chr_dict.keys()[analyzed_item]].size() / 100.0)
		emit_signal('section_slider_limit', maxi(length - 1, 0))
		_single_binary_compute(chr_dict[chr_dict.keys()[selected_item]], section, chr_dict.keys()[selected_item], 115)
		emit_signal('section_slider_to', section)
		computing = false

func _on_chr_list_item_selected(index):
	if !global.selected_substrings.has(index):
		global.selected_substrings.append(index)
	selected_item = index
	print(selected_item)
	var length : int = ceili(chr_dict[chr_dict.keys()[selected_item]].size() / 100.0)
	emit_signal('section_limit', maxi(length - 1, 0))

func _on_section_value_changed(value):
	section = value

func _on_section_slider_drag_ended(value_changed):
	if value_changed and first_compute and !computing and auto_run:
		reset_mesh_pos = false
		computing = true
		var length_to_compute = chr_dict[chr_dict.keys()[analyzed_item]].size()
		print('length to compute: ', str(length_to_compute))
		var wg_size: int
		if length_to_compute <= 12500000:
			wg_size = 50
		elif length_to_compute <= 42187500:
			wg_size = 75
		elif length_to_compute <= 100000000:
			wg_size = 100
		else:
			wg_size = 115
		print('chosen workgroup size: ', str(wg_size))
		_single_binary_compute(chr_dict[chr_dict.keys()[analyzed_item]], analyze_section, chr_dict.keys()[analyzed_item], wg_size)
		computing = false

func _on_section_slider_value_changed(value):
	analyze_section = value

func _on_sample_choice_value_changed(value):
	analyze_section = value

func _on_re_analyze_button_button_up():
	if first_compute and !computing:
		reset_mesh_pos = false
		computing = true
		var length_to_compute = chr_dict[chr_dict.keys()[analyzed_item]].size()
		print('length to compute: ', str(length_to_compute))
		var wg_size: int
		if length_to_compute <= 12500000:
			wg_size = 50
		elif length_to_compute <= 42187500:
			wg_size = 75
		elif length_to_compute <= 100000000:
			wg_size = 100
		else:
			wg_size = 115
		print('chosen workgroup size: ', str(wg_size))
		_single_binary_compute(chr_dict[chr_dict.keys()[analyzed_item]], analyze_section, chr_dict.keys()[analyzed_item], wg_size)
		computing = false

func _on_check_button_toggled(button_pressed):
	auto_run = button_pressed

func _on_chr_list_multi_selected(index, selected):
	if !global.selected_substrings.has(index) and selected:
		global.selected_substrings.append(index)
	elif global.selected_substrings.has(index) and !selected:
		global.selected_substrings.erase(index)
