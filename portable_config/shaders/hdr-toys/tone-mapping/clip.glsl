// clip the code value under the black point.

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (clip)

const float CONTRAST_RATIO = 1.0 / 1000.0;
const float WHITE = 1.0;
const float BLACK = WHITE * CONTRAST_RATIO;

float curve(float x) {
    const float r = (x - BLACK) / (WHITE - BLACK);
    return clamp(r, 0.0, WHITE);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = vec3(curve(color.r), curve(color.g), curve(color.b));
    return color;
}
