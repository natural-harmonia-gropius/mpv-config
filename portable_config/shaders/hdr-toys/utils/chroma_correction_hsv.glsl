// Emissive values are now physically correct so that as
// the emissive power increases the color will become lighter,
// similarly to how colored lights work in the real world.
// As color gets tone mapped, if the final color is bright
// enough to start saturating the film / sensor, it will
// become white.

// I don't know why, but LCH(150, 100, 0) is not white blanced.
// so do this in HSV

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

float cor(float L, float Lref, float Lmax, float sigma) {
    float r = 1.0;
    if (L > Lref)
        r = max(1.0 - sigma * (L - Lref) / (Lmax - Lref), 0.0);

    return r;
}

const float WHITE = 203.0;
const float PEAK  = 1000.0;
const float L_w   = PEAK / WHITE;   // White Point

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float sigma = 0.06;   // [0, 1]

    color.rgb = RGB_to_HSV(color.rgb);
    color.y *= cor(color.z, 1.0, L_w, sigma);
    color.rgb = HSV_to_RGB(color.rgb);

    return color;
}
