// OpenDRT v1.1.0 - GLSL port for mpv
// Original: https://github.com/jedypod/open-display-transform
// License: GPLv3

// Input:  linear BT.2020, scene-linear (normalised: 1.0 = 100 nits)
// Output: linear BT.709,  display-linear (1.0 = peak white)

//!PARAM preset
//!TYPE ENUM int
Standard
Arriba
Sylvan
Colorful
Aery
Dystopic
Umbra
Base

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (OpenDRT)

// ── Matrices ────────────────────────────────────────────────────────────────
// BT.2020 → XYZ D65
const mat3 m_rec2020_to_xyz = mat3(
    0.636958048301291,  0.262700212011267,  4.99999999999999e-17,
    0.144616903586208,  0.677998071518871,  0.028072693049087,
    0.168880975164172,  0.059301716469862,  1.060985057710791
);

// XYZ D65 → P3-D65
const mat3 m_xyz_to_p3d65 = mat3(
     2.493496911941425,  -0.829488969561575,   0.035845830243784,
    -0.931383617919124,   1.762664060318347,  -0.076172389268042,
    -0.402710784450717,   0.023624685841944,   0.956884524007687
);

// P3-D65 → XYZ D65
const mat3 m_p3d65_to_xyz = mat3(
    0.486570948648216,  0.228974564069749, -4.00000000000000e-17,
    0.265667693169093,  0.691738521836506,  0.045113381858903,
    0.198217285234363,  0.079286914093745,  1.043944368900976
);

// XYZ D65 → Rec.709
const mat3 m_xyz_to_rec709 = mat3(
     3.240969941904523,  -0.969243636280880,   0.055630079696994,
    -1.537383177570094,   1.875967501507720,  -0.203976958888977,
    -0.498610760293004,   0.041555057407176,   1.056971514242878
);

// Creative White CAT matrices (XYZ D65 space)
// D93
const mat3 m_cat_d65_to_d93 = mat3(
    0.95703423023223877,  -0.0179296955466270447,  0.00127589143812656403,
   -0.0247171502560377121, 0.990019857883453369,   0.00427919067442417058,
    0.0624028593301773071, 0.0248119533061981201,   1.29345715045928955
);

// D75
const mat3 m_cat_d65_to_d75 = mat3(
    0.981001079082489014,  -0.00843488052487373352,  0.000552809564396739006,
   -0.0116619253531098366,  0.996506094932556152,    0.00179840810596942902,
    0.0265614092350006104,  0.0105696544051170349,   1.12374722957611084
);

// D60
const mat3 m_cat_d65_to_d60 = mat3(
    1.01182246208190918,   0.00561682833358645439,  -0.000335735734552145004,
    0.00778879318386316299, 1.00150644779205322,    -0.0010509500280022619,
   -0.0157783031463623047, -0.00628517568111419678,  0.927366673946380615
);

// D55
const mat3 m_cat_d65_to_d55 = mat3(
    1.02585089206695557,   0.0129133854061365128,  -0.000719940289855003032,
    0.0179439820349216461, 1.00214779376983643,    -0.00218106806278228803,
   -0.0332137793302536011,-0.0132421031594276428,   0.84868013858795166
);

// D50
const mat3 m_cat_d65_to_d50 = mat3(
    1.04257404804229736,   0.0221935361623764038,  -0.00116488314233720303,
    0.03089117631316185,   1.00185668468475342,    -0.00342052709311246915,
   -0.052812620997428894, -0.0210737623274326324,   0.761789083480834961
);

// ── Math helpers ─────────────────────────────────────────────────────────────
float sdivf(float a, float b)  { return b == 0.0 ? 0.0 : a / b; }
vec3  sdivf3f(vec3 a, float b) { return b == 0.0 ? vec3(0.0) : a / b; }
float spowf(float a, float b)  { return a <= 0.0 ? 0.0 : pow(a, b); }
vec3  spowf3(vec3 a, float b)  { return vec3(spowf(a.r, b), spowf(a.g, b), spowf(a.b, b)); }
float fmaxf3(vec3 a)           { return max(a.r, max(a.g, a.b)); }
float fminf3(vec3 a)           { return min(a.r, min(a.g, a.b)); }
float hypotf3(vec3 v)          { return sqrt(max(0.0, dot(v, v))); }
float hypotf2(vec2 v)          { return sqrt(max(0.0, dot(v, v))); }

