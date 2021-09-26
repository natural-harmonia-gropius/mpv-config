//!HOOK MAIN
//!BIND HOOKED
//!DESC Inverse Crosstalk matrix

vec3 crosstalk_inv(vec3 x) {
    const float a = 0.05;
    const float b = 1 - a;
    const float c = 1 - (3 * a);
    const mat3  M = mat3(
         b, -a, -a,
        -a,  b, -a,
        -a, -a,  b) / c;
    return M * x;
}

vec4 color = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    color.rgb = crosstalk_inv(color.rgb);
    return color;
}
