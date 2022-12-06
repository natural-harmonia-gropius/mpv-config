// Heatmap of luminance

//!PARAM WHITE_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (heatmap)

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));

    const float l0 =     1.0 / CONTRAST_sdr;
    const float l1 =     1.0;
    const float l2 =  1000.0 / WHITE_sdr;
    const float l3 =  2000.0 / WHITE_sdr;
    const float l4 =  4000.0 / WHITE_sdr;
    const float l5 = 10000.0 / WHITE_sdr;

    if (L > l5) {
        color.rgb = vec3(1.0, 0.0, 0.6);
    } else if (L > l4) {
        const float a = (L - l4) / (l5 - l4);
        color.rgb = vec3(1.0, 1.0, a);
    } else if (L > l3) {
        const float a = (L - l3) / (l4 - l3);
        color.rgb = vec3(a, 0.0, 0.0);
    } else if (L > l2) {
        const float a = (L - l2) / (l3 - l2);
        color.rgb = vec3(0.0, a, 0.0);
    } else if (L > l1) {
        const float a = (L - l1) / (l2 - l1);
        color.rgb = vec3(0.0, 0.0, a);
    } else if (L < l0) {
        color.rgb = vec3(0.0, 0.0, 0.0);
    } else {
        color.rgb = vec3(L, L, L);
    }
    return color;
}
