// "film-like" tonemap, by Jim Hejl.
// https://twitter.com/jimhejl/status/633777619998130176

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (hejl2015)

const float WHITE = 203.0;
const float PEAK  = 1000.0;
const float L_w   = PEAK / WHITE;   // White Point

float f(float x) {
    float a = (1.425 * x) + 0.05;
    return ((x * a + 0.004) / ((x * (a + 0.55) + 0.0491))) - 0.0821;
}

float curve(float x) {
    float a = f(x) / f(L_w);
    return max(a, 0.0);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
