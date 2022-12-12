// ITU-R BT.2390 EETF
// https://www.itu.int/pub/R-REP-BT.2390

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

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (bt.2390)

const float pq_m1 = 0.1593017578125;
const float pq_m2 = 78.84375;
const float pq_c1 = 0.8359375;
const float pq_c2 = 18.8515625;
const float pq_c3 = 18.6875;

const float pq_C  = 10000.0;

float Y_2_ST2084(float C) {
    float L = C / pq_C;
    float Lm = pow(L, pq_m1);
    float N = (pq_c1 + pq_c2 * Lm) / (1.0 + pq_c3 * Lm);
    N = pow(N, pq_m2 );
    return N;
}

float ST2084_2_Y(float N) {
    float Np = pow(N, 1.0 / pq_m2);
    float L = Np - pq_c1;
    if (L < 0.0 ) L = 0.0;
    L = L / (pq_c2 - pq_c3 * Np);
    L = pow(L, 1.0 / pq_m1);
    return L * pq_C;
}

float curve(float x) {
    // Metadata of input
    const float L_w = Y_2_ST2084(L_hdr);
    const float L_b = Y_2_ST2084(0.0);

    // Metadata of output
    const float L_max = Y_2_ST2084(L_sdr);
    const float L_min = Y_2_ST2084(L_sdr / CONTRAST_sdr);

    // Y in
    x = x * L_sdr;

    // E'
    x = Y_2_ST2084(x);

    // E1
    x = (x - L_b) / (L_w - L_b);

    // E2
    const float maxLum = (L_max - L_b) / (L_w - L_b);
    const float KS = 1.5 * maxLum - 0.5;
    if (KS <= x && x <= 1.0) {
        const float TB  = (x - KS) / (1.0 - KS);
        const float TB2 = TB * TB;
        const float TB3 = TB * TB2;

        const float PB  = (2.0 * TB3 - 3.0 * TB2 + 1.0) * KS  +
                          (TB3 - 2.0 * TB2 + TB) * (1.0 - KS) +
                          (-2.0 * TB3 + 3.0 * TB2) * maxLum;

        x = PB;
    }

    // E3
    const float minLum = (L_min - L_b) / (L_w - L_b);
    const float b = minLum;
    if (0.0 <= x && x <= 1.0) {
        x = x + b * pow((1 - x), 4.0);
    }

    // E4
    x = x * (L_w - L_b) + L_b;

    // Y out
    x = ST2084_2_Y(x);

    // Output
    x = (x - L_sdr / CONTRAST_sdr) / (L_sdr - L_sdr / CONTRAST_sdr);

    return x;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
