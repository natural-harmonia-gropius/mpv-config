//!HOOK MAIN
//!BIND HOOKED
//!DESC Reinhard Tone Mapping (Relative luminance)

// "Extended Reinhard" described by Reinhard et al.
float curve(float x) {
    const float L_white = 4.0;  // whitePreserving
    return (x * (1.0 + x / (L_white * L_white))) / (1.0 + x);
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
