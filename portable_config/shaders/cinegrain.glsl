// Film grain shader - luminance-weighted, spatially correlated, multi-scale
// Base PRNG: IQ hash12 (no periodicity, works on full 4K coordinate range)

//!PARAM INTENSITY
//!DESC Overall grain strength
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.09

//!PARAM PEAK
//!DESC Luminance where grain is strongest (0.0-1.0)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.40

//!PARAM ROLLOFF
//!DESC Bell curve width (larger = wider/flatter)
//!TYPE float
//!MINIMUM 0.01
//!MAXIMUM 2.0
0.40

//!PARAM GRAIN_SIZE
//!DESC Primary grain size in pixels (1.0 = 1px, 3.0 = 3px)
//!TYPE float
//!MINIMUM 0.5
//!MAXIMUM 6.0
0.75

//!PARAM COARSE_MIX
//!DESC Amount of coarse grain layer (coarse = GRAIN_SIZE x1.5)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.4

//!PARAM BLUR
//!DESC Grain texture (0 = smooth organic blobs, 1 = fine pixel noise)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.7

//!PARAM CHROMA
//!DESC Colour grain strength (R/B shift, film-style)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.2

//!PARAM SOFTNESS
//!DESC Spatial blur radius for grain (0=off, 1=soft, 3=very soft)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 8.0
0.0

//!PARAM DEMO
//!DESC Gray card mode (0=off, 0.5=50% gray)
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC cinegrain

// Hash a 2D grid cell + frame seed to [0,1]
// IQ hash12: no mod() wrapping, works on any coordinate range
float grid_hash(vec2 cell, float seed)
{
    vec2 p = cell + vec2(seed * 13.7, seed * 31.1);
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Per-pixel hash noise — spatially uncorrelated, returns [-1, 1]
float pixel_hash(vec2 pixel_pos, float seed)
{
    vec2 p = floor(pixel_pos) + vec2(seed * 13.7, seed * 31.1);
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z) * 2.0 - 1.0;
}

// Value noise with quintic smoothstep — returns [-1, 1]
float value_noise(vec2 pixel_pos, float size, float seed)
{
    vec2 p = pixel_pos / size;
    vec2 fl = floor(p);
    vec2 fr = fract(p);
    // Quintic smoothstep (C2 continuous, softer grid edges than cubic)
    fr = fr * fr * fr * (fr * (fr * 6.0 - 15.0) + 10.0);

    float n00 = grid_hash(fl + vec2(0.0, 0.0), seed);
    float n10 = grid_hash(fl + vec2(1.0, 0.0), seed);
    float n01 = grid_hash(fl + vec2(0.0, 1.0), seed);
    float n11 = grid_hash(fl + vec2(1.0, 1.0), seed);

    return mix(mix(n00, n10, fr.x), mix(n01, n11, fr.x), fr.y) * 2.0 - 1.0;
}

// Fine grain: value noise (organic, rounded shapes) mixed with 1px hash noise
// BLUR=0: smooth organic blobs at GRAIN_SIZE scale; BLUR=1: per-pixel hash noise
float fine_grain(vec2 pixel_pos, float size, float seed)
{
    // Value noise: smooth bilinear interpolation between random corners
    // No square boundaries — creates rounded, organic grain shapes
    float vn = value_noise(pixel_pos, size, seed);

    // Hash component: organic per-pixel texture, no blobs, fixed 1px blur
    float h0 = pixel_hash(pixel_pos,                    seed) * 2.0;
    float h1 = pixel_hash(pixel_pos + vec2( 1.0, 0.0), seed);
    float h2 = pixel_hash(pixel_pos + vec2(-1.0, 0.0), seed);
    float h3 = pixel_hash(pixel_pos + vec2( 0.0, 1.0), seed);
    float h4 = pixel_hash(pixel_pos + vec2( 0.0,-1.0), seed);
    float hash = (h0 + h1 + h2 + h3 + h4) / 6.0;

    return mix(vn, hash, BLUR);
}

