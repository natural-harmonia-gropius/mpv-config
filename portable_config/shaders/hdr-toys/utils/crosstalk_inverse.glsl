//!PARAM alpha
//!TYPE float
//!MINIMUM 0.00
//!MAXIMUM 0.33
0.1

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC crosstalk-inverse

vec3 crosstalk_inv(vec3 x, float a) {
    float b = 1.0 - a;
    float c = 1.0 - 3.0 * a;
    mat3  M = mat3(
         b, -a, -a,
        -a,  b, -a,
        -a, -a,  b) / c;
    return M * x;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = crosstalk_inv(color.rgb, alpha);
    return color;
}