// From "Dynamic Range Reduction Inspired by Photoreceptor Physiology" by Reinhard and Devlin 2005.
// https://www.researchgate.net/publication/8100146_Dynamic_Range_Reduction_Inspired_by_Photoreceptor_Physiology

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (reinhard_devlin)

const float gamma;      // Gamma correction value.
const float f;          // Intensity adjustment parameter.
const float c;          // Chromatic adaptation.
const float a;          // Light adaptation.
const float m;          // Contrast parameter.
const float CmeanR;
const float CmeanG;
const float CmeanB;
const float Lavg;

float curve(float x) {
    return x / (1.0 + x);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}

// https://github.com/tizian/tonemapper/blob/master/src/operators/ReinhardDevlinOperator.cpp
