# mpv-config

Personal config for mpv-player.

## Getting Started

### mpv

- [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
- [zhongfly/mpv-winbuild](https://github.com/zhongfly/mpv-winbuild/releases)
- [aur/mpv-full-git](https://aur.archlinux.org/packages/mpv-full-git) (Arch Linux)

#### After Installation

1. Download and extract the [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config/archive/refs/heads/master.zip).
2. Move the `portable_config` directory to where `mpv.exe` is located.
3. If you're not using chinese, remove or edit the `uosc-languages` line in `mpv.conf`.

### yt-dlp (Optional)

- Download [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases) and add it to the mpv directory.
- Alternatively, use the [yt-dlp-nightly-builds](https://github.com/yt-dlp/yt-dlp-nightly-builds/releases) for more up-to-date versions.

### VapourSynth (Optional)

- Download [VapourSynth](https://github.com/vapoursynth/vapoursynth/releases) and [Python](https://www.python.org/downloads), then extract them to the mpv directory.
- To separate these from the mpv directory, follow this guide: [New method for separating portable VapourSynth (Python) from mpv directory](https://github.com/hooke007/MPV_lazy/discussions/484).

#### Plugins

- [AmusementClub/vs-mlrt](https://github.com/AmusementClub/vs-mlrt/releases)
- [vapoursynth/vs-miscfilters-obsolete](https://github.com/vapoursynth/vs-miscfilters-obsolete/releases)
- [HomeOfVapourSynthEvolution/VapourSynth-VMAF](https://github.com/HomeOfVapourSynthEvolution/VapourSynth-VMAF/releases)
- [SVPflow](https://www.svp-team.com/get/)
- [dubhater/vapoursynth-mvtools](https://github.com/dubhater/vapoursynth-mvtools/releases)

### FFmpeg (Optional)

- Download [FFmpeg](https://ffmpeg.org/download.html) and move it to the mpv directory.

## Credits

Scripts and shaders used in this configuration:

[mpv-player/TOOLS/lua](https://github.com/mpv-player/mpv/tree/master/TOOLS/lua)

- autocrop.lua
- autoload.lua

[fbriere/mpv-scripts](https://github.com/fbriere/mpv-scripts)

- sub-fonts-dir-auto.lua

[natural-harmonia-gropius/uosc](https://github.com/natural-harmonia-gropius/uosc) (forked from [tomasklaen/uosc](https://github.com/tomasklaen/uosc))

- uosc/\*.lua
- uosc\_\*.ttf

[po5/thumbfast](https://github.com/po5/thumbfast)

- thumbfast.lua

[natural-harmonia-gropius/mpv-quality-menu](https://github.com/natural-harmonia-gropius/mpv-quality-menu) (forked from [christoph-heinrich/mpv-quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu))

- quality-menu.lua

[natural-harmonia-gropius/recent-menu](https://github.com/natural-harmonia-gropius/recent-menu)

- recentmenu.lua

[natural-harmonia-gropius/input-event](https://github.com/natural-harmonia-gropius/input-event)

- inputevent.lua

[po5/celebi](https://github.com/po5/celebi)

- celebi.lua

[AmusementClub/vs-mlrt](https://github.com/AmusementClub/vs-mlrt/tree/master/scripts)

- vsmlrt.py

[bjin/mpv-prescalers](https://github.com/bjin/mpv-prescalers/tree/master/compute)

- ravu-zoom-ar-r3.glsl
- nnedi3-nns128-win8x4.glsl

[igv/FSRCNNX](https://github.com/igv/FSRCNN-TensorFlow/releases)

- FSRCNNX_x2_8-0-4-1.glsl
- FSRCNNX_x2_16-0-4-1.glsl

[Artoriuz/glsl-chroma-from-luma-prediction](https://github.com/Artoriuz/glsl-chroma-from-luma-prediction)

- CfL_Prediction.glsl

[igv/gist](https://gist.github.com/igv)

- KrigBilateral.glsl
- SSimSuperRes.glsl
- SSimDownscaler.glsl
- adaptive-sharpen.glsl

[an3223/dotfiles](https://github.com/AN3223/dotfiles/tree/master/.config/mpv/shaders)

- nlmeans.glsl
- guided.glsl
- hdeband.glsl

[haasn/libplacebo.org#example](https://libplacebo.org/custom-shaders/#full-example)

- filmgrain.glsl

[natural-harmonia-gropius/hdr-toys](https://github.com/natural-harmonia-gropius/hdr-toys)

- hdr-toys.conf
- hdr-toys.js
- hdr-toys/\*.glsl
