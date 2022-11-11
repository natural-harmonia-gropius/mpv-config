// "film-like" tonemap, by Jim Hejl.
// https://twitter.com/jimhejl/status/633777619998130176

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (hejl2015)

const float WHITE = 203.0;
const float PEAK  = 1000.0;
const float L_w   = PEAK / WHITE;   // White Point

float f(float x) {
    float vh = x;
    float va = (1.425 * vh) + 0.05;
    float vf = ((vh * va + 0.004) / ((vh * (va + 0.55) + 0.0491))) - 0.0821;
    return vf;
}

float curve(float x) {
    return f(x) / f(L_w);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
