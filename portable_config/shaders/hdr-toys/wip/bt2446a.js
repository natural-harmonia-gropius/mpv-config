const { pow, log, max } = Math;

const Lhdr = 1000.0;
const Lsdr = 100.0;

function f(Y) {
  const pHDR = 1.0 + 32.0 * pow(Lhdr / 10000.0, 1.0 / 2.4); // 13.25979791858332
  const pSDR = 1.0 + 32.0 * pow(Lsdr / 10000.0, 1.0 / 2.4); // 5.696957656390622

  const Yp = log(1.0 + (pHDR - 1.0) * Y) / log(pHDR);

  let Yc;
  if (Yp <= 0.7399) Yc = Yp * 1.077;
  else if (Yp < 0.9909) Yc = Yp * (-1.151 * Yp + 2.7811) - 0.6302;
  else Yc = Yp * 0.5 + 0.5;

  const Ysdr = (pow(pSDR, Yc) - 1.0) / (pSDR - 1.0);

  return { Y_in: Y, Y_out: Ysdr, Yp, Yc };
}

const arr = [];
for (let i = 0; i <= 20; i++) arr.push(i / 10);
console.table(arr.map((v) => f(v)));
