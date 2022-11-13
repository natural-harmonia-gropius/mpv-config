// clip the code value under the black point.

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (clip)

const float CONTRAST_RATIO = 1.0 / 1000.0;
const float WHITE = 1.0;
const float BLACK = WHITE * CONTRAST_RATIO;

float curve(float x) {
    const float r = (x - BLACK) / (WHITE - BLACK);
    return max(r, 0.0);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
