const { max, abs } = Math;

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

function RGB_2020_to_709(rgb) {
  const M = [
    [1.6605, -0.5876, -0.0728],
    [-0.1246, 1.1329, -0.0083],
    [-0.0182, -0.1006, 1.1187],
  ];
  return multiplyMatrices(M, rgb);
}

function XYZ_to_RGB_2020(X, Y, Z) {
  const M = [
    [1.7167, -0.3557, -0.2534],
    [-0.6667, 1.6165, 0.0158],
    [0.0176, -0.0428, 0.9421],
  ];
  return multiplyMatrices(M, [X, Y, Z]);
}

function xyY_to_XYZ(x, y, Y) {
  const X = (x * Y) / max(y, 1e-6);
  const Z = ((1.0 - x - y) * Y) / max(y, 1e-6);

  return [X, Y, Z];
}

function xyY_to_RGB_709(x, y, Y) {
  Y /= 100;
  const XYZ = xyY_to_XYZ(x, y, Y);
  const RGB2020 = XYZ_to_RGB_2020(...XYZ);
  const RGB709 = RGB_2020_to_709(RGB2020);
  return RGB709;
}

function distance(rgb) {
  const ac = max(...rgb);

  if (ac === 0) {
    return [0, 0, 0];
  }

  const d = [
    ac - rgb[0] / abs(ac),
    ac - rgb[1] / abs(ac),
    ac - rgb[2] / abs(ac),
  ];

  //   return max(...d);
  return d;
}

let c = RGB_2020_to_709([0, 1, 1]);
let m = RGB_2020_to_709([1, 0, 1]);
let y = RGB_2020_to_709([1, 1, 0]);
// console.log(c, m, y);

const l = [max(...distance(c)), max(...distance(m)), max(...distance(y))];
console.log("limit", l);

const color_checker = [
  distance(xyY_to_RGB_709(0.4, 0.35, 10.1)),
  distance(xyY_to_RGB_709(0.377, 0.345, 35.8)),
  distance(xyY_to_RGB_709(0.247, 0.251, 19.3)),
  distance(xyY_to_RGB_709(0.337, 0.422, 13.3)),
  distance(xyY_to_RGB_709(0.265, 0.24, 24.3)),
  distance(xyY_to_RGB_709(0.261, 0.343, 43.1)),
  distance(xyY_to_RGB_709(0.506, 0.407, 30.1)),
  distance(xyY_to_RGB_709(0.211, 0.175, 12.0)),
  distance(xyY_to_RGB_709(0.453, 0.306, 19.8)),
  distance(xyY_to_RGB_709(0.285, 0.202, 6.6)),
  distance(xyY_to_RGB_709(0.38, 0.489, 44.3)),
  distance(xyY_to_RGB_709(0.473, 0.438, 43.1)),
  distance(xyY_to_RGB_709(0.187, 0.129, 6.1)),
  distance(xyY_to_RGB_709(0.305, 0.478, 23.4)),
  distance(xyY_to_RGB_709(0.539, 0.313, 12.0)),
  distance(xyY_to_RGB_709(0.448, 0.47, 59.1)),
  distance(xyY_to_RGB_709(0.364, 0.233, 19.8)),
  distance(xyY_to_RGB_709(0.196, 0.252, 19.8)),
  distance(xyY_to_RGB_709(0.31, 0.316, 90.0)),
  distance(xyY_to_RGB_709(0.31, 0.316, 59.1)),
  distance(xyY_to_RGB_709(0.31, 0.316, 36.2)),
  distance(xyY_to_RGB_709(0.31, 0.316, 19.8)),
  distance(xyY_to_RGB_709(0.31, 0.316, 9.0)),
  distance(xyY_to_RGB_709(0.31, 0.316, 3.1)),
];
const t = color_checker.reduce((p, c) => [
  max(p[0], c[0]),
  max(p[1], c[1]),
  max(p[2], c[2]),
]);
console.log("threshold", t);
