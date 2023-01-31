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
//!DESC tone mapping (clip)

const float DISPGAMMA = 2.4;
const float L_W = 1.0;
const float L_B = 0.0;

float bt1886_r(float L, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float V = pow(max(L / a, 0.0), 1.0 / gamma) - b;
    return V;
}

float bt1886_f(float V, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float L = a * pow(max(V + b, 0.0), gamma);
    return L;
}

vec3 tone_mapping_clip(vec3 color) {
    color.rgb = vec3(
        bt1886_r(color.r, DISPGAMMA, L_W, L_W / CONTRAST_sdr),
        bt1886_r(color.g, DISPGAMMA, L_W, L_W / CONTRAST_sdr),
        bt1886_r(color.b, DISPGAMMA, L_W, L_W / CONTRAST_sdr)
    );

    color.rgb = vec3(
        bt1886_f(color.r, DISPGAMMA, L_W, L_B),
        bt1886_f(color.g, DISPGAMMA, L_W, L_B),
        bt1886_f(color.b, DISPGAMMA, L_W, L_B)
    );
    return color;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    float lv = 0.18;

    color.rgb = color.rgb * L_sdr / L_hdr;

    vec3 n1 = clamp(tone_mapping_clip(color.rgb * exp2(-1)), 0.0, 1.0);
    vec3 p1 = clamp(tone_mapping_clip(color.rgb * exp2(1)), 0.0, 1.0);
    vec3 m1 = mix(n1, p1, lv);

    vec3 n2 = clamp(tone_mapping_clip(color.rgb * exp2(-2)), 0.0, 1.0);
    vec3 p2 = clamp(tone_mapping_clip(color.rgb * exp2(2)), 0.0, 1.0);
    vec3 m2 = mix(n2, p2, lv);

    vec3 n3 = clamp(tone_mapping_clip(color.rgb * exp2(-3)), 0.0, 1.0);
    vec3 p3 = clamp(tone_mapping_clip(color.rgb * exp2(3)), 0.0, 1.0);
    vec3 m3 = mix(n3, p3, lv);

    vec3 n4 = clamp(tone_mapping_clip(color.rgb * exp2(-4)), 0.0, 1.0);
    vec3 p4 = clamp(tone_mapping_clip(color.rgb * exp2(4)), 0.0, 1.0);
    vec3 m4 = mix(n4, p4, lv);

    vec3 n5 = clamp(tone_mapping_clip(color.rgb * exp2(-5)), 0.0, 1.0);
    vec3 p5 = clamp(tone_mapping_clip(color.rgb * exp2(5)), 0.0, 1.0);
    vec3 m5 = mix(n5, p5, lv);

    vec3 n6 = clamp(tone_mapping_clip(color.rgb * exp2(-6)), 0.0, 1.0);
    vec3 p6 = clamp(tone_mapping_clip(color.rgb * exp2(6)), 0.0, 1.0);
    vec3 m6 = mix(n6, p6, lv);

    vec3 n7 = clamp(tone_mapping_clip(color.rgb * exp2(-7)), 0.0, 1.0);
    vec3 p7 = clamp(tone_mapping_clip(color.rgb * exp2(7)), 0.0, 1.0);
    vec3 m7 = mix(n7, p7, lv);

    vec3 n8 = clamp(tone_mapping_clip(color.rgb * exp2(-8)), 0.0, 1.0);
    vec3 p8 = clamp(tone_mapping_clip(color.rgb * exp2(8)), 0.0, 1.0);
    vec3 m8 = mix(n8, p8, lv);

    color.rgb = mix(color.rgb, m1, lv);
    color.rgb = mix(color.rgb, m2, lv);
    color.rgb = mix(color.rgb, m3, lv);
    color.rgb = mix(color.rgb, m4, lv);
    color.rgb = mix(color.rgb, m5, lv);
    color.rgb = mix(color.rgb, m6, lv);
    color.rgb = mix(color.rgb, m7, lv);
    color.rgb = mix(color.rgb, m8, lv);

    return color;
}
