#[compute]
#version 450

layout(local_size_x = 10, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer MyResultBuffer {
	int data[];
}
my_result_buffer;
layout(set = 0, binding = 1, std430) restrict buffer MyDataBuffer {
	int data[];
}
my_data_buffer;
//layout(set = 0, binding = 2, rgba32f) uniform image2D img_in;
//layout(set = 0, binding = 3, rgba32f) uniform image2D img_out;

int compare(int c1, int c2) {
	return int(c1 == c2);
}

// The code we want to execute in each invocation
void main() {
	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z));
	uint big_location = location * 10;
	uint sub_location = big_location + gl_LocalInvocationIndex;
	int comparison_result = compare(int(my_data_buffer.data[sub_location]), int(my_data_buffer.data[gl_LocalInvocationIndex]));
	
	memoryBarrierShared();
    barrier();
	
	atomicAdd(my_result_buffer.data[location], comparison_result);
}
