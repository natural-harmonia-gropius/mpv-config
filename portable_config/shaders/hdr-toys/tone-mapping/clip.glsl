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
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
