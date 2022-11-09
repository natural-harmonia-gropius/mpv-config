//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Clip Code Value (Black Only)

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return max(color, 0.0);
}



//!HOOK OUTPUT
//!BIND HOOKED
//!DESC PQ to Y

// Constants from SMPTE ST 2084-2014
const float pq_m1 = 0.1593017578125;    // ( 2610.0 / 4096.0 ) / 4.0;
const float pq_m2 = 78.84375;           // ( 2523.0 / 4096.0 ) * 128.0;
const float pq_c1 = 0.8359375;          // ( 3424.0 / 4096.0 ) or pq_c3 - pq_c2 + 1.0;
const float pq_c2 = 18.8515625;         // ( 2413.0 / 4096.0 ) * 32.0;
const float pq_c3 = 18.6875;            // ( 2392.0 / 4096.0 ) * 32.0;

const float pq_C  = 10000.0;

// Converts from the non-linear perceptually quantized space to cd/m^2
// Note that this is in float, and assumes normalization from 0 - 1
// (0 - pq_C for linear) and does not handle the integer coding in the Annex
// sections of SMPTE ST 2084-2014
float ST2084_2_Y(float N) {
    // Note that this does NOT handle any of the signal range
    // considerations from 2084 - this assumes full range (0 - 1)
    float Np = pow(N, 1.0 / pq_m2);
    float L = Np - pq_c1;
    if (L < 0.0 ) L = 0.0;
    L = L / (pq_c2 - pq_c3 * Np);
    L = pow(L, 1.0 / pq_m1);
    return L * pq_C; // returns cd/m^2
}

// ST.2084 EOTF (non-linear PQ to display light)
// converts from PQ code values to cd/m^2
vec3 ST2084_2_Y_f3(vec3 rgb) {
    return vec3(ST2084_2_Y(rgb.r), ST2084_2_Y(rgb.g), ST2084_2_Y(rgb.b));
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = ST2084_2_Y_f3(color.rgb);
    return color;
}



//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Y to Linear

const float L_WHITE = 203.0;
const float L_BLACK = 0.0;
// Scale cd/m^2 to linear code value
vec3 Y_2_linCV(vec3 Y, float Ymax, float Ymin) {
    return (Y - Ymin) / (Ymax - Ymin);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = Y_2_linCV(color.rgb, L_WHITE, L_BLACK);
    return color;
}



//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Tone Mapping (Reinhard)

// "Extended Reinhard" described by Reinhard et al.
float reinhard(float x) {
    const float L_w = 4.0;
    return (x * (1.0 + x / (L_w * L_w))) / (1.0 + x);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= reinhard(L) / L;
    return color;
}



//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Gamut Mapping (Clip)

// Simple conversion from BT.2020 to BT.709 based on linear matrix transformation
mat3 M = mat3(
    1.6605, -0.5876, -0.0728,
    -0.1246, 1.1329, -0.0083,
    -0.0182, -0.1006, 1.1187);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= M;
    return color;
}



//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Linear to BT.1886

const float DISPGAMMA = 2.4;
const float L_W = 1.0;
const float L_B = 0.0;
float bt1886(float L, float gamma, float Lw, float Lb) {
    // The reference EOTF specified in Rec. ITU-R BT.1886
    // L = a(max[(V+b),0])^g
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0/ gamma) - pow(Lb, 1.0 / gamma));
    float V = pow(max(L / a, 0.0), 1.0 / gamma) - b;
    return V;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = vec3(
        bt1886(color.r, DISPGAMMA, L_W, L_B),
        bt1886(color.g, DISPGAMMA, L_W, L_B),
        bt1886(color.b, DISPGAMMA, L_W, L_B)
    );
    return color;
}
