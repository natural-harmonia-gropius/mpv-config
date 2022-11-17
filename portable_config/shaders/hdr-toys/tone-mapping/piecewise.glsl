// Filmic curve by John Hable. Based on the "Uncharted 2", but updated with a better controllability.
// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (piecewise)

vec3 RGB_to_XYZ(float R, float G, float B) {
    mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return M * vec3(R, G, B);
}

vec3 XYZ_to_RGB(float X, float Y, float Z) {
    mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return M * vec3(X, Y, Z);
}

vec3 XYZ_to_xyY(float X, float Y, float Z) {
    float divisor = X + Y + Z;
    if (divisor == 0.0) divisor = 1e-6;

    float x = X / divisor;
    float y = Y / divisor;

    return vec3(x, y, Y);
}

vec3 xyY_to_XYZ(float x, float y, float Y) {
    float X = x * Y / max(y, 1e-6);
    float Z = (1.0 - x - y) * Y / max(y, 1e-6);

    return vec3(X, Y, Z);
}

vec2 asSlopeIntercept(float x0, float x1, float y0, float y1) {
    float dy = (y1 - y0);
    float dx = (x1 - x0);
    float m  = dx == 0.0 ? 1.0 : dy / dx;
    float b  = y0 - x0 * m;
    return vec2(m, b);
}

float evalDerivativeLinearGamma(float m, float b, float g, float x) {
    return g * m * pow(m * x + b, g - 1.0);
}

vec2 solveAB(float x0, float y0, float m) {
    float B   = (m * x0) / y0;
    float lnA = log(y0) - B * log(x0);
    return vec2(lnA, B);
}

float evalCurveSegment(float x, float offsetX, float offsetY, float scaleX, float scaleY, float lnA, float B) {
    float x0 = (x - offsetX) * scaleX;
    float y0 = x0 > 0.0 ? exp(lnA + B * log(x0)) : 0.0;
    return y0 * scaleY + offsetY;
}

// User Params
const float toeStrength = 0.1;  // [0-1]
const float toeLength = 0.2;  // [0-1]
const float shoulderStrength = 3.3;  // in F stops [0-10]
const float shoulderLength = 0.5;  // [0-1]
const float shoulderAngle = 1.0;  // [0-1]

const float gamma = 1.0;

float curve(float x) {
    // Convert from "user" to "direct" parameters

    // This is not actually the display gamma. It's just a UI space to avoid having
    // to enter small numbers for the input.
    // As a simple trick, we can apply a power of 2.2 to toeLength to allow finer
    // control of the toe.
    const float perceptualGamma = 2.4;

    float x0 = pow(toeLength, perceptualGamma) * 0.5;  // toe goes from 0 to 0.5
    float y0 = (1.0 - toeStrength ) * x0; // lerp from 0 to x0

    const float remainingY = 1.0 - y0;

    const float y1_offset = (1.0 - shoulderLength) * remainingY;
    float x1 = x0 + y1_offset;
    float y1 = y0 + y1_offset;

    const float initialW = x0 + remainingY;
    const float extraW = pow(2.0, shoulderStrength) - 1.0;
    const float W = initialW + extraW;

    float overshootX = (2.0 * W) * shoulderAngle * shoulderStrength / W;
    float overshootY = 0.5 * shoulderAngle * shoulderStrength;

    x0 /= W;
    x1 /= W;

    // Precompute information for all three segments (mid, toe, shoulder)
    const vec2  tmp = asSlopeIntercept(x0, x1, y0, y1);
    const float m = tmp.x,
                b = tmp.y,
                g = 1.0 / gamma;

    if (g != 1.0) {
        y0 = max(pow(y0, g), 1e-6);
        y1 = max(pow(y1, g), 1e-6);
        overshootY = pow(1.0 + overshootY, g) - 1.0;
    }

    float   midOffsetX  = -(b / m),
            midOffsetY  = 0.0,
            midScaleX   = 1.0,
            midScaleY   = 1.0,
            midLnA      = g * log(m),
            midB        = g;

    const float toeM = evalDerivativeLinearGamma(m, b, g, x0);
    const vec2  toeAB   = solveAB(x0, y0, m);
    float   toeOffsetX  = 0.0,
            toeOffsetY  = 0.0,
            toeScaleX   = 1.0,
            toeScaleY   = 1.0,
            toeLnA      = toeAB.x,
            toeB        = toeAB.y;

    const float shoulderX0  = (1.0 + overshootX) - x1;
    const float shoulderY0  = (1.0 + overshootY) - y1;
    const float shoulderM   = evalDerivativeLinearGamma(m, b, g, x1);
    const vec2  shoulderAB  = solveAB(shoulderX0, shoulderY0, m);
    float   shoulderOffsetX = 1.0 + overshootX,
            shoulderOffsetY = 1.0 + overshootY,
            shoulderScaleX  = -1.0,
            shoulderScaleY  = -1.0,
            shoulderLnA     = shoulderAB.x,
            shoulderB       = shoulderAB.y;

    // Normalize (correct for overshooting)
    const float scale = 1.0 / evalCurveSegment(1.0,
        shoulderOffsetX, shoulderOffsetY,
        shoulderScaleX, shoulderScaleY,
        shoulderLnA, shoulderB);
    toeOffsetY      *= scale;
    toeScaleY       *= scale;
    midOffsetY      *= scale;
    midScaleY       *= scale;
    shoulderOffsetY *= scale;
    shoulderScaleY  *= scale;

    const float Xn = x / W;
    float result;
    if (Xn < x0) {
        result = evalCurveSegment(Xn,
            toeOffsetX, toeOffsetY,
            toeScaleX, toeScaleY,
            toeLnA, toeB);
    } else if (Xn < x1) {
        result = evalCurveSegment(Xn,
            midOffsetX, midOffsetY,
            midScaleX, midScaleY,
            midLnA, midB);
    } else {
        result = evalCurveSegment(Xn,
            shoulderOffsetX, shoulderOffsetY,
            shoulderScaleX, shoulderScaleY,
            shoulderLnA, shoulderB);
    }

    return result;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb = RGB_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_xyY(color.r, color.g, color.b);
    color.z  *= curve(color.z) / color.z;
    color.rgb = xyY_to_XYZ(color.r, color.g, color.b);
    color.rgb = XYZ_to_RGB(color.r, color.g, color.b);
    return color;
}
