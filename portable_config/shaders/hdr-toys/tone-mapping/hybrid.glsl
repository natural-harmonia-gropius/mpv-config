//!PARAM L_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (hybrid)

const float pq_m1 = 0.1593017578125;
const float pq_m2 = 78.84375;
const float pq_c1 = 0.8359375;
const float pq_c2 = 18.8515625;
const float pq_c3 = 18.6875;

const float pq_C  = 10000.0;

float Y_to_ST2084(float C) {
    float L = C / pq_C;
    float Lm = pow(L, pq_m1);
    float N = (pq_c1 + pq_c2 * Lm) / (1.0 + pq_c3 * Lm);
    N = pow(N, pq_m2);
    return N;
}

float ST2084_to_Y(float N) {
    float Np = pow(N, 1.0 / pq_m2);
    float L = Np - pq_c1;
    if (L < 0.0 ) L = 0.0;
    L = L / (pq_c2 - pq_c3 * Np);
    L = pow(L, 1.0 / pq_m1);
    return L * pq_C;
}

vec3 RGB_to_XYZ(float R, float G, float B) {
    mat3 M = mat3(
        0.6370, 0.1446, 0.1689,
        0.2627, 0.6780, 0.0593,
        0.0000, 0.0281, 1.0610);
    return vec3(R, G, B) * M;
}

vec3 XYZ_to_RGB(float X, float Y, float Z) {
    mat3 M = mat3(
         1.7167, -0.3557, -0.2534,
        -0.6667,  1.6165,  0.0158,
         0.0176, -0.0428,  0.9421);
    return vec3(X, Y, Z) * M;
}

vec3 XYZ_to_Cone(float X, float Y, float Z) {
    mat3 M = mat3(
         0.41478972, 0.579999,  0.0146480,
        -0.2015100,  1.120649,  0.0531008,
        -0.0166008,  0.264800,  0.6684799);
    return vec3(X, Y, Z) * M;
}

vec3 Cone_to_XYZ(float X, float Y, float Z) {
    mat3 M = mat3(
	     1.9242264357876067,  -1.0047923125953657,  0.037651404030618,
	     0.35031676209499907,  0.7264811939316552, -0.06538442294808501,
	    -0.09098281098284752, -0.3127282905230739,  1.5227665613052603);
    return vec3(X, Y, Z) * M;
}

vec3 Cone_to_Iab(float L, float M, float S) {
    mat3 MM = mat3(
        0.5,       0.5,       0.0,
        3.524000, -4.066708,  0.542708,
        0.199076,  1.096799, -1.295875);
    return vec3(L, M, S) * MM;
}

vec3 Iab_to_Cone(float I, float a, float b) {
    mat3 M = mat3(
	    1.0,                 0.1386050432715393,   0.05804731615611886,
	    0.9999999999999999, -0.1386050432715393,  -0.05804731615611886,
	    0.9999999999999998, -0.09601924202631895, -0.8118918960560388);
    return vec3(I, a, b) * M;
}

const float b = 1.15;
const float g = 0.66;

const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

vec3 RGB_to_Jzazbz(vec3 color, float L_sdr) {
    color *= L_sdr;

    color = RGB_to_XYZ(color.r, color.g, color.b);

    float Xm = (b * color.x) - ((b - 1.0) * color.z);
    float Ym = (g * color.y) - ((g - 1.0) * color.x);

    color = XYZ_to_Cone(Xm, Ym, color.z);

    color.r = Y_to_ST2084(color.r);
    color.g = Y_to_ST2084(color.g);
    color.b = Y_to_ST2084(color.b);

    color = Cone_to_Iab(color.r, color.g, color.b);

    color.r = ((1.0 + d) * color.r) / (1.0 + (d * color.r)) - d0;

    return color;
}

vec3 Jzazbz_to_RGB(vec3 color, float L_sdr) {
    color.r = (color.r + d0) / (1.0 + d - d * (color.r + d0));

    color = Iab_to_Cone(color.r, color.g, color.b);

    color.r = ST2084_to_Y(color.r);
    color.g = ST2084_to_Y(color.g);
    color.b = ST2084_to_Y(color.b);

    color = Cone_to_XYZ(color.r, color.g, color.b);

    float Xa = (color.x + ((b - 1.0) * color.z)) / b;
    float Ya = (color.y + ((g - 1.0) * Xa)) / g;

    color = XYZ_to_RGB(Xa, Ya, color.z);

    color /= L_sdr;

    return color;
}

vec3 Jzazbz_to_JzCzhz(vec3 color) {
    float az = color.g;
    float bz = color.b;

    color.g = sqrt(az * az + bz * bz);
    color.b = atan(bz, az);

    return color;
}

vec3 JzCzhz_to_Jzazbz(vec3 color) {
    float Cz = color.g;
    float hz = color.b;

    color.g = Cz * cos(hz);
    color.b = Cz * sin(hz);

    return color;
}

const float ip = 0.58535;   // linear length
const float k1 = 0.83802;   // linear strength
const float k3 = 0.74204;   // shoulder strength

float f(float Y, float k1, float k3, float ip) {
    ip /= k1;
    float k2 = (k1 * ip) * (1.0 - k3);
    float k4 = (k1 * ip) - (k2 * log(1.0 - k3));
    return Y < ip ?
        Y * k1 :
        log((Y / ip) - k3) * k2 + k4;
}

float curve(float x) {
    const float over_white = 1019.0 / 940.0;    // 109% range (super-whites)
    return f(x, k1, k3, ip) / over_white;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 src = color.rgb;

    vec3 rgb = vec3(curve(color.r), curve(color.g), curve(color.b));

    float L = dot(color.rgb, vec3(0.2627, 0.6780, 0.0593));
    vec3 lum = color.rgb * curve(L) / L;

    float norm = max(max(color.r, color.g), color.b);
    vec3 sat = color.rgb * curve(norm) / norm;

    src = RGB_to_Jzazbz(src, L_sdr);
    src = Jzazbz_to_JzCzhz(src);

    rgb = RGB_to_Jzazbz(rgb, L_sdr);
    rgb = Jzazbz_to_JzCzhz(rgb);

    lum = RGB_to_Jzazbz(lum, L_sdr);
    lum = Jzazbz_to_JzCzhz(lum);

    sat = RGB_to_Jzazbz(sat, L_sdr);
    sat = Jzazbz_to_JzCzhz(sat);

    color.rgb = vec3(mix(lum.r, sat.r, src.r), mix(lum.g, rgb.g, src.r), src.b);
    color.rgb = JzCzhz_to_Jzazbz(color.rgb);
    color.rgb = Jzazbz_to_RGB(color.rgb, L_sdr);

    return color;
}
