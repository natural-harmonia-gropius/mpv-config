// Extended mapping by Reinhard et al. 2002. which allows high luminances to burn out.
// https://www.researchgate.net/publication/2908938_Photographic_Tone_Reproduction_For_Digital_Images

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (drago)

const float WHITE = 203.0;
const float PEAK  = 1000.0;
const float L_w   = PEAK / WHITE;   // White Point

float curve(float x) {
    return (x * (1.0 + x / (L_w * L_w))) / (1.0 + x);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}

const float gamma   = 2.4;      // "Gamma correction value.
const float Ldmax   = 80.0;     // "Maximum luminance capability of the display (cd/m^2)
const float Lwa     = ;         // image -> getLogMeanLuminance()
const float Lmax    = ;         // image -> getMaximumLuminance()
const float b       = 0.85;     // "Bias function parameter
const float slope   = 4.5;      // "Elevation ratio of the line passing by the origin and tangent to the curve (for custom gamma correction).
const float start   = 0.018;    // "Abscissa at the point of tangency (for custom gamma correction).

float luminance(vec3 color) {
    return dot(color, vec3(0.2627, 0.6780, 0.0593));
}

float log10(float x) {
    return log(x) / log(10.0);
}

float customGamma(float C) {
    if (C <= start) {
        return slope * C;
    } else {
        return pow(1.099 * C, 0.9 / gamma) - 0.099;
    }
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 Cin = color.rgb;
    float Lin = luminance(Cin);

    // Bias the world adaptation and scale other parameters accordingly
    float   LwaP  = Lwa / pow(1.0 + b - 0.85, 5.0),
            LmaxP = Lmax / LwaP,
            LinP  = Lin / LwaP;

    // Apply tonemapping curve to luminance
    float   exponent = log(b) / log(0.5),
            c1       = (0.01 * Ldmax) / log10(1.0 + LmaxP),
            c2       = log(1.0 + LinP) / log(2.0 + 8.0 * pow(LinP / LmaxP, exponent)),
            Lout     = c1 * c2;

    // Treat color by preserving color ratios [Schlick 1994].
    vec3 Cout = Cin / Lin * Lout;

    // Apply a custom gamma curve and clamp
    Cout = vec3(customGamma(Cout.r), customGamma(Cout.g), customGamma(Cout.b));

    color.rgb = Cout;
    return color;
}