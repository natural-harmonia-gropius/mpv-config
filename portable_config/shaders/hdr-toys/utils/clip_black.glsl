//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Clip Code Value (Black Only)

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return max(color, 0.0);
}
