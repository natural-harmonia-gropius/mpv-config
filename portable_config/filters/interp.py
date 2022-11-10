import vapoursynth as vs
from vapoursynth import core

CLIP = video_in  # 原始帧
W = video_in_dw  # 原始帧宽度
H = video_in_dh  # 原始帧高度
FPS = container_fps  # 原始帧率
FREQ = display_fps  # 屏幕刷新率

INTERP_THRESHOLD = 2  # 帧率与目标帧率的差值

if FPS < INTERP_THRESHOLD:
    raise Exception(
        "Interpolation is not possible, where the video frame rate is too low."
    )

if FREQ < INTERP_THRESHOLD:
    raise Exception(
        "Interpolation is not necessary, where the display refresh rate is too low."
    )

if FREQ - FPS < INTERP_THRESHOLD:
    raise Exception(
        "Interpolation is not necessary, where the frame rate is close to the refresh rate."
    )

VW = 1920  # 目标缩放宽度
VH = 1080  # 目标缩放高度

# 0: 禁用, 1: 启用, 2: 独占
RIFE = 0  # 启用 RIFE 预处理
MVTL = 0  # 启用 MVTools 预处理
NVOF = 0  # 启用 NVOF 预处理（不支持独占模式）

OFPS = 60  # 目标帧率
ADAPTIVE_OFPS = FREQ > OFPS  # 开启后输出帧率将被设置为：最大值(目标帧率, 双倍帧率, 半刷新率)
NTSC_OFPS = FREQ != round(FREQ)  # 开启后输出帧率将被设置为：取整(OFPS) / 1.001

SP = """{ gpu: 1 }"""  # https://www.svp-team.com/wiki/Manual:SVPflow
AP = """{
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
FP = """{
    gpuid: %d, rate: { num: %d, den: %d, abs: %s },
    algo: 23, mask: { cover: 80, area: 30, area_sharp: 0.75 },
    scene: { mode: 0, limits: { scene: 6000, zero: 100, blocks: 40 } }
}"""


def main(clip=CLIP, fps=FPS):
    if VW and VH:
        clip = fit_scale_down(clip, VW, VH)

    num = OFPS
    den = round(1e6)

    if ADAPTIVE_OFPS:
        num = max(OFPS, FPS * 2, FREQ / 2)

    if FREQ - num < INTERP_THRESHOLD:
        num = FREQ * den
    else:
        if NTSC_OFPS:
            num = round(num)
            num = num * den / 1.001
        else:
            num = num * den
    num = round(num)

    if RIFE == 2:
        num = round(num / fps)
        clip, fps = rife(clip, fps, num, den)
        return clip

    if MVTL == 2:
        num = round(num / fps)
        clip, fps = mvtools(clip, fps, num, den)
        return clip

    if RIFE:
        clip, fps = rife(clip, fps)

    if MVTL:
        clip, fps = mvtools(clip, fps)

    if NVOF:
        clip, fps = svpflow_nvof(clip, fps)

    if num / den - fps < INTERP_THRESHOLD:
        return clip

    clip, fps = svpflow(clip, fps, num, den, SP, AP, FP)
    return clip


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
    if clip.format.id == vs.YUV420P8:
        clip8 = clip
    elif clip.format.id == vs.YUV420P10:
        clip8 = clip.resize.Bicubic(format=vs.YUV420P8)
    else:
        clip = clip.resize.Bicubic(format=vs.YUV420P10)
        clip8 = clip.resize.Bicubic(format=vs.YUV420P8)
    return clip, clip8


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
        _abs = "true"
    else:
        _abs = "false"

    if _abs == "true":
        ofps = quo
    elif _abs == "false":
        ofps = quo * fps
    else:
        raise Exception('typeof "abs" must be <"true" | "false">')

    flow_param = flow_param % (gpu_id, num, den, _abs)

    clip, clip8 = to_yuv420(clip)
    svp_super = core.svp1.Super(clip8, super_param)
    svp_param = svp_super["clip"], svp_super["data"]
    svp_analyse = core.svp1.Analyse(*svp_param, clip, analyse_param)
    svp_param = *svp_param, svp_analyse["clip"], svp_analyse["data"]
    clip = core.svp2.SmoothFps(clip, *svp_param, flow_param, src=clip, fps=fps)
    return clip, round(ofps, 3)


def svpflow_nvof(clip, fps, super_param="{ gpu: 1 }"):
    clip, clip8 = to_yuv420(clip)
    clip = core.svp2.SmoothFps_NVOF(
        clip, super_param, nvof_src=clip8, src=clip, fps=fps
    )
    return clip, fps * 2


def mvtools(
    clip,
    fps,
    num=2,
    den=1,
    blocksize=2**4,
    th_diff=8 * 8 * 7,
    th_changed=14,
):
    clip = core.std.AssumeFPS(clip, fpsnum=fps * 1e6, fpsden=1e6)
    mv_super = core.mv.Super(clip, pel=2, hpad=blocksize, vpad=blocksize)
    mv_forward = core.mv.Analyse(
        mv_super, blksize=blocksize, isb=False, chroma=True, search=3, searchparam=2
    )
    mv_backward = core.mv.Analyse(
        mv_super, blksize=blocksize, isb=True, chroma=True, search=3, searchparam=2
    )
    clip = core.mv.FlowFPS(
        clip,
        mv_super,
        mv_backward,
        mv_forward,
        num=1e6 * fps * num / den,
        den=1e6,
        mask=0,
        thscd1=th_diff,
        thscd2=th_changed,
    )
    return clip, fps * num / den


def rife(
    clip,
    fps,
    num=2,
    den=1,
    model=9,
    tta=False,
    uhd=False,
    sc_threshold=0.2,
    skip_threshold=60.0,
    gpu_id=0,
    gpu_thread=2,
):
    pixel_format = clip.format.id
    signal_range = clip.get_frame(0).props._ColorRange
    if sc_threshold:
        clip = clip.misc.SCDetect(threshold=sc_threshold)
    clip = clip.resize.Bicubic(format=vs.RGBS, matrix_in=1)
    clip = clip.rife.RIFE(
        gpu_id=gpu_id,
        gpu_thread=gpu_thread,
        model=model,
        factor_num=num,
        factor_den=den,
        tta=tta,
        uhd=uhd,
        sc=bool(sc_threshold),
        skip=bool(skip_threshold),
        skip_threshold=skip_threshold,
    )
    clip = clip.resize.Bicubic(
        format=pixel_format, matrix=1, range=1 - signal_range or None
    )
    return clip, fps * num / den


main().set_output()
