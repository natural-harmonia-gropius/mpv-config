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

const float o = pow(0.5, 2.4);  // mid-grey of output
const float i = o;              // mid-grey of input
const float a = 1.6;            // contrast
const float d = 0.99;           // shoulder

float curve(float x) {
    const float w = L_hdr / L_sdr;
    const float b =
        (-pow(i, a) + pow(w, a) * o) /
        ((pow(w, a * d) - pow(i, a * d)) * o);
    const float c =
        (pow(w, a * d) * pow(i, a) - pow(w, a) * pow(i, a * d) * o) /
        ((pow(w, a * d) - pow(i, a * d)) * o);

    return pow(x, a) / (pow(x, a * d) * b + c);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
