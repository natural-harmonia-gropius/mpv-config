# mpv_config

Personal portable_config for MPV player, The aim is to use it right out of the box.

Except users of Windows 11 need to put [Segoe Fluent Icons](https://aka.ms/SegoeFluentIcons) and [Segoe UI Variable](https://aka.ms/SegoeUIVariable) into fonts folder to use my [modified uosc](https://github.com/Natural-Harmonia-Gropius/uosc).

## TL;DR

[mpv-player](https://github.com/shinchiro/mpv-winbuild-cmake/releases)  
[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)  
[vapoursynth](https://github.com/vapoursynth/vapoursynth/releases)  
[python](https://www.python.org/downloads)  
[ffmpeg](https://www.gyan.dev/ffmpeg/builds/#release-builds)

[mpv-player/TOOLS/lua](https://github.com/mpv-player/mpv/tree/master/TOOLS/lua)  
[tomasklaen/uosc](https://github.com/darsain/uosc)  
[po5/thumbfast](https://github.com/po5/thumbfast)  
[christoph-heinrich/mpv-quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu)  
[Natural-Harmonia-Gropius/InputEvent](https://github.com/Natural-Harmonia-Gropius/InputEvent)

[bjin/mpv-prescalers](https://github.com/bjin/mpv-prescalers/tree/master/vulkan/compute)  
[igv/FSRCNNX](https://github.com/igv/FSRCNN-TensorFlow/releases)  
[igv/gist](https://gist.github.com/igv)  
[agyild/gist](https://gist.github.com/agyild)  
[AN3223/dotfiles](https://github.com/AN3223/dotfiles/tree/master/.config/mpv/shaders)

[cameramanben/LUTCalc](https://cameramanben.github.io/LUTCalc/LUTCalc/index.html)  
[toru-ver4/BT.2407 Annex2](https://trev16.hatenablog.com/entry/2020/06/07/094646)  
[toru-ver4/BT.2446 Method C](https://trev16.hatenablog.com/entry/2020/08/01/131907)  
[toru-ver4/Luminance Map](https://trev16.hatenablog.com/entry/2020/04/26/190416)

## About the shaders-toys folder

### How to use this?

TBD

```ini
[hdr]
profile-cond=get("video-params/sig-peak") > 1
profile-restore=copy
target-trc=pq
target-prim=bt.2020
# glsl-shader=~~/shaders/BT2100PQ_to_BT709.glsl
glsl-shader=~~/shaders/hdr-toys/utils/clip_black.glsl
glsl-shader=~~/shaders/hdr-toys/PQ_to_Y.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt.2446c.glsl
glsl-shader=~~/shaders/hdr-toys/Y_to_CV.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/linear.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/reinhard.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/hable.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/aces.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt.2446a.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/bt.2407_matrix.glsl
glsl-shader=~~/shaders/hdr-toys/CV_to_BT1886.glsl
```

### Roadmap

Tone Mapping

- [x] Linear
- [x] Reinhard
- [x] Hable
- [ ] BT.2446 Method A
- [ ] BT.2446 Method C
- [ ] BT.2390

Gamut Mapping

- [x] BT.2407 Matrix
- [ ] BT.2407 Annex 1
- [ ] BT.2407 Annex 2
- [ ] BT.2407 Annex 3
- [ ] BT.2407 Annex 4
- [ ] BT.2407 Annex 5
- [ ] BT.2407 Annex 6

Overkill

- [ ] ACES Output Transform
