//!HOOK MAIN
//!BIND HOOKED
//!DESC ITU-R BT.2446 Conversion Method C

vec3 RGB_to_XYZ(vec3 RGB) {
    const mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return M * RGB;
}

vec3 XYZ_to_RGB(vec3 XYZ) {
    const mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return M * XYZ;
}

// Transformations between CIE XYZ tristimulus values and CIE x,y
// chromaticity coordinates
vec3 XYZ_to_xyY(vec3 XYZ) {
    float divisor = (XYZ.x + XYZ.y + XYZ.z);
    if (divisor == 0) divisor = 1e-10;

    const float x = XYZ.x / divisor;
    const float y = XYZ.y / divisor;
    const float Y = XYZ.y;

    return vec3(x, y, Y);
}

vec3 xyY_to_XYZ(vec3 xyY) {
    const float x = xyY[0];
    const float y = xyY[1];
    const float Y = xyY[2];

    const float X = x * Y / max(y, 1e-10);
    const float Z = (1.0 - x - y) * Y / max(y, 1e-10);

    return vec3(X, Y, Z);
}

float ft(float t) {
    const float d = 6 / 29;
    return t > pow(d, 3) ? pow(t, 1 / 3) : pow(1 / d, 3) * t;
}

// Optional processing of chroma correction above HDR Reference White
vec3 chroma_correction(vec3 xyY) {
    const vec3 XYZ = xyY_to_XYZ(xyY);

    const float Xn = 192.93;
    const float Yn = 203;
    const float Zn = 221.05;

    const float L = 116 * ft(xyY.y / Yn) - 16;
    const float a = 500 * (ft(XYZ.x / Xn) - ft(XYZ.y / Yn));
    const float b = 200 * (ft(XYZ.y / Yn) - ft(XYZ.z / Zn));

    const float sigma = 1.0;
    const float Lref  = 203;
    const float Lmax  = 1000;

    const float Cab = sqrt(pow(a, 2) + pow(b, 2));
    const float hab = atan(b / a);

    const float fcor   = L > Lref ? 1 - sigma * (L - Lref) / (Lmax - Lref) : 1;
    const float Cabcor = fcor * Cab;
    const float acor   = Cabcor * cos(hab);
    const float bcor   = Cabcor * sin(hab);

    const float fy = (L + 16) / 116;
    const float fx = fy + acor / 500;
    const float fz = fy - bcor / 200;

    const float Y = fy > sigma ? Yn * pow(fy, 3) : (fy - 16 / 116) * 3 * pow(sigma, 2) * Yn;
    const float X = fx > sigma ? Xn * pow(fx, 3) : (fx - 16 / 116) * 3 * pow(sigma, 2) * Xn;
    const float Z = fz > sigma ? Zn * pow(fz, 3) : (fz - 16 / 116) * 3 * pow(sigma, 2) * Zn;

    return XYZ_to_xyY(vec3(X, Y, Z));
}

float tone_mapping(float Y) {
    const float k1 = 0.83802;
    const float k3 = 0.74204;
    const float ip = 58.5 / k1;

    const float k2 = k1 * (1 - k3) * ip;
    const float k4 = (k1 * ip) - (k2 * log(1 - k3));
    return Y >= ip ? log((Y / ip) - k3) * k2 + k4 : k1 * Y;
}

vec4 p = HOOKED_texOff(vec2(0.0, 0.0));
vec4 hook() {
    p.rgb   = RGB_to_XYZ(p.rgb);
    p.xyz   = XYZ_to_xyY(p.rgb);
    // p.xyz   = chroma_correction(p.xyz);
    p.z     = tone_mapping(p.z);
    p.xyz   = xyY_to_XYZ(p.xyz);
    p.rgb   = XYZ_to_RGB(p.xyz);
    return p;
}
