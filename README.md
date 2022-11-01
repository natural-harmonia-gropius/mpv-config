# mpv_config

Personal portable_config for MPV player, The aim is to use it right out of the box.

Except users of Windows 11 need to put [Segoe Fluent Icons](https://aka.ms/SegoeFluentIcons) into fonts folder to use my [modified uosc](https://github.com/Natural-Harmonia-Gropius/uosc).  
Also [Segoe UI Variable](https://aka.ms/SegoeUIVariable) needs to be added manually.

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
vo=gpu-next

glsl-shader=~~/shaders-toys/Helper/ClipBlack.glsl
# glsl-shader=~~/shaders-toys/HLG_to_Y.glsl
glsl-shader=~~/shaders-toys/PQ_to_Y.glsl
glsl-shader=~~/shaders-toys/Tonemapper/BT2446C.glsl
glsl-shader=~~/shaders-toys/Y_to_CV.glsl
# glsl-shader=~~/shaders-toys/Tonemapper/Reinhard.glsl
# glsl-shader=~~/shaders-toys/Tonemapper/Hable.glsl
# glsl-shader=~~/shaders-toys/Tonemapper/ACES_KN_yc.gls
# glsl-shader=~~/shaders-toys/Tonemapper/BT2446A.glsl
glsl-shader=~~/shaders-toys/CV_to_BT1886.glsl

lut=~~/luts/Rec202012-bit_Rec2020-Rec202012-bit_Rec709.cube
lut-type=conversion
```

### Roadmap

Tone Mapping

- [x] Reinhard
- [x] Uncharted 2
- [ ] BT.2390
- [ ] BT.2446 Method A
- [ ] BT.2446 Method C
- [ ] BT.2446 Method C - with chroma correction

Gamut Mapping

- [ ] BT.2407

Overkill

- [ ] ACES Output Transform
