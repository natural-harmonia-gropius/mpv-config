// From the "Advanced Techniques and Optimization of HDR Color Pipelines" GDC talk by Timothy Lottes.
// https://www.gdcvault.com/play/1023512/Advanced-Graphics-Techniques-Tutorial-Day

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (lottes)

float curve(float x) {
    const float a       = 1.6;
    const float d       = 0.977;
    const float hdrMax  = 8.0;
    const float midIn   = 0.18;
    const float midOut  = 0.267;

    const float b =
        (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
    const float c =
        (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
        ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

    return pow(x, a) / (pow(x, a * d) * b + c);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
