// The simplest tone mapping method, just multiplied by a number.

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (linear)

const float WHITE = 203.0;
const float PEAK  = 1000.0;
const float L_w   = PEAK / WHITE;   // White Point

float curve(float x) {
    return x / L_w;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
