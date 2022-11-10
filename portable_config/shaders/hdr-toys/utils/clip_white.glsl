//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Clip Code Value (White Only)

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return min(color, 1.0);
}
