const { max, abs, pow, sqrt, sin, cos, atan2 } = Math;

function multiplyMatrices(A, B) {
  let m = A.length;

  if (!Array.isArray(A[0])) {
    // A is vector, convert to [[a, b, c, ...]]
    A = [A];
  }

  if (!Array.isArray(B[0])) {
    // B is vector, convert to [[a], [b], [c], ...]]
    B = B.map((x) => [x]);
  }

  let p = B[0].length;
  let B_cols = B[0].map((_, i) => B.map((x) => x[i])); // transpose B
  let product = A.map((row) =>
    B_cols.map((col) => {
      let ret = 0;

      if (!Array.isArray(row)) {
        for (let c of col) {
          ret += row * c;
        }

        return ret;
      }

      for (let i = 0; i < row.length; i++) {
        ret += row[i] * (col[i] || 0);
      }

      return ret;
    })
  );

  if (m === 1) {
    product = product[0]; // Avoid [[a, b, c, ...]]
  }

  if (p === 1) {
    return product.map((x) => x[0]); // Avoid [[a], [b], [c], ...]]
  }

  return product;
}

function RGB_to_XYZ(R, G, B) {
  const M = [
    [0.637, 0.1446, 0.1689],
    [0.2627, 0.678, 0.0593],
    [0.0, 0.0281, 1.061],
  ];
  return multiplyMatrices(M, [R, G, B]);
}

function XYZ_to_RGB(X, Y, Z) {
  const M = [
    [1.7167, -0.3557, -0.2534],
    [-0.6667, 1.6165, 0.0158],
    [0.0176, -0.0428, 0.9421],
  ];
  return multiplyMatrices(M, [X, Y, Z]);
}

const L_sdr = 203.0;

const delta = 6.0 / 29.0;
const deltac = (delta * 2.0) / 3.0;

function f1(x, delta) {
  return x > pow(delta, 3.0)
    ? pow(x, 1.0 / 3.0)
    : deltac + x / (3.0 * pow(delta, 2.0));
}

function f2(x, delta) {
  return x > delta ? pow(x, 3.0) : (x - deltac) * (3.0 * pow(delta, 2.0));
}

const XYZn = RGB_to_XYZ(L_sdr, L_sdr, L_sdr);

function XYZ_to_Lab(X, Y, Z) {
  X = f1(X / XYZn[0], delta);
  Y = f1(Y / XYZn[1], delta);
  Z = f1(Z / XYZn[2], delta);

  const L = 116.0 * Y - 16.0;
  const a = 500.0 * (X - Y);
  const b = 200.0 * (Y - Z);

  return [L, a, b];
}

function Lab_to_XYZ(L, a, b) {
  let Y = (L + 16.0) / 116.0;
  let X = Y + a / 500.0;
  let Z = Y - b / 200.0;

  X = f2(X, delta) * XYZn[0];
  Y = f2(Y, delta) * XYZn[1];
  Z = f2(Z, delta) * XYZn[2];

  return [X, Y, Z];
}

function Lab_to_LCHab(L, a, b) {
  const C = sqrt(a ** 2 + b ** 2);
  const H = atan2(b, a);

  return [L, C, H];
}

function LCHab_to_Lab(L, C, H) {
  const a = C * cos(H);
  const b = C * sin(H);
  return [L, a, b];
}

let color;
color = [0, 0, 0];
color = RGB_to_XYZ(...color);
color = XYZ_to_Lab(...color);
color = Lab_to_LCHab(...color);
color = LCHab_to_Lab(...color);
color = Lab_to_XYZ(...color);
color = XYZ_to_RGB(...color);
