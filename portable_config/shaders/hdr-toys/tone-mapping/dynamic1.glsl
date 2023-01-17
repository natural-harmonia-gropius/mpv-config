//!PARAM L_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!BUFFER buf_storage
//!VAR int L_max2
//!STORAGE
00000000

//!HOOK OUTPUT
//!BIND HOOKED
//!COMPUTE 32 32
//!DESC tone mapping (dynamic, compute)

shared int L_max;

void metering() {
    ivec2 base = ivec2(gl_WorkGroupID) * ivec2(gl_WorkGroupSize);
    for (uint y = gl_LocalInvocationID.y; y < gl_WorkGroupSize.y; y++) {
        for (uint x = gl_LocalInvocationID.x; x < gl_WorkGroupSize.x; x++) {
            vec4 texelValue = texelFetch(HOOKED_raw, base + ivec2(x,y), 0);
            float L = L_sdr * dot(texelValue.rgb, vec3(0.2627, 0.6780, 0.0593));
            atomicMax(L_max, int(L));
        }
    }
}

float curve(float x, float w) {
    const float simple = x / (1.0 + x);
    const float extended = simple * (1.0 + x / (w * w));
    return extended;
}

void hook() {
    atomicMax(L_max, int(L_sdr));

    metering();

    barrier();

    vec4 color = HOOKED_tex(HOOKED_pos);
    float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L, L_max / L_sdr) / L;

    imageStore(out_image, ivec2(gl_GlobalInvocationID), color);
}
