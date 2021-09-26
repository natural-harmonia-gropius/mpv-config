//!HOOK MAIN
//!BIND HOOKED
//!DESC Linear Tone Mapping (Relative luminance)

float curve(float x) {
    const float WHITE = 203;
    const float PEAK  = 10000;
	return x * WHITE / PEAK;
}

float y(vec3 x) {
    // https://en.wikipedia.org/wiki/Relative_luminance
    return dot(x, vec3(0.2126, 0.7152, 0.0722));
}

vec3 mode_y(vec3 x) {
    const float Y = y(x);
    return x * curve(Y) / Y;
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_y(p.rgb);
    return p;
}
