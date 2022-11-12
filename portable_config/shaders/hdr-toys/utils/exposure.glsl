// Adjusts the linear exposure value by scaling the input by the values in bias.

//!PARAM bias
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 100
1.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC exposure scaling
//!WHEN bias 0 >
// bias != 1

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= bias;
    return color;
}
