from vapoursynth import core


def mvtools(
    clip,
    fps,
    num=2,
    den=1,
    super_param=None,
    analyse_param=None,
    flow_param=None,
):
    if super_param is None:
        super_param = {"pel": 2, "sharp": 2, "rfilter": 4}

    if analyse_param is None:
        analyse_param = {
            "overlap": 0,
            "overlapv": 0,
            "search": 3,
            "dct": 0,
            "truemotion": True,
            "blksize": 32,
            "blksizev": 32,
            "searchparam": 2,
            "badsad": 10000,
            "badrange": 24,
            "divide": 0,
        }

    if flow_param is None:
        flow_param = {
            "thscd1": 140,
            "thscd2": int(15 * 255 / 100),
            "blend": True,
            "mask": 2,
        }

    clip = core.std.AssumeFPS(clip, fpsnum=fps * 1e6, fpsden=1e6)
    mv_super = core.mv.Super(clip, **super_param)
    mv_backward = core.mv.Analyse(mv_super, **analyse_param, isb=True)
    mv_forward = core.mv.Analyse(mv_super, **analyse_param, isb=False)
    clip = core.mv.FlowFPS(
        clip,
        mv_super,
        mv_backward,
        mv_forward,
        **flow_param,
        num=1e6 * fps * num / den,
        den=1e6,
    )
    return clip, fps * num / den
