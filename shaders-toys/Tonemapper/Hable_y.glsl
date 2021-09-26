//!HOOK MAIN
//!BIND HOOKED
//!DESC Hable Tone Mapping (Relative luminance)

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

float y(vec3 x) {
    // https://en.wikipedia.org/wiki/Relative_luminance
    return dot(x, vec3(0.2126, 0.7152, 0.0722));
}

vec3 mode_y(vec3 x) {
    const float Y = y(x);
    return x * curve(Y) / Y;
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb = mode_y(p.rgb);
    return p;
}
