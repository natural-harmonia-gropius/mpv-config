// ITU-R BT.2446 Conversion Method C
// https://www.itu.int/pub/R-REP-BT.2446

// TODO: chroma_correction causes green tint.

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC chroma correction (bt.2446c)

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

    L = clamp(L, 0.0, 100.0);
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

vec3 chroma_correction(float L, float C, float H, float Lref, float Lmax, float sigma) {
    if (L > Lref) {
        float cor = 1.0 - sigma * (L - Lref) / (Lmax - Lref);
        cor = max(cor, 0.0);
        C *= cor;
        C = clamp(C, 0.0, 150.0);
    }
    return vec3(L, C, H);
}

const float WHITE = 203.0;
const float PEAK  = 1000.0;
const float L_w   = PEAK / WHITE;   // White Point

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float sigma = 1.00;   // 0 <= sigma <= 1

    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_LCHab(color.r, color.g, color.b);
    color.rgb = chroma_correction(color.r, color.g, color.b, 1.0, L_w, 1);
    color.rgb = LCHab_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_RGB(color.r, color.g, color.b);

    return color;
}
