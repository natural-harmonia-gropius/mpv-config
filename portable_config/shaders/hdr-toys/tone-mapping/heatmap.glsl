// Heatmap

//!PARAM L_METHOD
//!TYPE int
//!MINIMUM 0
//!MAXIMUM 4
0

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

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN L_METHOD
//!DESC tone mapping (heatmap)

vec3 RGB_to_XYZ(float R, float G, float B) {
    mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return M * vec3(R, G, B);
}

vec3 XYZ_to_xyY(float X, float Y, float Z) {
    float divisor = X + Y + Z;
    if (divisor == 0.0) divisor = 1e-6;

    float x = X / divisor;
    float y = Y / divisor;

    return vec3(x, y, Y);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    float L = 0.0;
    if (L_METHOD == 1) {
        // Relative luminance
        L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    } else if (L_METHOD == 2) {
        // Max Code Value
        L = max(max(color.r, color.g), color.b);
    } else if (L_METHOD == 3) {
        // Average Code Value
        L = (color.r + color.g + color.b) / 3;
    } else if (L_METHOD == 4) {
        // CIE xyY;
        vec3 XYZ = RGB_to_XYZ(color.r, color.g, color.b);
        vec3 xyY = XYZ_to_xyY(XYZ.x, XYZ.y, XYZ.z);
        L = xyY.z;
    }

    const float l0 =     1.0 / CONTRAST_sdr;
    const float l1 =     1.0;
    const float l2 =  1000.0 / L_sdr;
    const float l3 =  2000.0 / L_sdr;
    const float l4 =  4000.0 / L_sdr;
    const float l5 = 10000.0 / L_sdr;

    if (L > l5) {
        color.rgb = vec3(1.0, 0.0, 0.6);
    } else if (L > l4) {
        float a = (L - l4) / (l5 - l4);
        a = max(a - 0.1, 0.0) / 0.9 + 0.1;
        color.rgb = vec3(1.0, 1.0, a);
    } else if (L > l3) {
        float a = (L - l3) / (l4 - l3);
        a = max(a - 0.1, 0.0) / 0.9 + 0.1;
        color.rgb = vec3(a, 0.0, 0.0);
    } else if (L > l2) {
        float a = (L - l2) / (l3 - l2);
        a = max(a - 0.1, 0.0) / 0.9 + 0.1;
        color.rgb = vec3(0.0, a, 0.0);
    } else if (L > l1) {
        float a = (L - l1) / (l2 - l1);
        a = max(a - 0.1, 0.0) / 0.9 + 0.1;
        color.rgb = vec3(0.0, 0.0, a);
    } else if (L < l0) {
        color.rgb = vec3(0.0, 0.0, 0.0);
    } else {
        color.rgb = vec3(L, L, L);
    }
    return color;
}
