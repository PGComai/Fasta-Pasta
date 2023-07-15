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
layout(set = 0, binding = 3, std430) restrict buffer MyPointerVec {
	float data[];
}
my_pointer_vec;
layout(set = 0, binding = 4, std430) restrict buffer MyPointerNearest {
	float data[];
}
my_pointer_nearest;

// The code we want to execute in each invocation
void main() {
	float dist_from_pointer = 1000.0;
	vec3 pointer_vec = vec3(my_pointer_vec.data[0], my_pointer_vec.data[1], my_pointer_vec.data[2]);
	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z));
	vec3 position = vec3(my_position_x_buffer.data[location], my_position_y_buffer.data[location], my_position_z_buffer.data[location]);
	float measured_dist_from_pointer = distance(pointer_vec, position);
	
	my_pointer_nearest.data[location] = measured_dist_from_pointer;
}
