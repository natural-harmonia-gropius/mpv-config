// SMPTE "legal" signal range

//!PARAM DEN
//!TYPE float
1023.0

//!PARAM BLACK
//!TYPE float
64.0

//!PARAM WHITE
//!TYPE float
940.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC signal range scaling

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float B = BLACK / DEN;
    const float W = WHITE / DEN;

    color.rgb *= W - B;
    color.rgb += B;
    return color;
}
