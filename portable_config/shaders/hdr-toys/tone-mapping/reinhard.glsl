// Extended mapping by Reinhard et al. 2002. which allows high luminances to burn out.
// https://www.researchgate.net/publication/2908938_Photographic_Tone_Reproduction_For_Digital_Images

//!PARAM L_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (reinhard)

float curve(float x) {
    return (x * (1.0 + x / pow(L_hdr / L_sdr, 2))) / (1.0 + x);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