// Blurred value noise: 5-tap cross (used for coarse layer)
float blurred_noise(vec2 pixel_pos, float size, float seed)
{
    float r = BLUR * size * 0.6;
    float n0 = value_noise(pixel_pos,                    size, seed) * 2.0;
    float n1 = value_noise(pixel_pos + vec2( r, 0.0),   size, seed);
    float n2 = value_noise(pixel_pos + vec2(-r, 0.0),   size, seed);
    float n3 = value_noise(pixel_pos + vec2(0.0,  r),   size, seed);
    float n4 = value_noise(pixel_pos + vec2(0.0, -r),   size, seed);
    return (n0 + n1 + n2 + n3 + n4) / 6.0;
}

// Asymmetric bell curve: tight Gaussian highlight rolloff × power-law shadow ramp.
// Highlight side uses ROLLOFF * 0.35 — grain fades faster above PEAK.
// Shadow side: (luma/PEAK)^0.18 with smoothstep cutoff below 3% luma.
// Power law gives film-like shadow grain; smoothstep kills it cleanly
// near true black to prevent black-level lift. Validated against scans.
float luma_weight(float luma)
{
    float r = (luma > PEAK) ? ROLLOFF * 0.35 : ROLLOFF;
    float d = (luma - PEAK) / r;
    float bell = exp(-0.5 * d * d);
    float shadow = min(pow(luma / max(PEAK, 0.001), 0.18), 1.0) * smoothstep(0.0, 0.03, luma);
    return bell * shadow;
}

float grain_sample(vec2 pos, float seed)
{
    float fine   = fine_grain(pos, GRAIN_SIZE, seed);
    float coarse = blurred_noise(pos, GRAIN_SIZE * 1.5, seed + 17.3);
    return mix(fine, coarse, COARSE_MIX);
}

vec4 hook()
{
    vec2 pixel_pos = HOOKED_pos * HOOKED_size;
    float seed = random;

    float grain;
    if (SOFTNESS < 0.001) {
        grain = grain_sample(pixel_pos, seed);
    } else {
        // 5-tap cross blur using fine_grain only (no coarse layer per tap).
        // PERFORMANCE COMPROMISE — physical correctness deferred:
        //
        // Using fine_grain instead of grain_sample means COARSE_MIX has no
        // effect when SOFTNESS > 0 (which is all current presets). This removes
        // the emulsion crystal clustering from the SOFTNESS path entirely.
        //
        // COARSE_MIX (crystal clustering in emulsion) and SOFTNESS (optical blur
        // from projection magnification) are physically distinct phenomena and
        // should both be active simultaneously. The correct implementation uses
        // grain_sample here (5 × 29 hash ops = 145 total) instead of fine_grain
        // (5 × 9 = 45). On GTX 1650 Ti at 4K the full grain_sample path was
        // borderline — the 5-tap version (56% of original 9-tap cost) is untested.
        //
        // COARSE_MIX active: grain_sample includes both fine + coarse layers.
        // Cost: 5 × grain_sample = 145 hash ops (OK on RTX 4060, borderline GTX 1650 Ti)
        float r = SOFTNESS * GRAIN_SIZE;
        grain  = grain_sample(pixel_pos,                   seed) * 0.238;
        grain += grain_sample(pixel_pos + vec2( r,  0.0), seed) * 0.190;
        grain += grain_sample(pixel_pos + vec2(-r,  0.0), seed) * 0.190;
        grain += grain_sample(pixel_pos + vec2(0.0,  r),  seed) * 0.190;
        grain += grain_sample(pixel_pos + vec2(0.0, -r),  seed) * 0.190;
    }

    vec4 color = HOOKED_tex(HOOKED_pos);
    if (DEMO > 0.0) color = vec4(vec3(DEMO), 1.0);
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    float weight = luma_weight(luma);

    color.rgb += vec3(INTENSITY * weight * grain);

    // Colour grain: correlated spatial structure, independent R/B shifts
    if (CHROMA > 0.0) {
        float size_c = GRAIN_SIZE * 1.8;  // chroma grain is coarser than luma
        float cr = fine_grain(pixel_pos, size_c, seed + 31.7);
        float cb = fine_grain(pixel_pos, size_c, seed + 57.2);
        float cw = INTENSITY * CHROMA * weight;
        color.r += cw * cr;
        color.b += cw * cb;
    }

    // Clamp to prevent negative values (dark channel clipping → black spots)
    color.rgb = max(color.rgb, vec3(0.0));

    return color;
}
