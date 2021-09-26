import vapoursynth as vs
from vapoursynth import core

clip = video_in
fps = container_fps or 23.976
freq = display_fps or 59.970
w, h = video_in_dw, video_in_dh

target_fps = 60, fps * 2, freq / 2
vw, vh = 1920, 1080

sp = "{ gpu: 1 }"
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
    refine: [{ thsad: 250 }, { thsad: 200, search: { type: 4, distance: -4 } }]
}"""
fp = """{
    algo: 23, rate: { num: %d, den: %d, abs: true },
    scene: { mode: 0, limits: { scene: 6000, zero: 100, blocks: 40 } },
    mask: { cover: 80, area: 30, area_sharp: 0.75 }
}""" % (round(max(target_fps)) * 1000, 1001)


def fit(clip, w, h, vw, vh):
    r = round(max(w/vw, h/vh))
    if r > 1:
        def f(x): return round(x/r/4)*4
        clip = clip.resize.Spline36(width=f(w), height=f(h))
    return clip


def toYUV420(clip):
    if clip.format.id == vs.YUV420P8:
        clip8 = clip
    elif clip.format.id == vs.YUV420P10:
        clip8 = clip.resize.Point(format=vs.YUV420P8)
    else:
        clip = clip.resize.Point(format=vs.YUV420P10)
        clip8 = clip.resize.Point(format=vs.YUV420P8)
    return clip, clip8


def svpflow(clip, fps, sp, ap, fp):
    clip, clip8 = toYUV420(clip)
    s = core.svp1.Super(clip8, sp)
    r = s["clip"], s["data"]
    v = core.svp1.Analyse(*r, clip, ap)
    r = *r, v["clip"], v["data"]
    clip = core.svp2.SmoothFps(clip, *r, fp, src=clip, fps=fps)
    return clip


clip = fit(clip, w, h, vw, vh)
clip = svpflow(clip, fps, sp, ap, fp)
clip.set_output()
