//!HOOK MAIN
//!BIND HOOKED
//!DESC Crosstalk matrix

vec3 crosstalk(vec3 x) {
    const float a = 0.05;
    const float b = 1 - (2 * a);
    const mat3  M = mat3(
        b, a, a,
        a, b, a,
        a, a, b);
    return M * x;
}

vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    color.rgb = crosstalk(color.rgb);
    return color;
}
