// ITU-R BT.2446 Conversion Method C - 6.1.8
// Optional processing of chroma correction above HDR Reference White

// In SDR production, highlight parts are sometimes intentionally expressed as white. The processing
// described in this section is optionally used to shift chroma above HDR Reference White to achromatic
// when the converted SDR content requires a degree of consistency for SDR production content. This
// processing is applied as needed before the tone-mapping processing.

// TODO: fix green tint. (I can't)
// I don't know why, but LCH(150, 100, 0) is not white blanced,
// and the round-trip of functions from BT.2446 are not work properly.
// So I do this in HSV, use "chroma_correction_hsv.glsl" instead.

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

//!PARAM sigma
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.06

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN sigma
//!DESC chroma correction

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

float Xn = 192.93;
float Yn = 203.00;
float Zn = 221.05;

float delta = 6.0 / 29.0;
float deltac = delta * 2.0 / 3.0;

float f1(float x, float delta) {
    return x > pow(delta, 3.0) ?
        pow(x, 1.0 / 3.0) :
        deltac + x / (3.0 * pow(delta, 2.0));
}

float f2(float x, float delta) {
    return x > delta ?
        pow(x, 3.0) :
        (x - deltac) * (3.0 * pow(delta, 2.0));
}

vec3 XYZ_to_Lab(float X, float Y, float Z) {
    X = f1(X / Xn, delta);
    Y = f1(Y / Yn, delta);
    Z = f1(Z / Zn, delta);

    float L = 116.0 * Y - 16.0;
    float a = 500.0 * (X - Y);
    float b = 200.0 * (Y - Z);

    // L = clamp(L, 0.0, 100.0);
    return vec3(L, a, b);
}

vec3 Lab_to_XYZ(float L, float a, float b) {
    float Y = (L + 16.0) / 116.0;
    float X = Y + a / 500.0;
    float Z = Y - b / 200.0;

    X = f2(X, delta) * Xn;
    Y = f2(Y, delta) * Yn;
    Z = f2(Z, delta) * Zn;

    return vec3(X, Y, Z);
}

vec3 Lab_to_LCHab(float L, float a, float b) {
    float C = length(vec2(a, b));
    float H = atan(b, a);

    return vec3(L, C, H);
}

vec3 LCHab_to_Lab(float L, float C, float H) {
    vec2 ab = C * vec2(cos(H), sin(H));
    return vec3(L, ab);
}

float chroma_correction(float L, float Lref, float Lmax, float sigma) {
    float cor = 1.0;
    if (L > Lref)
        cor = max(1.0 - sigma * (L - Lref) / (Lmax - Lref), 0.0);

    return cor;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_LCHab(color.r, color.g, color.b);
    color.g  *= chroma_correction(color.r, 1.0, L_hdr / L_sdr, sigma);
    color.rgb = LCHab_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_RGB(color.r, color.g, color.b);
    return color;
}
