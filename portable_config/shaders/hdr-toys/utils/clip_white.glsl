//!HOOK OUTPUT
//!BIND HOOKED
//!DESC clip code value (white)

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return min(color, 1.0);
}