// ── Core math ────────────────────────────────────────────────────────────────
float compress_hyperbolic_power(float x, float s, float p) {
    return spowf(x / (x + s), p);
}

float compress_toe_quadratic(float x, float toe, bool inv) {
    if (toe == 0.0) return x;
    if (!inv)  return spowf(x, 2.0) / (x + toe);
    else       return (x + sqrt(max(0.0, x * (4.0 * toe + x)))) / 2.0;
}

float compress_toe_cubic(float x, float m, float w, bool inv) {
    if (m == 1.0) return x;
    float x2 = x * x;
    if (!inv) {
        return x * (x2 + m * w) / (x2 + w);
    } else {
        float p0 = x2 - 3.0 * m * w;
        float p1 = 2.0 * x2 + 27.0 * w - 9.0 * m * w;
        float p2 = pow(sqrt(x2 * p1 * p1 - 4.0 * p0 * p0 * p0) / 2.0 + x * p1 / 2.0, 1.0 / 3.0);
        return p0 / (3.0 * p2) + p2 / 3.0 + x / 3.0;
    }
}

float contrast_high(float x, float p, float pv, float pv_lx, bool inv) {
    float x0 = 0.18 * pow(2.0, pv);
    if (x < x0 || p == 1.0) return x;
    float o   = x0 - x0 / p;
    float s0  = pow(x0, 1.0 - p) / p;
    float x1  = x0 * pow(2.0, pv_lx);
    float k1  = p * s0 * pow(x1, p) / x1;
    float y1  = s0 * pow(x1, p) + o;
    if (inv)
        return x > y1 ? (x - y1) / k1 + x1 : pow((x - o) / s0, 1.0 / p);
    else
        return x > x1 ? k1 * (x - x1) + y1 : s0 * pow(x, p) + o;
}

float softplus(float x, float s) {
    if (x > 10.0 * s || s < 1e-4) return x;
    return s * log(max(0.0, 1.0 + exp(x / s)));
}

float gauss_window(float x, float w) { return exp(-x * x / w); }

vec2 opponent(vec3 rgb) {
    return vec2(rgb.r - rgb.b, rgb.g - (rgb.r + rgb.b) / 2.0);
}

float hue_offset(float h, float o) {
    const float PI = 3.14159265358979324;
    return mod(h - o + PI, 2.0 * PI) - PI;
}

// ── OpenDRT Standard Preset Parameters ───────────────────────────────────────
// Display: Rec.709, 100 nit
const float Lp = 100.0;
const float Lg = 10.0;
const float hdr_grey_boost = 0.13;

