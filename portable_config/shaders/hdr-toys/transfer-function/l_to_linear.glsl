//!HOOK OUTPUT
//!BIND HOOKED
//!DESC luminance to linear

const float L_WHITE = 203.0;
const float L_BLACK = 0.0;
// Scale cd/m^2 to linear code value
vec3 Y_2_linCV(vec3 Y, float Ymax, float Ymin) {
    return (Y - Ymin) / (Ymax - Ymin);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = Y_2_linCV(color.rgb, L_WHITE, L_BLACK);
    return color;
}