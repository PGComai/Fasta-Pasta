#[compute]
#version 450

layout(local_size_x = 9, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer MyResultBuffer {
	int data[];
}
my_result_buffer;
layout(set = 0, binding = 1, std430) restrict buffer MyDataBuffer {
	int data[];
}
my_data_buffer;

// The code we want to execute in each invocation
void main() {
	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z)) + 1;
	uint big_location = location * 9;
	uint sub_location = big_location - (gl_LocalInvocationIndex + 1);
	int value = my_data_buffer.data[sub_location] * int(pow(10, int(gl_LocalInvocationIndex)));
	
	memoryBarrierShared();
    barrier();
	
	atomicAdd(my_result_buffer.data[location - 1], value);
}
