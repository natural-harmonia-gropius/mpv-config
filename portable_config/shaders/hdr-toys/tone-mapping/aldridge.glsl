// Variation of the Hejl and Burgess-Dawson filmic curve done by Graham Aldridge.
// http://iwasbeingirony.blogspot.com/2010/04/approximating-film-with-tonemapping.html

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (aldridge)

const float cutoff = 0.025; // Transition into compressed blacks.

float curve(float x) {
    float t = 2.0 * cutoff;
    float a = x + (t - x) * clamp(t - x, 0.0, 1.0) * (0.25 / cutoff) - cutoff;
    float r = (a * (6.2 * a + 0.5)) / (a * (6.2 * a + 1.7) + 0.06);
    return r;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
