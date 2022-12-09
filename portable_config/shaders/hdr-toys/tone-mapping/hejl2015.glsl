// "film-like" tonemap, by Jim Hejl.
// https://twitter.com/jimhejl/status/633777619998130176

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

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (hejl2015)

float f(float x) {
    float a = (1.425 * x) + 0.05;
    return ((x * a + 0.004) / ((x * (a + 0.55) + 0.0491))) - 0.0821;
}

float curve(float x) {
    const float w = L_hdr / L_sdr;
    float a = f(x) / f(w);
    return max(a, 0.0);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
