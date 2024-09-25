import os
import sys

current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)


from math import gcd, trunc

from rife import rife
from shared import fit_scale_down
from svpflow import svpflow


def main(
    clip=video_in,
    width=video_in_dw,
    height=video_in_dh,
    fps=container_fps,
    freq=display_fps,
    viewport_width=display_res[0],
    viewport_height=display_res[1],
):
    vw = min(viewport_width, 1920)
    vh = min(viewport_height, 1080)

    den = round(1e6)
    num = den * gcd(trunc(round(freq) / 60) * 60, 120)

    if freq != round(freq):
        num = num / 1.001

    clip = fit_scale_down(clip, vw, vh)

    if (fps * 1.99) < (num / den):
        clip, fps = rife(clip, fps)

    if (fps * 1.99) < (num / den):
        clip, fps = svpflow(clip, fps, num, den)

    return clip


main().set_output()
