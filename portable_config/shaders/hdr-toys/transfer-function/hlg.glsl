//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (hlg)

const float L_w   = 1000.0;
const float L_b   = 0.0;

const float alpha = L_w - L_b;
const float beta  = L_b;
const float gamma = 1.2 * pow(1.111, log2(L_w / 1000.0));

const float a = 0.17883277;
const float b = 1.0 - 4.0 * a;
const float c = 0.5 - a * log(4.0 * a);

// HLG Inverse EOTF (i.e. HLG inverse OOTF followed by the HLG OETF)
vec3 Y_to_HLG(vec3 displayLinear) {
    // HLG Inverse OOTF (display linear to scene linear)
    // This case is to protect against pow(0,-N)=Inf error. The ITU document
    // does not offer a recommendation for this corner case. There may be a
    // better way to handle this, but for now, this works.
    const float Y_d = dot(displayLinear, vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196));
    const vec3 sceneLinear = vec3(
        Y_d == 0.0 ? 0.0 : pow((Y_d - beta) / alpha, (1.0 - gamma) / gamma) * ((displayLinear.r - beta) / alpha),
        Y_d == 0.0 ? 0.0 : pow((Y_d - beta) / alpha, (1.0 - gamma) / gamma) * ((displayLinear.g - beta) / alpha),
        Y_d == 0.0 ? 0.0 : pow((Y_d - beta) / alpha, (1.0 - gamma) / gamma) * ((displayLinear.b - beta) / alpha)
    );

    // HLG OETF (scene linear to non-linear signal value)
    const vec3 HLG = vec3(
        sceneLinear.r <= 1.0 / 12.0 ? sqrt(3.0 * sceneLinear.r) : a * log(12.0 * sceneLinear.r - b) + c,
        sceneLinear.g <= 1.0 / 12.0 ? sqrt(3.0 * sceneLinear.g) : a * log(12.0 * sceneLinear.g - b) + c,
        sceneLinear.b <= 1.0 / 12.0 ? sqrt(3.0 * sceneLinear.b) : a * log(12.0 * sceneLinear.b - b) + c
    );

    return HLG;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = Y_to_HLG(color.rgb * L_sdr);

    return color;
}
