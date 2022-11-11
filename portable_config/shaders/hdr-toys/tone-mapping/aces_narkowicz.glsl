// approximated ACES fit by Krzysztof Narkowicz.
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (aces_narkowicz)

const float A = 2.51;
const float B = 0.03;
const float C = 2.43;
const float D = 0.59;
const float E = 0.14;

float curve(float x) {
    return (x * (A * x + B)) / (x * (C * x + D) + E);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
