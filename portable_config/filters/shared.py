from vapoursynth import YUV420P8, YUV420P10


def fit_scale_down(clip, viewport_width=1920, viewport_height=1080, step=4):
    width = clip.width
    height = clip.height

    ratio = max(width / viewport_width, height / viewport_height)

    if ratio <= 1:
        return clip

    width = round(width / ratio / step) * step
    height = round(height / ratio / step) * step

    clip = clip.resize.Spline36(width=width, height=height)

    return clip


def to_yuv420(clip):
    if clip.format.id == YUV420P8:
        clip8 = clip
    elif clip.format.id == YUV420P10:
        clip8 = clip.resize.Bicubic(format=YUV420P8)
    else:
        clip = clip.resize.Bicubic(format=YUV420P10)
        clip8 = clip.resize.Bicubic(format=YUV420P8)
    return clip, clip8
