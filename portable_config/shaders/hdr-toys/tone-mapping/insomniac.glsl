// Filmic curve by Mike Day, Also known as the "Insomniac curve".
// https://d3cw3dd2w32x2b.cloudfront.net/wp-content/uploads/2012/09/an-efficient-and-user-friendly-tone-mapping-operator.pdf

//!PARAM WHITE_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM WHITE_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (insomniac)

float w = 1.0;    // White point. Smallest value that is mapped to 1.
float b = 0.0;    // Black point. Largest value that is mapped to 0.
float t = 0.7;    // Toe strength. Amount of blending between a straight-line curve and a purely asymptotic curve for the toe.
float s = 0.8;    // Shoulder strength. Amount of blending between a straight-line curve and a purely asymptotic curve for the shoulder.
float c = 2.0;    // Cross-over point. Point where the toe and shoulder are pieced together into a single curve.
float k = 0.0;

float curve(float x) {
    w = WHITE_hdr / WHITE_sdr;
    k = (1.0 - t) * (c - b) / ((1.0 - s) * (w - c) + (1.0 - t) * (c - b));
    float a = x < c ?
        k * (1.0 - t) * (x - b) / (c - (1.0 - t) * b - t * x) :
        (1.0 - k) * (x - c) / (s * x + (1.0 - s) * w - c) + k;
    return max(a, 0.0);
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
