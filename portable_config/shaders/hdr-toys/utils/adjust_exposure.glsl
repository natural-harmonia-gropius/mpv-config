//!PARAM bias
//!TYPE float
//!MINIMUM 0
2.03

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC adjust exposure
//!WHEN exposure 0 >

// Adjusts the code value by exposure.
vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= bias;
    return color;
}
