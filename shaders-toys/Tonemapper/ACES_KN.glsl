//!HOOK MAIN
//!BIND HOOKED
//!DESC Krzysztof Narkowicz's ACES Tone Mapping

// ACES Filmic Tone Mapping Curve fit by Krzysztof Narkowicz.
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float curve(float x) {
    x *= 0.6;
    const float A = 2.51;
    const float B = 0.03;
    const float C = 2.43;
    const float D = 0.59;
    const float E = 0.14;
    return (x * (A * x + B)) / (x * (C * x + D) + E);
}

vec3 mode_rgb(vec3 x) {
    return vec3(curve(x.r), curve(x.g), curve(x.b));
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_rgb(p.rgb);
    return p;
}
