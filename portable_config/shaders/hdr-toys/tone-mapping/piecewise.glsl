// Filmic curve by John Hable. Based on the "Uncharted 2", but updated with a better controllability.
// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone-mapping (piecewise)

const float gamma   = 1.2;  // Gamma correction value.
const float tStr    = 0.5;  // Toe strength.
const float tLen    = 0.5;  // Toe length.
const float sStr    = 2.0;  // Shoulder strength.
const float sLen    = 0.5;  // Shoulder length.
const float sAngle  = 1.0;  // Shoulder angle.

vec2 asSlopeIntercept(float x0, float x1, float y0, float y1) {
    float dy = (y1 - y0);
    float dx = (x1 - x0);
    float m  = dx == 0.0 ? 1.0 : dy / dx;
    float b  = y0 - x0*m;
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

float curve(float x) {
    // Convert from "user" to "direct" parameters
    float   tLen_       = pow(tLen, 2.4),
            x0          = 0.5 * tLen_,
            y0          = (1.0 - tStr) * x0,
            remainingY  = 1.0 - y0,
            initialW    = x0 + remainingY,
            y1Offset    = (1.0 - sLen) * remainingY,
            x1          = x0 + y1Offset,
            y1          = y0 + y1Offset,
            extraW      = pow(2.0, sStr) - 1.0,
            W           = initialW + extraW,
            overshootX  = (2.0 * W) * sAngle * sStr,
            overshootY  = 0.5 * sAngle * sStr,
            invGamma    = 1.0 / gamma;

    // Precompute information for all three segments (mid, toe, shoulder)
    float curveWinv = 1.0 / W;

    x0 /= W;
    x1 /= W;
    overshootX /= W;

    vec2 tmp = asSlopeIntercept(x0, x1, y0, y1);
    float   m = tmp.x,
            b = tmp.y,
            g = invGamma;

    float   midOffsetX  = -(b / m),
            midOffsetY  = 0.0,
            midScaleX   = 1.0,
            midScaleY   = 1.0,
            midLnA      = g * log(m),
            midB        = g;

    float   toeM        = evalDerivativeLinearGamma(m, b, g, x0),
            shoulderM   = evalDerivativeLinearGamma(m, b, g, x1);

    y0 = max(1e-5, pow(y0, invGamma));
    y1 = max(1e-5, pow(y1, invGamma));
    overshootY = pow(1.0 + overshootY, invGamma) - 1.0;

    tmp = solveAB(x0, y0, toeM);
    float   toeOffsetX  = 0.0,
            toeOffsetY  = 0.0,
            toeScaleX   = 1.0,
            toeScaleY   = 1.0,
            toeLnA      = tmp.x,
            toeB        = tmp.y;

    float   shoulderX0  = (1.0 + overshootX) - x1,
            shoulderY0  = (1.0 + overshootY) - y1;

    tmp = solveAB(shoulderX0, shoulderY0, shoulderM);
    float   shoulderOffsetX = 1.0 + overshootX,
            shoulderOffsetY = 1.0 + overshootY,
            shoulderScaleX  = -1.0,
            shoulderScaleY  = -1.0,
            shoulderLnA     = tmp.x,
            shoulderB       = tmp.y;

    // Normalize (correct for overshooting)
    float scale = evalCurveSegment(1.0,
        shoulderOffsetX, shoulderOffsetY,
        shoulderScaleX, shoulderScaleY,
        shoulderLnA, shoulderB);
    float invScale = 1.0 / scale;
    toeOffsetY      *= invScale;
    toeScaleY       *= invScale;
    midOffsetY      *= invScale;
    midScaleY       *= invScale;
    shoulderOffsetY *= invScale;
    shoulderScaleY  *= invScale;

    float normX = x * curveWinv;
    float res;
    if (normX < x0) {
        res = evalCurveSegment(normX,
            toeOffsetX, toeOffsetY,
            toeScaleX, toeScaleY,
            toeLnA, toeB);
    } else if (normX < x1) {
        res = evalCurveSegment(normX,
            midOffsetX, midOffsetY,
            midScaleX, midScaleY,
            midLnA, midB);
    } else {
        res = evalCurveSegment(normX,
            shoulderOffsetX, shoulderOffsetY,
            shoulderScaleX, shoulderScaleY,
            shoulderLnA, shoulderB);
    }

    return res;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    const float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    color.rgb *= curve(L) / L;
    return color;
}