// ── Main transform ────────────────────────────────────────────────────────────
vec3 open_drt(vec3 rgb) {
    const float PI    = 3.14159265358979324;
    const float SQRT3 = 1.73205080756887729;

    // ── Look preset parameters ──────────────────────────────────────────────
    float tn_con, tn_sh, tn_toe, tn_off;
    bool  tn_hcon_enable; float tn_hcon, tn_hcon_pv, tn_hcon_st;
    bool  tn_lcon_enable; float tn_lcon, tn_lcon_w;
    // cwp: 0=D93 1=D75 2=D65 3=D60 4=D55 5=D50
    int   cwp; float cwp_lm;
    float rs_sa, rs_rw, rs_bw;
    bool  pt_enable;
    float pt_lml, pt_lml_r, pt_lml_g, pt_lml_b, pt_lmh, pt_lmh_r, pt_lmh_b;
    bool  ptl_enable; float ptl_c, ptl_m, ptl_y;
    bool  ptm_enable;
    float ptm_low, ptm_low_rng, ptm_low_st, ptm_high, ptm_high_rng, ptm_high_st;
    bool  brl_enable;
    float brl, brl_r, brl_g, brl_b, brl_rng, brl_st;
    bool  brlp_enable;
    float brlp, brlp_r, brlp_g, brlp_b;
    bool  hc_enable; float hc_r, hc_r_rng;
    bool  hs_rgb_enable;
    float hs_r, hs_r_rng, hs_g, hs_g_rng, hs_b, hs_b_rng;
    bool  hs_cmy_enable;
    float hs_c, hs_c_rng, hs_m, hs_m_rng, hs_y, hs_y_rng;

    if (preset == 0) { // Standard
        tn_con=1.66; tn_sh=0.5; tn_toe=0.003; tn_off=0.005;
        tn_hcon_enable=false; tn_hcon=0.0; tn_hcon_pv=1.0; tn_hcon_st=4.0;
        tn_lcon_enable=false; tn_lcon=0.0; tn_lcon_w=0.5;
        cwp=2; cwp_lm=0.25;
        rs_sa=0.35; rs_rw=0.25; rs_bw=0.55;
        pt_enable=true; pt_lml=0.25; pt_lml_r=0.5; pt_lml_g=0.0; pt_lml_b=0.1; pt_lmh=0.25; pt_lmh_r=0.5; pt_lmh_b=0.0;
        ptl_enable=true; ptl_c=0.06; ptl_m=0.08; ptl_y=0.06;
        ptm_enable=true; ptm_low=0.4; ptm_low_rng=0.25; ptm_low_st=0.5; ptm_high=-0.8; ptm_high_rng=0.35; ptm_high_st=0.4;
        brl_enable=true; brl=0.0; brl_r=-2.5; brl_g=-1.5; brl_b=-1.5; brl_rng=0.5; brl_st=0.35;
        brlp_enable=true; brlp=-0.5; brlp_r=-1.25; brlp_g=-1.25; brlp_b=-0.25;
        hc_enable=true; hc_r=1.0; hc_r_rng=0.3;
        hs_rgb_enable=true; hs_r=0.6; hs_r_rng=0.6; hs_g=0.35; hs_g_rng=1.0; hs_b=0.66; hs_b_rng=1.0;
        hs_cmy_enable=true; hs_c=0.25; hs_c_rng=1.0; hs_m=0.0; hs_m_rng=1.0; hs_y=0.0; hs_y_rng=1.0;
    } else if (preset == 1) { // Arriba
        tn_con=1.05; tn_sh=0.5; tn_toe=0.1; tn_off=0.01;
        tn_hcon_enable=false; tn_hcon=0.0; tn_hcon_pv=1.0; tn_hcon_st=4.0;
        tn_lcon_enable=true; tn_lcon=1.5; tn_lcon_w=0.2;
        cwp=2; cwp_lm=0.25;
        rs_sa=0.35; rs_rw=0.25; rs_bw=0.55;
        pt_enable=true; pt_lml=0.25; pt_lml_r=0.45; pt_lml_g=0.0; pt_lml_b=0.1; pt_lmh=0.25; pt_lmh_r=0.25; pt_lmh_b=0.0;
        ptl_enable=true; ptl_c=0.06; ptl_m=0.08; ptl_y=0.06;
        ptm_enable=true; ptm_low=1.0; ptm_low_rng=0.4; ptm_low_st=0.5; ptm_high=-0.8; ptm_high_rng=0.66; ptm_high_st=0.6;
        brl_enable=true; brl=0.0; brl_r=-2.5; brl_g=-1.5; brl_b=-1.5; brl_rng=0.5; brl_st=0.35;
        brlp_enable=true; brlp=0.0; brlp_r=-1.7; brlp_g=-2.0; brlp_b=-0.5;
        hc_enable=true; hc_r=1.0; hc_r_rng=0.3;
        hs_rgb_enable=true; hs_r=0.6; hs_r_rng=0.8; hs_g=0.35; hs_g_rng=1.0; hs_b=0.66; hs_b_rng=1.0;
        hs_cmy_enable=true; hs_c=0.15; hs_c_rng=1.0; hs_m=0.0; hs_m_rng=1.0; hs_y=0.0; hs_y_rng=1.0;
    } else if (preset == 2) { // Sylvan
        tn_con=1.6; tn_sh=0.5; tn_toe=0.01; tn_off=0.01;
        tn_hcon_enable=false; tn_hcon=0.0; tn_hcon_pv=1.0; tn_hcon_st=4.0;
        tn_lcon_enable=true; tn_lcon=0.25; tn_lcon_w=0.75;
        cwp=2; cwp_lm=0.25;
        rs_sa=0.25; rs_rw=0.25; rs_bw=0.55;
        pt_enable=true; pt_lml=0.15; pt_lml_r=0.5; pt_lml_g=0.15; pt_lml_b=0.1; pt_lmh=0.25; pt_lmh_r=0.15; pt_lmh_b=0.15;
        ptl_enable=true; ptl_c=0.05; ptl_m=0.08; ptl_y=0.05;
        ptm_enable=true; ptm_low=0.5; ptm_low_rng=0.5; ptm_low_st=0.5; ptm_high=-0.8; ptm_high_rng=0.5; ptm_high_st=0.5;
        brl_enable=true; brl=-1.0; brl_r=-2.0; brl_g=-2.0; brl_b=0.0; brl_rng=0.25; brl_st=0.25;
        brlp_enable=true; brlp=-1.0; brlp_r=-0.5; brlp_g=-0.25; brlp_b=-0.25;
        hc_enable=true; hc_r=1.0; hc_r_rng=0.4;
        hs_rgb_enable=true; hs_r=0.6; hs_r_rng=1.15; hs_g=0.8; hs_g_rng=1.25; hs_b=0.6; hs_b_rng=1.0;
        hs_cmy_enable=true; hs_c=0.25; hs_c_rng=0.25; hs_m=0.25; hs_m_rng=0.5; hs_y=0.35; hs_y_rng=0.5;
    } else if (preset == 3) { // Colorful
        tn_con=1.5; tn_sh=0.5; tn_toe=0.003; tn_off=0.003;
        tn_hcon_enable=false; tn_hcon=0.0; tn_hcon_pv=1.0; tn_hcon_st=4.0;
        tn_lcon_enable=true; tn_lcon=0.4; tn_lcon_w=0.5;
        cwp=2; cwp_lm=0.25;
        rs_sa=0.35; rs_rw=0.25; rs_bw=0.55;
        pt_enable=true; pt_lml=0.5; pt_lml_r=1.0; pt_lml_g=0.0; pt_lml_b=0.5; pt_lmh=0.15; pt_lmh_r=0.15; pt_lmh_b=0.15;
        ptl_enable=true; ptl_c=0.05; ptl_m=0.06; ptl_y=0.05;
        ptm_enable=true; ptm_low=0.8; ptm_low_rng=0.5; ptm_low_st=0.4; ptm_high=-0.8; ptm_high_rng=0.4; ptm_high_st=0.4;
        brl_enable=true; brl=0.0; brl_r=-1.25; brl_g=-1.25; brl_b=-0.25; brl_rng=0.3; brl_st=0.5;
        brlp_enable=true; brlp=-0.5; brlp_r=-1.25; brlp_g=-1.25; brlp_b=-0.5;
        hc_enable=true; hc_r=1.0; hc_r_rng=0.4;
        hs_rgb_enable=true; hs_r=0.5; hs_r_rng=0.8; hs_g=0.35; hs_g_rng=1.0; hs_b=0.5; hs_b_rng=1.0;
        hs_cmy_enable=true; hs_c=0.25; hs_c_rng=1.0; hs_m=0.0; hs_m_rng=1.0; hs_y=0.25; hs_y_rng=1.0;
    } else if (preset == 4) { // Aery
        tn_con=1.15; tn_sh=0.5; tn_toe=0.04; tn_off=0.006;
        tn_hcon_enable=false; tn_hcon=0.0; tn_hcon_pv=0.0; tn_hcon_st=0.5;
        tn_lcon_enable=true; tn_lcon=0.5; tn_lcon_w=2.0;
        cwp=1; cwp_lm=0.25; // D75
        rs_sa=0.25; rs_rw=0.2; rs_bw=0.5;
        pt_enable=true; pt_lml=0.0; pt_lml_r=0.5; pt_lml_g=0.15; pt_lml_b=0.1; pt_lmh=0.0; pt_lmh_r=0.1; pt_lmh_b=0.0;
        ptl_enable=true; ptl_c=0.05; ptl_m=0.08; ptl_y=0.05;
        ptm_enable=true; ptm_low=0.8; ptm_low_rng=0.35; ptm_low_st=0.5; ptm_high=-0.9; ptm_high_rng=0.5; ptm_high_st=0.3;
        brl_enable=true; brl=-3.0; brl_r=0.0; brl_g=0.0; brl_b=1.0; brl_rng=0.8; brl_st=0.15;
        brlp_enable=true; brlp=-1.0; brlp_r=-1.0; brlp_g=-1.0; brlp_b=0.0;
        hc_enable=true; hc_r=0.5; hc_r_rng=0.25;
        hs_rgb_enable=true; hs_r=0.6; hs_r_rng=1.0; hs_g=0.35; hs_g_rng=2.0; hs_b=0.5; hs_b_rng=1.5;
        hs_cmy_enable=true; hs_c=0.35; hs_c_rng=1.0; hs_m=0.25; hs_m_rng=1.0; hs_y=0.35; hs_y_rng=0.5;
    } else if (preset == 5) { // Dystopic
        tn_con=1.6; tn_sh=0.5; tn_toe=0.01; tn_off=0.008;
        tn_hcon_enable=true; tn_hcon=0.25; tn_hcon_pv=0.0; tn_hcon_st=1.0;
        tn_lcon_enable=true; tn_lcon=1.0; tn_lcon_w=0.75;
        cwp=3; cwp_lm=0.25; // D60
        rs_sa=0.2; rs_rw=0.25; rs_bw=0.55;
        pt_enable=true; pt_lml=0.15; pt_lml_r=0.0; pt_lml_g=0.0; pt_lml_b=0.0; pt_lmh=0.0; pt_lmh_r=0.0; pt_lmh_b=0.0;
        ptl_enable=true; ptl_c=0.05; ptl_m=0.08; ptl_y=0.05;
        ptm_enable=true; ptm_low=0.25; ptm_low_rng=0.25; ptm_low_st=0.8; ptm_high=-0.8; ptm_high_rng=0.6; ptm_high_st=0.25;
        brl_enable=true; brl=-2.0; brl_r=-2.0; brl_g=-2.0; brl_b=0.0; brl_rng=0.35; brl_st=0.35;
        brlp_enable=true; brlp=0.0; brlp_r=-1.0; brlp_g=-1.0; brlp_b=-1.0;
        hc_enable=true; hc_r=1.0; hc_r_rng=0.25;
        hs_rgb_enable=true; hs_r=0.7; hs_r_rng=1.33; hs_g=1.0; hs_g_rng=2.0; hs_b=0.75; hs_b_rng=2.0;
        hs_cmy_enable=true; hs_c=1.0; hs_c_rng=0.5; hs_m=1.0; hs_m_rng=1.0; hs_y=1.0; hs_y_rng=0.765;
    } else if (preset == 6) { // Umbra
        tn_con=1.8; tn_sh=0.5; tn_toe=0.001; tn_off=0.015;
        tn_hcon_enable=false; tn_hcon=0.0; tn_hcon_pv=1.0; tn_hcon_st=4.0;
        tn_lcon_enable=true; tn_lcon=1.0; tn_lcon_w=1.0;
        cwp=5; cwp_lm=0.25; // D50
        rs_sa=0.35; rs_rw=0.25; rs_bw=0.55;
        pt_enable=true; pt_lml=0.0; pt_lml_r=0.5; pt_lml_g=0.0; pt_lml_b=0.15; pt_lmh=0.25; pt_lmh_r=0.25; pt_lmh_b=0.0;
        ptl_enable=true; ptl_c=0.05; ptl_m=0.06; ptl_y=0.05;
        ptm_enable=true; ptm_low=0.4; ptm_low_rng=0.35; ptm_low_st=0.66; ptm_high=-0.6; ptm_high_rng=0.45; ptm_high_st=0.45;
        brl_enable=true; brl=-2.0; brl_r=-4.5; brl_g=-3.0; brl_b=-4.0; brl_rng=0.35; brl_st=0.3;
        brlp_enable=true; brlp=0.0; brlp_r=-2.0; brlp_g=-1.0; brlp_b=-0.5;
        hc_enable=true; hc_r=1.0; hc_r_rng=0.35;
        hs_rgb_enable=true; hs_r=0.66; hs_r_rng=1.0; hs_g=0.5; hs_g_rng=2.0; hs_b=0.85; hs_b_rng=2.0;
        hs_cmy_enable=true; hs_c=0.0; hs_c_rng=1.0; hs_m=0.25; hs_m_rng=1.0; hs_y=0.66; hs_y_rng=0.66;
    } else { // Base (preset == 7)
        tn_con=1.66; tn_sh=0.5; tn_toe=0.003; tn_off=0.005;
        tn_hcon_enable=false; tn_hcon=0.0; tn_hcon_pv=1.0; tn_hcon_st=4.0;
        tn_lcon_enable=false; tn_lcon=0.0; tn_lcon_w=0.5;
        cwp=2; cwp_lm=0.25;
        rs_sa=0.35; rs_rw=0.25; rs_bw=0.55;
        pt_enable=true; pt_lml=0.5; pt_lml_r=0.5; pt_lml_g=0.15; pt_lml_b=0.15; pt_lmh=0.8; pt_lmh_r=0.5; pt_lmh_b=0.0;
        ptl_enable=true; ptl_c=0.05; ptl_m=0.06; ptl_y=0.05;
        ptm_enable=false; ptm_low=0.0; ptm_low_rng=0.5; ptm_low_st=0.5; ptm_high=0.0; ptm_high_rng=0.5; ptm_high_st=0.5;
        brl_enable=false; brl=0.0; brl_r=0.0; brl_g=0.0; brl_b=0.0; brl_rng=0.5; brl_st=0.35;
        brlp_enable=true; brlp=-0.5; brlp_r=-1.6; brlp_g=-1.6; brlp_b=-0.8;
        hc_enable=false; hc_r=0.0; hc_r_rng=0.25;
        hs_rgb_enable=false; hs_r=0.0; hs_r_rng=1.0; hs_g=0.0; hs_g_rng=1.0; hs_b=0.0; hs_b_rng=1.0;
        hs_cmy_enable=false; hs_c=0.0; hs_c_rng=1.0; hs_m=0.0; hs_m_rng=1.0; hs_y=0.0; hs_y_rng=1.0;
    }

    // ── Tonescale parameter setup ───────────────────────────────────────────
    // surround dim = 1 → tn_su = 1
    const float tn_su = 1.0;

    float ts_x1  = pow(2.0, 6.0 * tn_sh + 4.0);
    float ts_y1  = Lp / 100.0;
    float ts_x0  = 0.18 + tn_off;
    float ts_y0  = (Lg / 100.0) * (1.0 + hdr_grey_boost * log2(ts_y1));
    float ts_s0  = compress_toe_quadratic(ts_y0, tn_toe, true);
    float ts_p   = tn_con / (1.0 + tn_su * 0.05);
    float ts_s10 = ts_x0 * (pow(ts_s0, -1.0 / tn_con) - 1.0);
    float ts_m1  = ts_y1 / pow(ts_x1 / (ts_x1 + ts_s10), tn_con);
    float ts_m2  = compress_toe_quadratic(ts_m1, tn_toe, true);
    float ts_s   = ts_x0 * (pow(ts_s0 / ts_m2, -1.0 / tn_con) - 1.0);
    // Display scale for Rec.1886 (linear, 100-nit reference)
    float ts_dsc = 100.0 / Lp;

    // HDR purity factor (unused at 100 nit but kept for correctness)
    const float pt_hdr = 0.5;
    float pt_cmp_Lf  = pt_hdr * min(1.0, (Lp - 100.0) / 900.0);
    float s_Lp100    = ts_x0 * (pow(Lg / 100.0, -1.0 / tn_con) - 1.0);
    float ts_s1      = ts_s * pt_cmp_Lf + s_Lp100 * (1.0 - pt_cmp_Lf);

    // ── Input: linear BT.2020 → linear P3-D65 ──────────────────────────────
    rgb = m_rec2020_to_xyz * rgb;
    rgb = m_xyz_to_p3d65   * rgb;

    // ── Rendering Space ─────────────────────────────────────────────────────
    vec3  rs_w  = vec3(rs_rw, 1.0 - rs_rw - rs_bw, rs_bw);
    float sat_L = dot(rgb, rs_w);
    rgb = sat_L * rs_sa + rgb * (1.0 - rs_sa);

    // Offset
    rgb += tn_off;

    // Tonescale norm (scene norm)
    float tsn = hypotf3(rgb) / SQRT3;

    // RGB Ratios
    rgb = sdivf3f(rgb, tsn);

    // Opponent / hue
    vec2  opp   = opponent(rgb);
    float ach_d = hypotf2(opp) / 2.0;
    ach_d = 1.25 * compress_toe_quadratic(ach_d, 0.25, false);

    const float hue_epsilon = 1e-6;
    float hue_raw = length(opp) < hue_epsilon ? 0.0 : atan(opp.x, opp.y);
    float hue = mod(hue_raw + PI + 1.10714931, 2.0 * PI);

    // RGB hue-angle windows (for purity compress / hue contrast)
    vec3 ha_rgb = vec3(
        gauss_window(hue_offset(hue,  0.1), 0.66),
        gauss_window(hue_offset(hue,  4.3), 0.66),
        gauss_window(hue_offset(hue,  2.3), 0.66));

    // RGB hue-angle windows for hue shift (red shifted more orange)
    vec3 ha_rgb_hs = vec3(
        gauss_window(hue_offset(hue, -0.4), 0.66),
        ha_rgb.g,
        gauss_window(hue_offset(hue,  2.5), 0.66));

    // CMY hue-angle windows
    vec3 ha_cmy = vec3(
        gauss_window(hue_offset(hue,  3.3), 0.5),
        gauss_window(hue_offset(hue,  1.3), 0.5),
        gauss_window(hue_offset(hue, -1.15), 0.5));

    // ── Brilliance ──────────────────────────────────────────────────────────
    if (brl_enable) {
        float brl_tsf = spowf(tsn / (tsn + 1.0), 1.0 - brl_rng);
        float brl_exf = (brl + brl_r * ha_rgb.r + brl_g * ha_rgb.g + brl_b * ha_rgb.b)
                        * spowf(ach_d, 1.0 / brl_st);
        float brl_ex  = pow(2.0, brl_exf * (brl_exf < 0.0 ? brl_tsf : 1.0 - brl_tsf));
        tsn *= brl_ex;
    }

    // ── Contrast Low ────────────────────────────────────────────────────────
    if (tn_lcon_enable) {
        float lcon_m = pow(2.0, -tn_lcon);
        float lcon_w = tn_lcon_w / 4.0;
        lcon_w *= lcon_w;
        float lcon_cnst_sc = compress_toe_cubic(ts_x0, lcon_m, lcon_w, true) / ts_x0;
        tsn *= lcon_cnst_sc;
        tsn  = compress_toe_cubic(tsn, lcon_m, lcon_w, false);
    }

    // ── Contrast High ────────────────────────────────────────────────────────
    if (tn_hcon_enable) {
        float hcon_p = pow(2.0, tn_hcon);
        tsn = contrast_high(tsn, hcon_p, tn_hcon_pv, tn_hcon_st, false);
    }

    // ── Hyperbolic compression ───────────────────────────────────────────────
    float tsn_pt    = compress_hyperbolic_power(tsn, ts_s1,    ts_p);
    float tsn_const = compress_hyperbolic_power(tsn, s_Lp100,  ts_p);
    tsn             = compress_hyperbolic_power(tsn, ts_s,     ts_p);

    // ── Hue Contrast R ───────────────────────────────────────────────────────
    if (hc_enable) {
        float hc_ts = 1.0 - tsn_const;
        float hc_c  = hc_ts * (1.0 - ach_d) + ach_d * (1.0 - hc_ts);
        hc_c *= ach_d * ha_rgb.r;
        hc_ts = spowf(max(0.0, hc_ts), 1.0 / hc_r_rng);
        float hc_f = hc_r * (hc_c - 2.0 * hc_c * hc_ts) + 1.0;
        rgb = vec3(rgb.r, rgb.g * hc_f, rgb.b * hc_f);
    }

    // ── Hue Shift RGB ────────────────────────────────────────────────────────
    if (hs_rgb_enable) {
        vec3  hs_rgb_v = vec3(
            ha_rgb_hs.r * ach_d * spowf(tsn_pt, 1.0 / hs_r_rng),
            ha_rgb_hs.g * ach_d * spowf(tsn_pt, 1.0 / hs_g_rng),
            ha_rgb_hs.b * ach_d * spowf(tsn_pt, 1.0 / hs_b_rng));
        vec3 hsf = vec3(hs_rgb_v.r * hs_r, hs_rgb_v.g * -hs_g, hs_rgb_v.b * -hs_b);
        hsf = vec3(hsf.b - hsf.g, hsf.r - hsf.b, hsf.g - hsf.r);
        rgb += hsf;
    }

    // ── Hue Shift CMY ────────────────────────────────────────────────────────
    if (hs_cmy_enable) {
        float tsn_pt_compl = 1.0 - tsn_pt;
        vec3  hs_cmy_v = vec3(
            ha_cmy.r * ach_d * spowf(tsn_pt_compl, 1.0 / hs_c_rng),
            ha_cmy.g * ach_d * spowf(tsn_pt_compl, 1.0 / hs_m_rng),
            ha_cmy.b * ach_d * spowf(tsn_pt_compl, 1.0 / hs_y_rng));
        vec3 hsf = vec3(hs_cmy_v.r * -hs_c, hs_cmy_v.g * hs_m, hs_cmy_v.b * hs_y);
        hsf = vec3(hsf.b - hsf.g, hsf.r - hsf.b, hsf.g - hsf.r);
        rgb += hsf;
    }

    // ── Purity Compression ───────────────────────────────────────────────────
    float pt_lml_p = 1.0 + 4.0 * (1.0 - tsn_pt)
                     * (pt_lml + pt_lml_r * ha_rgb_hs.r + pt_lml_g * ha_rgb_hs.g + pt_lml_b * ha_rgb_hs.b);
    float ptf = 1.0 - spowf(max(0.0, tsn_pt), pt_lml_p);

    float pt_lmh_p = (1.0 - ach_d * (pt_lmh_r * ha_rgb_hs.r + pt_lmh_b * ha_rgb_hs.b))
                     * (1.0 - pt_lmh * ach_d);
    ptf = spowf(max(0.0, ptf), pt_lmh_p);

    // ── Mid-Range Purity ─────────────────────────────────────────────────────
    if (ptm_enable) {
        float ptm_low_f  = (ptm_low_st  == 0.0 || ptm_low_rng  == 0.0) ? 1.0
            : 1.0 + ptm_low  * exp(-2.0 * ach_d * ach_d / ptm_low_st)
              * spowf(max(0.0, 1.0 - tsn_const), 1.0 / ptm_low_rng);
        float ptm_high_f = (ptm_high_st == 0.0 || ptm_high_rng == 0.0) ? 1.0
            : 1.0 + ptm_high * exp(-2.0 * ach_d * ach_d / ptm_high_st)
              * spowf(max(0.0, tsn_pt), 1.0 / (4.0 * ptm_high_rng));
        ptf *= ptm_low_f * ptm_high_f;
    }

    // Lerp to peak achromatic
    rgb = rgb * ptf + (1.0 - ptf);

    // ── Inverse Rendering Space ──────────────────────────────────────────────
    sat_L = dot(rgb, rs_w);
    rgb   = (sat_L * rs_sa - rgb) / (rs_sa - 1.0);

    // ── Display gamut: P3-D65 → XYZ D65 → (optional CWP) → Rec.709 ──────────
    rgb = m_p3d65_to_xyz * rgb;

    // Creative White shift (applied in XYZ D65)
    // cwp: 0=D93 1=D75 2=D65(no shift) 3=D60 4=D55 5=D50
    if (cwp != 2) {
        float cwp_f = pow(tsn, 2.0 * cwp_lm);
        mat3 cwp_mat = cwp == 0 ? m_cat_d65_to_d93
                     : cwp == 1 ? m_cat_d65_to_d75
                     : cwp == 3 ? m_cat_d65_to_d60
                     : cwp == 4 ? m_cat_d65_to_d55
                     :            m_cat_d65_to_d50; // cwp == 5
        vec3 rgb_cwp = cwp_mat * rgb;
        rgb = rgb_cwp * cwp_f + rgb * (1.0 - cwp_f);
    }

    rgb = m_xyz_to_rec709 * rgb;

    // ── Post Brilliance ──────────────────────────────────────────────────────
    if (brlp_enable) {
        vec2  brlp_opp   = opponent(rgb);
        float brlp_ach_d = hypotf2(brlp_opp) / 4.0;
        brlp_ach_d = 1.1 * (brlp_ach_d * brlp_ach_d / (brlp_ach_d + 0.1));
        vec3  brlp_ha_rgb = ach_d * ha_rgb;
        float brlp_m = brlp + brlp_r * brlp_ha_rgb.r + brlp_g * brlp_ha_rgb.g + brlp_b * brlp_ha_rgb.b;
        float brlp_ex = pow(2.0, brlp_m * brlp_ach_d * tsn);
        rgb *= brlp_ex;
    }

    // ── Purity Softclip ──────────────────────────────────────────────────────
    if (ptl_enable) {
        rgb = vec3(softplus(rgb.r, ptl_c), softplus(rgb.g, ptl_m), softplus(rgb.b, ptl_y));
    }

    // ── Final tonescale ───────────────────────────────────────────────────────
    tsn *= ts_m2;
    tsn  = compress_toe_quadratic(tsn, tn_toe, false);
    tsn *= ts_dsc;

    // Return from RGB ratios
    rgb *= tsn;

    // Clamp to display range
    rgb = clamp(rgb, 0.0, 1.0);

    return rgb;
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = open_drt(color.rgb);
    return color;
}
