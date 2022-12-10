//!HOOK OUTPUT
//!BIND HOOKED
//!DESC clip code value (black)

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return vec4(max(color.rgb, 0.0), color.a);
}
