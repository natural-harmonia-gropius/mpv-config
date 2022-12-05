// ITU-R BT.2446 Conversion Method C - 6.1.8
// Optional processing of chroma correction above HDR Reference White

// In SDR production, highlight parts are sometimes intentionally expressed as white. The processing
// described in this section is optionally used to shift chroma above HDR Reference White to achromatic
// when the converted SDR content requires a degree of consistency for SDR production content. This
// processing is applied as needed before the tone-mapping processing.

// In HSV, originally LCHab.

//!PARAM WHITE_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM WHITE_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!PARAM sigma
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.06

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC chroma correction (hsv)

vec3 RGB_to_HSV(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1e-6;

    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 HSV_to_RGB(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float chroma_correction(float L, float Lref, float Lmax, float sigma) {
    float cor = 1.0;
    if (L > Lref)
        cor = max(1.0 - sigma * (L - Lref) / (Lmax - Lref), 0.0);

    return cor;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_HSV(color.rgb);
    color.g  *= chroma_correction(color.b, 1.0, WHITE_hdr / WHITE_sdr, sigma);
    color.rgb = HSV_to_RGB(color.rgb);
    return color;
}
