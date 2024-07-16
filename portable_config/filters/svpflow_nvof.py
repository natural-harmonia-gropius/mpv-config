import vapoursynth as vs
from shared import to_yuv420


def svpflow_nvof(clip, fps, super_param="{ gpu: 1 }"):
    clip, clip8 = to_yuv420(clip)
    clip = vs.core.svp2.SmoothFps_NVOF(
        clip, super_param, nvof_src=clip8, src=clip, fps=fps
    )
    return clip, fps * 2
