import vapoursynth as vs
from vapoursynth import core

from portable_config.filters.shared import to_yuv420


def svpflow(
    clip,
    fps,
    num=2,
    den=1,
    super_param="{ gpu: 1 }",
    analyse_param="{}",
    flow_param="{ gpuid: %d, rate: { num: %d, den: %d, abs: %s } }",
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
    svp_super = core.svp1.Super(clip8, super_param)
    svp_param = svp_super["clip"], svp_super["data"]
    svp_analyse = core.svp1.Analyse(*svp_param, clip, analyse_param)
    svp_param = *svp_param, svp_analyse["clip"], svp_analyse["data"]
    clip = core.svp2.SmoothFps(clip, *svp_param, flow_param, src=clip, fps=fps)
    return clip, round(ofps, 3)
