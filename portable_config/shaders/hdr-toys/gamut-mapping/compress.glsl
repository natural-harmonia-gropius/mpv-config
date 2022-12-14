// compress highly chromatic source colorimetry into a smaller gamut.
// https://github.com/jedypod/gamut-compress

//!PARAM threshold
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 0.3
0.15

//!PARAM cyan
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.147

//!PARAM magenta
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.264

//!PARAM yellow
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.006

//!PARAM select
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.2

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (compress)

mat3 M = mat3(
     1.6605, -0.5876, -0.0728,
    -0.1246,  1.1329, -0.0083,
    -0.0182, -0.1006,  1.1187);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 rgb = color.rgb;
    rgb = clamp(rgb, 0.0, 1.0);
    rgb *= M;

    // Amount of outer gamut to affect
    vec3 th = 1.0 - vec3(threshold);

    // Distance limit: How far beyond the gamut boundary to compress
    vec3 dl = 1.0 + vec3(cyan, magenta, yellow);

    // Calculate scale so compression function passes through distance limit: (x=dl, y=1)
    vec3 s;
    s.x = (1.0 - th.x) / sqrt(max(1.001, dl.x) - 1.0);
    s.y = (1.0 - th.y) / sqrt(max(1.001, dl.y) - 1.0);
    s.z = (1.0 - th.z) / sqrt(max(1.001, dl.z) - 1.0);

    // Achromatic axis
    float ac = max(rgb.x, max(rgb.y, rgb.z));

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac == 0.0 ? vec3(0.0) : (ac - rgb) / abs(ac);

    vec3 cd; // Compressed distance
    // Parabolic compression function: https://www.desmos.com/calculator/nvhp63hmtj
    cd.x = d.x < th.x ? d.x : s.x * sqrt(d.x - th.x + s.x * s.x / 4.0) - s.x * sqrt(s.x * s.x / 4.0) + th.x;
    cd.y = d.y < th.y ? d.y : s.y * sqrt(d.y - th.y + s.y * s.y / 4.0) - s.y * sqrt(s.y * s.y / 4.0) + th.y;
    cd.z = d.z < th.z ? d.z : s.z * sqrt(d.z - th.z + s.z * s.z / 4.0) - s.z * sqrt(s.z * s.z / 4.0) + th.z;

    // Inverse RGB Ratios to RGB
    vec3 crgb = ac - cd * abs(ac);

    crgb = mix(rgb, crgb, select);

    color.rgb = crgb;
    return color;
}
