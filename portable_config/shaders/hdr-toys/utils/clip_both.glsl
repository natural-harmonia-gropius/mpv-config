//!HOOK OUTPUT
//!BIND HOOKED
//!DESC clip code value (black & white)

// Handle out-of-gamut values
// Clip values < 0 or > 1 (i.e. projecting outside the display primaries)
vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return vec4(clamp(color.rgb, 0.0, 1.0), color.a);
}
