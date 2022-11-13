// default to SMPTE "legal" signal range

//!PARAM DEPTH
//!TYPE int
10

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
    const float D = pow(2, DEPTH) - 1;
    const float B = BLACK / D;
    const float W = WHITE / D;

    color.rgb *= W - B;
    color.rgb += B;
    return color;
}
