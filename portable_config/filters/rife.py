from tempfile import gettempdir

from vapoursynth import MATRIX_BT709, RGBH
from vsmlrt import RIFE, BackendV2, RIFEModel


def rife(clip, fps):
    pixel_format = clip.format.id
    clip = clip.misc.SCDetect(threshold=0.2)
    clip = clip.resize.Bilinear(format=RGBH, matrix_in=MATRIX_BT709)
    clip = RIFE(
        clip,
        model=RIFEModel.v4_26,
        ensemble=False,
        backend=BackendV2.TRT(
            num_streams=4,
            fp16=True,
            output_format=1,
            use_cuda_graph=True,
            engine_folder=gettempdir(),
        ),
        video_player=True,
        _implementation=2,
    )
    clip = clip.resize.Bilinear(format=pixel_format, matrix=MATRIX_BT709)
    return clip, fps * 2
