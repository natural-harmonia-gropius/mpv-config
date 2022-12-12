//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Jzazbz

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

vec3 XYZ_to_Cone(float X, float Y, float Z) {
    mat3 M = mat3(
         0.41478972, 0.579999,  0.0146480,
        -0.2015100,  1.120649,  0.0531008,
        -0.0166008,  0.264800,  0.6684799);
    return vec3(X, Y, Z) * M;
}

vec3 Cone_to_Iab(float L, float M, float S) {
    mat3 MM = mat3(
             0.5,       0.5,         0,
        3.524000, -4.066708,  0.542708,
        0.199076,  1.096799, -1.295875);
    return vec3(L, M, S) * MM;
}

const float pi = 3.141592653589793;

vec3 Jab_to_Jch(float J, float a, float b) {
    const float c = sqrt(pow(a, 2.0) + pow(b, 2.0));

    float h = 0.0;
    const float e = 0.0002;
    if (!(a < e && b < e)) {
        h = atan(a, b) * 180 / pi;
        // h = ((h % 360.0) + 360.0) % 360.0;
    }

    return vec3(J, c, h);
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

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);

    float b = 1.15;
    float g = 0.66;

    float Xm = (b * color.x) - ((b - 1.0) * color.z);
    float Ym = (g * color.y) - ((g - 1.0) * color.x);

    color.rgb = XYZ_to_Cone(Xm, Ym, color.z);

    color.r = PQEOTF(color.r);
    color.g = PQEOTF(color.g);
    color.b = PQEOTF(color.b);

    color.rgb = Cone_to_Iab(color.r, color.g, color.b);

    float d = -0.56;
    float d0 = 1.6295499532821566E-11;

    color.r = ((1.0 + d) * color.r) / (1.0 + (d * color.r)) - d0;

    return color;
}
