// Adjusts the linear exposure value by scaling the input by the values in bias.

//!PARAM bias
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1.0

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN bias 1 -
//!DESC exposure scaling

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= bias;
    return color;
}
