//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (linear)

float curve(float x) {
    const float WHITE = 203.0;
    const float PEAK  = 1000.0;
    return x * WHITE / PEAK;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
