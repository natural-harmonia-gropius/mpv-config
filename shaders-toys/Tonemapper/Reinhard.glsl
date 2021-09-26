//!HOOK MAIN
//!BIND HOOKED
//!DESC Reinhard Tone Mapping

// "Extended Reinhard" described by Reinhard et al.
float curve(float x) {
    const float L_white = 4.0;  // whitePreserving
    return (x * (1.0 + x / (L_white * L_white))) / (1.0 + x);
}

vec3 mode_rgb(vec3 x) {
    return vec3(curve(x.r), curve(x.g), curve(x.b));
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_rgb(p.rgb);
    return p;
}
