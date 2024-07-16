import os
import sys

current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)


import math

from mvtools import mvtools
from rife import rife
from shared import fit_scale_down
from svpflow import svpflow
from svpflow_nvof import svpflow_nvof

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

    clip = fit_scale_down(clip, vw, vh)

    if (fps * 2) < (num / den):
        clip, fps = rife(clip, fps)

    clip, fps = svpflow(clip, fps, num, den)

    return clip


main().set_output()
