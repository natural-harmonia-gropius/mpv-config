//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (lightness, chroma)

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

vec3 XYZn = RGB_to_XYZ(L_sdr, L_sdr, L_sdr);
float Xn = XYZn.x;
float Yn = XYZn.y;
float Zn = XYZn.z;

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

const float C_ref = dot(vec3(1.0, 1.0, 1.0), vec3(104.55, 119.78, 133.81)) / 3.0;
const float C_max = dot(vec3(1.0, 1.0, 1.0), vec3(154.49, 208.07, 147.92)) / 3.0;

const float alpha = (C_max - C_ref) / C_ref;
const float beta  = 0.25;

float curve(float r, float a, float b) {
    if (r <= 1.0 - b) {
        r = r;
    } else if (1.0 - b < r && r <= 1.0 + a) {
        r = r - (a / pow(b - a, 2.0)) * sqrt(pow(b, 2.0) + (a - b) * (r + b - 1.0));
    } else if (r > 1.0 + a) {
        r = 1.0;
    }

    return r;
}

mat3 M = mat3(
     1.6605, -0.5876, -0.0728,
    -0.1246,  1.1329, -0.0083,
    -0.0182, -0.1006,  1.1187);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    // const float C = dot(color.rgb, vec3(104.55, 119.78, 133.81)) / 3.0;
    // color.g  *= C_ref / C;
    // const float H_delta = dot(color.rgb, vec3(-0.58, -9.9, 0.69) / 360.0);
    // color.b  += H_delta;

    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_LCHab(color.r, color.g, color.b);
    vec4 color2 = color;

    color.rgb = LCHab_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_RGB(color.r, color.g, color.b);
    color.rgb = max(color.rgb, 0.0);
    color.rgb *= M;
    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_Lab(color.r, color.g, color.b);
    color.rgb = Lab_to_LCHab(color.r, color.g, color.b);

    color2.r = color.r;
    color2.g = color.g;
    color2.rgb = LCHab_to_Lab(color2.r, color2.g, color2.b);
    color2.rgb = Lab_to_XYZ(color2.r, color2.g, color2.b);
    color2.rgb = XYZ_to_RGB(color2.r, color2.g, color2.b);
    color2.rgb = max(color2.rgb, 0.0);

    return color2;
}