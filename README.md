# mpv_config

Personal portable_config for MPV player, The aim is to use it right out of the box.

Except users of Windows 11 need to put [Segoe Fluent Icons](https://aka.ms/SegoeFluentIcons) and [Segoe UI Variable](https://aka.ms/SegoeUIVariable) into fonts folder to use my [modified uosc](https://github.com/Natural-Harmonia-Gropius/uosc).

Optimized HDR to SDR conversion, see [hdr-toys](https://github.com/Natural-Harmonia-Gropius/mpv_config/tree/main/portable_config/shaders/hdr-toys).

## Folders

### ./

- [mpv-player](https://github.com/shinchiro/mpv-winbuild-cmake/releases)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)
- [vapoursynth](https://github.com/vapoursynth/vapoursynth/releases)
- [python](https://www.python.org/downloads)
- [ffmpeg](https://www.gyan.dev/ffmpeg/builds/#release-builds)

### ~~/scripts

#### [mpv-player/TOOLS/lua](https://github.com/mpv-player/mpv/tree/master/TOOLS/lua)

- autocrop.lua
- autoload.lua

#### [tomasklaen/uosc](https://github.com/darsain/uosc)

- uosc.lua

#### [po5/thumbfast](https://github.com/po5/thumbfast)

- thumbfast.lua

#### [christoph-heinrich/mpv-quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu)

- quality-menu.lua

#### [Natural-Harmonia-Gropius/InputEvent](https://github.com/Natural-Harmonia-Gropius/InputEvent)

- inputevent.lua

#### [po5/evafast](https://github.com/po5/evafast)

- evafast.lua

### ~~/shaders

#### [bjin/mpv-prescalers](https://github.com/bjin/mpv-prescalers/tree/master/vulkan/compute)

- ravu-zoom-r3.glsl

#### [igv/FSRCNNX](https://github.com/igv/FSRCNN-TensorFlow/releases)

- FSRCNNX_x2_8-0-4-1.glsl
- FSRCNNX_x2_16-0-4-1.glsl

#### [igv/gist](https://gist.github.com/igv)

- KrigBilateral.glsl
- SSimSuperRes.glsl
- SSimDownscaler.glsl
- adaptive-sharpen.glsl

#### [agyild/gist](https://gist.github.com/agyild)

- FSR.glsl
- CAS.glsl
- NVScaler.glsl
- NVSharpen.glsl

#### [AN3223/dotfiles](https://github.com/AN3223/dotfiles/tree/master/.config/mpv/shaders)

- nlmeans.glsl
- nlmeans_next.glsl

### ~~/luts

These files are too large, please get them from the following links.

#### [Toru Yoshihara](https://github.com/toru-ver4)

- [Report ITU-R BT.2407 の Annex2 を実装してみた](https://trev16.hatenablog.com/entry/2020/06/07/094646)
- [BT.2446 Method C (HDR to SDR 変換) を実装してみた](https://trev16.hatenablog.com/entry/2020/08/01/131907)
- [HDR コンテンツの輝度マップ生成用の 3DLUT を作る](https://trev16.hatenablog.com/entry/2020/04/26/190416)

#### [Ben Turley](https://github.com/cameramanben)

- [LUT Calculator](https://cameramanben.github.io/LUTCalc/LUTCalc/index.html)
