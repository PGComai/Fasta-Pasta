#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer MyPositionXBuffer {
	float data[];
}
my_position_x_buffer;
layout(set = 0, binding = 1, std430) restrict buffer MyPositionYBuffer {
	float data[];
}
my_position_y_buffer;
layout(set = 0, binding = 2, std430) restrict buffer MyPositionZBuffer {
	float data[];
}
my_position_z_buffer;
layout(set = 0, binding = 3, std430) restrict buffer MyValueBuffer {
	int data[];
}
my_value_buffer;

layout(set = 1, binding = 0, std430) restrict buffer MyColorRBuffer {
	float data[];
}
my_color_r_buffer;
layout(set = 1, binding = 1, std430) restrict buffer MyColorGBuffer {
	float data[];
}
my_color_g_buffer;
layout(set = 1, binding = 2, std430) restrict buffer MyColorBBuffer {
	float data[];
}
my_color_b_buffer;
//float webby_force(float dist) {
//	//return clamp(pow(dist, 16.0), 0.0, 10.0);
//	float force_reversal_dist = 0.2;
//	return clamp(pow((dist - force_reversal_dist) * 400.0, 1.8), -400.0, 400.0);
//}

// The code we want to execute in each invocation
void main() {
	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z));
//	vec3 position = vec3(float(location + 1) / 1000.0, float(my_value_buffer.data[location]) * 2.0, my_position_z_buffer.data[location]);
	
//	vec3 newposition = position;
	
	my_position_x_buffer.data[location] = float(location + 1) / 1000.0;
	my_position_y_buffer.data[location] = float(my_value_buffer.data[location]) * 2.0;
	my_position_z_buffer.data[location] = my_position_z_buffer.data[location];
	my_color_r_buffer.data[location] = 255.0 - float(my_value_buffer.data[location]);
}
