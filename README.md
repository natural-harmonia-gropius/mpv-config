# mpv config

Personal portable_config for MPV player, The aim is to use it right out of the box.

Optimized uosc, based on my personal preference.  
[natural-harmonia-gropius/uosc](https://github.com/natural-harmonia-gropius/uosc)  
except users of windows 11 need to put [Segoe Fluent Icons](https://aka.ms/SegoeFluentIcons) and [Segoe UI Variable](https://aka.ms/SegoeUIVariable) into `~~/portable_config/fonts` folder.

Optimized HDR to SDR conversion, include dynamic curve and applied to a uniform color space.  
[natural-harmonia-gropius/hdr-toys](https://github.com/natural-harmonia-gropius/hdr-toys)

Optimized svpflow script, and optional rife enhancement.  
[~~/portable_config/filters/interp.py](https://github.com/natural-harmonia-gropius/mpv_config/blob/master/portable_config/filters/interp.py)  
I can't provide the required dll in this repository, sorry.

## Get executable files from following links

[mpv-player](https://github.com/shinchiro/mpv-winbuild-cmake/releases)  
[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)  
[vapoursynth](https://github.com/vapoursynth/vapoursynth/releases)  
[python](https://www.python.org/downloads)  
[ffmpeg](https://www.gyan.dev/ffmpeg/builds/#release-builds)

## Included file sources

[mpv-player/TOOLS/lua](https://github.com/mpv-player/mpv/tree/master/TOOLS/lua)

- autocrop.lua (Modified, but I can't remember what was changed)
- autoload.lua

[tomasklaen/uosc](https://github.com/darsain/uosc)

- uosc.lua

[po5/thumbfast](https://github.com/po5/thumbfast)

- thumbfast.lua

[christoph-heinrich/mpv-quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu)

- quality-menu.lua

[natural-harmonia-gropius/input-event](https://github.com/natural-harmonia-gropius/input-event)

- inputevent.lua

[po5/evafast](https://github.com/po5/evafast)

- evafast.lua

[bjin/mpv-prescalers](https://github.com/bjin/mpv-prescalers/tree/master/vulkan/compute)

- ravu-zoom-r3.glsl

[igv/FSRCNNX](https://github.com/igv/FSRCNN-TensorFlow/releases)

- FSRCNNX_x2_8-0-4-1.glsl
- FSRCNNX_x2_16-0-4-1.glsl

[igv/gist](https://gist.github.com/igv)

- KrigBilateral.glsl
- SSimSuperRes.glsl
- SSimDownscaler.glsl
- adaptive-sharpen.glsl
