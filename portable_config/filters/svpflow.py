import vapoursynth as vs
from shared import to_yuv420

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


def svpflow(
    clip,
    fps,
    num=2,
    den=1,
    super_param=sp,
    analyse_param=ap,
    flow_param=fp,
    gpu_id=0,
):
    quo = num / den

    if quo > fps:
        is_abs = "true"
    else:
        is_abs = "false"

    if is_abs == "true":
        ofps = quo
    elif is_abs == "false":
        ofps = quo * fps

    flow_param = flow_param % (gpu_id, num, den, is_abs)

    clip, clip8 = to_yuv420(clip)
    svp_super = vs.core.svp1.Super(clip8, super_param)
    svp_param = svp_super["clip"], svp_super["data"]
    svp_analyse = vs.core.svp1.Analyse(*svp_param, clip, analyse_param)
    svp_param = *svp_param, svp_analyse["clip"], svp_analyse["data"]
    clip = vs.core.svp2.SmoothFps(clip, *svp_param, flow_param, src=clip, fps=fps)
    return clip, round(ofps, 3)
