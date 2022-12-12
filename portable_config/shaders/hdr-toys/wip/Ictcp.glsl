//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Ictcp

vec3 RGB_to_XYZ(float R, float G, float B) {
    mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return vec3(R, G, B) * M;
}

vec3 XYZ_to_RGB(float X, float Y, float Z) {
    mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return vec3(X, Y, Z) * M;
}

vec3 XYZ_to_LMS(float X, float Y, float Z) {
    mat3 M = mat3(
         0.359, 0.696, -0.036,
        -0.192, 1.100,  0.075,
         0.007, 0.075,  0.843);
    return vec3(X, Y, Z) * M;
}

const float c1  =  3424 / 4096;
const float c2  =  2413 / 128;
const float c3  =  2392 / 128;
const float m1  =  2610 / 16384;
const float m2  =  2523 / 32;
const float im1 = 16384 / 2610;
const float im2 =    32 / 2523;

float PQEOTF(float val) {
    float num = c1 + (c2 * pow((val / 10000), m1));
    float den = 1 + (c3 * pow((val / 10000), m1));
    return pow(num / den, m2);
}

vec3 LMS_to_IPT(float L, float M, float S) {
    vec3 VV = vec3(L, M, S);
    VV.r = PQEOTF(VV.r);
    VV.g = PQEOTF(VV.g);
    VV.b = PQEOTF(VV.b);
    mat3 MM = mat3(
         2048 / 4096,   2048 / 4096,      0     ,
         6610 / 4096, -13613 / 4096, 7003 / 4096,
        17933 / 4096, -17390 / 4096, -543 / 4096);
    return VV * MM;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_LMS(color.r, color.g, color.b);
    color.rgb = LMS_to_IPT(color.r, color.g, color.b);
    return color;
}
