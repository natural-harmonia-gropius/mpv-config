//!HOOK MAIN
//!BIND HOOKED
//!DESC no idea: Linear Tone Mapping (Hybrid)

float curve(float x) {
    const float WHITE = 203;
    const float PEAK  = 10000;
	return x * WHITE / PEAK;
}

vec3 mode_rgb(vec3 x) {
    return vec3(curve(x.r), curve(x.g), curve(x.b));
}

float y(vec3 x) {
    // https://en.wikipedia.org/wiki/Relative_luminance
    return dot(x, vec3(0.2126, 0.7152, 0.0722));
}

vec3 mode_y(vec3 x) {
    const float Y = y(x);
    return x * curve(Y) / Y;
}

vec3 mode_hybrid(vec3 x) {
    // const float Y = y(x);
    // return Y <= y(vec3(1.0)) ? mode_y(x) : mode_rgb(x);

    const float Y = y(x);
    const vec3 M1 = mode_rgb(x);
    const vec3 M2 = mode_y(x);
    return M1 * 0.6 + M2 * 0.4;
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_hybrid(p.rgb);
    return p;
}
