//!HOOK OUTPUT
//!BIND HOOKED
//!DESC clip code value (black)

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    color.rgb = max(color.rgb, 0.0);

    return color;
}
