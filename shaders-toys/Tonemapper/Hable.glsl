//!HOOK MAIN
//!BIND HOOKED
//!DESC Hable Tone Mapping

// Uncharted 2 devised by John Hable.
// sometimes known as 'Hable Tone Mapping' or 'Hable Filmic' etc.
// http://filmicgames.com/archives/75
float uncharted2(float x) {
    const float A = 0.15;   // Shoulder Strength
    const float B = 0.50;   // Linear Strength
    const float C = 0.10;   // Linear Angle
    const float D = 0.20;   // Toe Strength
    const float E = 0.02;   // Toe Numerator
    const float F = 0.30;   // Toe Denominator
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

float curve(float x) {
    const float W = 11.2;
    return uncharted2(x) / uncharted2(W);
}

vec3 mode_rgb(vec3 x) {
    return vec3(curve(x.r), curve(x.g), curve(x.b));
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_rgb(p.rgb);
    return p;
}
