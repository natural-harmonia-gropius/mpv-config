# mpv config

Personal portable_config for MPV player.

## Getting started

### mpv-player

- [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
- [zhongfly/mpv-winbuild](https://github.com/zhongfly/mpv-winbuild/releases)
- [aur/mpv-full-git](https://aur.archlinux.org/packages/mpv-full-git) (Arch linux)

#### after installation

- Download and extract [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config/archive/refs/heads/master.zip).
- Move `portable_config` to the folder where mpv.exe is located.
- Put [Segoe Fluent Icons](https://aka.ms/SegoeFluentIcons) and [Segoe UI Variable](https://aka.ms/SegoeUIVariable) in `portable_config/fonts`. (Non Windows 11)
- Delete or edit `uosc-languages` line in mpv.conf. (Non Chinese)

### yt-dlp (optional)

- Get it from [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases), put it in mpv folder.
- or [yt-dlp-nightly-builds](https://github.com/yt-dlp/yt-dlp-nightly-builds/releases)

### vapoursynth (optional)

- Get it from [vapoursynth](https://github.com/vapoursynth/vapoursynth/releases), [python](https://www.python.org/downloads) also required, extract them to mpv folder.
- Separate folder solution: [将便携版 vapoursynth（python）与 mpv 目录分开的新方法](https://github.com/hooke007/MPV_lazy/discussions/484)

#### plugins

- [AmusementClub/vs-mlrt](https://github.com/AmusementClub/vs-mlrt/releases/tag/v15.4)
- [vapoursynth/vs-miscfilters-obsolete](https://github.com/vapoursynth/vs-miscfilters-obsolete/releases)
- [HomeOfVapourSynthEvolution/VapourSynth-VMAF](https://github.com/HomeOfVapourSynthEvolution/VapourSynth-VMAF/releases)
- [SVPflow](https://www.svp-team.com/get/)
- [dubhater/vapoursynth-mvtools](https://github.com/dubhater/vapoursynth-mvtools/releases)

### ffmpeg (optional)

- Get it from [ffmpeg](https://ffmpeg.org/download.html)

## Credits

[mpv-player/TOOLS/lua](https://github.com/mpv-player/mpv/tree/master/TOOLS/lua)

- autocrop.lua
- autoload.lua

[fbriere/mpv-scripts](https://github.com/fbriere/mpv-scripts)

- sub-fonts-dir-auto.lua

[natural-harmonia-gropius/uosc](https://github.com/natural-harmonia-gropius/uosc) - forked from [tomasklaen/uosc](https://github.com/tomasklaen/uosc)

- uosc.lua

[po5/thumbfast](https://github.com/po5/thumbfast)

- thumbfast.lua

[natural-harmonia-gropius/mpv-quality-menu](https://github.com/natural-harmonia-gropius/mpv-quality-menu) - forked from [christoph-heinrich/mpv-quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu)

- quality-menu.lua

[natural-harmonia-gropius/recent-menu](https://github.com/natural-harmonia-gropius/recent-menu)

- recentmenu.lua

[natural-harmonia-gropius/input-event](https://github.com/natural-harmonia-gropius/input-event)

- inputevent.lua

[po5/celebi](https://github.com/po5/celebi)

- celebi.lua

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

- hdr-toys/\*
