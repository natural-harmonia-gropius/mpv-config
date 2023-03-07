//!HOOK OUTPUT
//!BIND HOOKED
//!DESC linear to srgb

const float GAMMA  = 2.4;
const float OFFSET = 0.055;

float moncurve_r(float y, float gamma, float offs) {
    const float yb = pow(offs * gamma / ((gamma - 1.0) * (1.0 + offs)), gamma);
    const float rs = pow((gamma - 1.0) / offs, gamma - 1.0) * pow((1.0 + offs) / gamma, gamma);
    return y >= yb ? (1.0 + offs) * pow(y, 1.0 / gamma) - offs : y * rs;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = vec3(
        moncurve_r(color.r, GAMMA, OFFSET),
        moncurve_r(color.g, GAMMA, OFFSET),
        moncurve_r(color.b, GAMMA, OFFSET)
    );
    return color;
}
