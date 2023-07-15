#[compute]
#version 450

layout(local_size_x = 169, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
	int data[];
}
my_data_buffer;
layout(set = 0, binding = 1, rgba32f) uniform image2D img_in;
layout(set = 0, binding = 2, rgba32f) uniform image2D img_out;

uint remap(int likeness) {
	return uint(100 + (likeness - 0)) * ((1080 - 0) / (100 - 0));
}

// The code we want to execute in each invocation
void main() {
	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z));
	uint big_location = location * 169;
	uint sub_location = big_location + gl_LocalInvocationIndex;
	uint pixel_height = remap(my_data_buffer.data[sub_location]);
}
