// Simple conversion from BT.2020 to BT.709 based on linear matrix transformation
// RGB_rec2020 => XYZ => RGB_Rec709

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (bt.2407 matrix)

mat3 M = mat3(
     1.6605, -0.5876, -0.0728,
    -0.1246,  1.1329, -0.0083,
    -0.0182, -0.1006,  1.1187);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb *= M;
    return color;
}
