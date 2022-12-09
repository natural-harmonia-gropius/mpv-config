// Filmic curve by Timothy Lottes, Also known as the "AMD curve".
// https://www.gdcvault.com/play/1023512/Advanced-Graphics-Techniques-Tutorial-Day

//!PARAM L_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (lottes)

const float a      = 1.6;
const float d      = 0.977;
const float midIn  = 0.18;
const float midOut = 0.267;

float curve(float x) {
    const float w = L_hdr / L_sdr;
    const float b =
        (-pow(midIn, a) + pow(w, a) * midOut) /
        ((pow(w, a * d) - pow(midIn, a * d)) * midOut);
    const float c =
        (pow(w, a * d) * pow(midIn, a) - pow(w, a) * pow(midIn, a * d) * midOut) /
        ((pow(w, a * d) - pow(midIn, a * d)) * midOut);

    return pow(x, a) / (pow(x, a * d) * b + c);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
