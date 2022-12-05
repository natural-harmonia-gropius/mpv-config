// Scale cd/m^2 to linear code value

//!PARAM WHITE_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!PARAM BLACK_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
0.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC luminance to linear

vec3 Y_2_linCV(vec3 Y, float Ymax, float Ymin) {
    return (Y - Ymin) / (Ymax - Ymin);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = Y_2_linCV(color.rgb, WHITE_sdr, BLACK_sdr);
    return color;
}
