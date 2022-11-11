// Analytical approximation of a Kodak film curve by Jim Hejl and Richard Burgess-Dawson.
// http://filmicworlds.com/blog/filmic-tonemapping-operators/

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (filmic)

float curve(float x) {
    float X = max(0.0, x - 0.004);
    float result = (X * (6.2 * X + 0.5)) / (X * (6.2 * X + 1.7) + 0.06);
    return pow(result, 2.4);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
