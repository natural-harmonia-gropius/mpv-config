// ITU-R BT.2446 Conversion Method C
// https://www.itu.int/pub/R-REP-BT.2446

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (bt.2446c)

vec3 RGB_to_XYZ(float R, float G, float B) {
    mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return M * vec3(R, G, B);
}

vec3 XYZ_to_RGB(float X, float Y, float Z) {
    mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return M * vec3(X, Y, Z);
}

vec3 XYZ_to_xyY(float X, float Y, float Z) {
    float divisor = X + Y + Z;
    if (divisor == 0.0) divisor = 1e-10;

    float x = X / divisor;
    float y = Y / divisor;

    return vec3(x, y, Y);
}

vec3 xyY_to_XYZ(float x, float y, float Y) {
    float X = x * Y / max(y, 1e-10);
    float Z = (1.0 - x - y) * Y / max(y, 1e-10);

    return vec3(X, Y, Z);
}

float tone_mapping(float Y, float k1, float k3, float ip) {
    ip /= k1;
    float k2 = (k1 * ip) * (1.0 - k3);
    float k4 = (k1 * ip) - (k2 * log(1.0 - k3));
    return Y < ip ?
        Y * k1 :
        log((Y / ip) - k3) * k2 + k4;
}

const float k1 = 0.69;      // In book: 0.83802
const float k3 = 0.74204;
const float ip = 0.49;      // In book: 80% SDR, 58.5 of 100 cd/m2

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_xyY(color.r, color.g, color.b);
    color.z   = tone_mapping(color.z, k1, k3, ip);
    color.rgb = xyY_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_RGB(color.r, color.g, color.b);
    return color;
}