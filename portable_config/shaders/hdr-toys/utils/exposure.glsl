// https://en.wikipedia.org/wiki/Exposure_value

//!PARAM ev
//!TYPE float
//!MINIMUM -64
//!MAXIMUM  64
0

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN ev
//!DESC exposure

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= pow(2.0, ev);
    return color;
}
