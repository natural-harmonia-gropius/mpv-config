// https://github.com/GPUOpen-Effects/FidelityFX-LPM

//!HOOK MAIN
//!BIND HOOKED
//!DESC open display transform

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    return color;
}
