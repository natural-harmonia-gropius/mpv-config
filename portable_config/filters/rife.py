import os

import vapoursynth as vs

current_dir = os.path.dirname(os.path.abspath(__file__))


def rife(
    clip,
    fps,
    num=2,
    den=1,
    model_path="models/rife-v4.22_ensembleFalse",
    tta=False,
    uhd=False,
    sc_threshold=0.2,
    skip_threshold=60.0,
    gpu_id=0,
    gpu_thread=2,
):
    pixel_format = clip.format.id
    if sc_threshold:
        clip = clip.misc.SCDetect(threshold=sc_threshold)
    clip = clip.resize.Bicubic(format=vs.RGBS, matrix_in=vs.MATRIX_BT709)
    clip = clip.rife.RIFE(
        gpu_id=gpu_id,
        gpu_thread=gpu_thread,
        model_path=f"{current_dir}/{model_path}",
        factor_num=num,
        factor_den=den,
        tta=tta,
        uhd=uhd,
        sc=bool(sc_threshold),
        skip=bool(skip_threshold),
        skip_threshold=skip_threshold,
    )
    clip = clip.resize.Bicubic(format=pixel_format, matrix=vs.MATRIX_BT709)
    return clip, fps * num / den
