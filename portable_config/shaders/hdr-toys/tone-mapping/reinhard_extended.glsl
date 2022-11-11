// From "Photographic Tone Reproduction For Digital Images" by Reinhard et al. 2002.
// https://www.researchgate.net/publication/2908938_Photographic_Tone_Reproduction_For_Digital_Images

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (reinhard_extended)

const float WHITE = 203.0;
const float PEAK  = 1000.0;
const float L_w   = PEAK / WHITE;   // White Point

float curve(float x) {
    return (x * (1.0 + x / (L_w * L_w))) / (1.0 + x);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
