// Clip the code value out of sdr range.

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (clip)

float curve(float x) {
    const float WHITE = 1.0;
    const float BLACK = WHITE / CONTRAST_sdr;

    x = (x - BLACK) / (WHITE - BLACK);
    x = clamp(x, 0.0, WHITE);
    return x;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.r = curve(color.r);
    color.g = curve(color.g);
    color.b = curve(color.b);
    return color;
}
