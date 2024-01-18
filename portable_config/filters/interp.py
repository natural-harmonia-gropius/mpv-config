import math

from portable_config.filters.mvtools import mvtools
from portable_config.filters.rife import rife
from portable_config.filters.shared import fit_scale_down
from portable_config.filters.svpflow import svpflow
from portable_config.filters.svpflow_nvof import svpflow_nvof

CLIP = video_in  # 原始帧
W = video_in_dw  # 原始帧宽度
H = video_in_dh  # 原始帧高度
FPS = container_fps  # 原始帧率
FREQ = display_fps  # 屏幕刷新率
RES = display_res  # 屏幕分辨率


def main(clip=CLIP, fps=FPS):
    vw = min(RES[0], 1920)
    vh = min(RES[1], 1080)

    den = round(1e6)
    num = den * math.gcd(math.trunc(round(FREQ) / 60) * 60, 120)

    if FREQ != round(FREQ):
        num = num / 1.001

    # https://www.svp-team.com/wiki/Manual:SVPflow
    sp = """{ gpu: 1 }"""
    ap = """{
        block: { w: 32, h: 16, overlap: 2 },
        main: {
            levels: 5,
            search: {
                type: 4, distance: -12,
                coarse: { type: 4, distance: -1, trymany: true, bad: { range: 0 } }
            },
            penalty: { lambda: 3.33, plevel: 1.33, lsad: 3300, pzero: 110, pnbour: 50 }
        },
        refine: [{ thsad: 400 }, { thsad: 200, search: { type: 4, distance: -4 } }]
    }"""
    fp = """{
        gpuid: %d, rate: { num: %d, den: %d, abs: %s },
        algo: 23, mask: { cover: 80, area: 30, area_sharp: 0.75 },
        scene: { mode: 0, limits: { scene: 6000, zero: 100, blocks: 40 } }
    }"""

    clip = fit_scale_down(clip, vw, vh)
    clip, fps = rife(clip, fps)
    clip, fps = svpflow(clip, fps, num, den, sp, ap, fp)

    return clip


main().set_output()
