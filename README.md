# mpv-config

Personal config for mpv-player.

## Getting Started

### mpv

Download mpv from one of following repositories.

- [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake/releases/latest)
- [zhongfly/mpv-winbuild](https://github.com/zhongfly/mpv-winbuild/releases/latest)

After Installation

1. Download [natural-harmonia-gropius/mpv-config](https://github.com/natural-harmonia-gropius/mpv-config/archive/refs/heads/master.zip).
2. Move the `portable_config` folder to where `mpv.exe` is located.
3. If you're not using chinese, remove or edit the `uosc-languages` line in `mpv.conf`.

### yt-dlp (Optional)

Download yt-dlp from winget

```sh
sudo winget install yt-dlp.yt-dlp --skip-dependencies
```

### FFmpeg (Optional)

Download FFmpeg from winget

```sh
sudo winget install Gyan.FFmpeg
```

### VapourSynth (Optional)

- Download [VapourSynth R73](https://github.com/vapoursynth/vapoursynth/releases/tag/R73)
- Download [Python 3.13](https://www.python.org/downloads/latest/python3.13/)
- Copy all files from the VapourSynth folder to the Python folder, if a conflict arises, choose to replace them.
- Move the `VapourSynth` folder to where `mpv.exe` is located.
- Download [VSScript.dll](https://github.com/hooke007/mpv_PlayKit/discussions/484)
- Move the `VSScript.dll` to where `mpv.exe` is located.
- Run the following command in the VapourSynth folder.

```pwsh
& {
  # https://docs.python.org/3/library/site.html
  Get-Item .\python*._pth | ForEach-Object {
    (Get-Content $_ -Encoding UTF8) -replace '#\s*import site', 'import site' | Set-Content $_ -Encoding UTF8
  }

  # get-pip
  curl -s https://bootstrap.pypa.io/get-pip.py | ./python

  # pip install vapoursynth
  ./python -m pip install ./wheel/vapoursynth-73-cp312-abi3-win_amd64.whl
}
```

- Download plugins for vapoursynth, put into `VapourSynth\vs-plugins` folder.
  - [AmusementClub/vs-mlrt](https://github.com/AmusementClub/vs-mlrt/releases/latest)
  - [AmusementClub/vs-mlrt/External Models](https://github.com/AmusementClub/vs-mlrt/releases/tag/external-models)
  - [vapoursynth/vs-miscfilters-obsolete](https://github.com/vapoursynth/vs-miscfilters-obsolete/releases/latest)
  - [HomeOfVapourSynthEvolution/VapourSynth-VMAF](https://github.com/HomeOfVapourSynthEvolution/VapourSynth-VMAF/releases/latest)
  - [SVPflow](https://www.svp-team.com/get/)
  - [dubhater/vapoursynth-mvtools](https://github.com/dubhatervapoursynth/vapoursynth-mvtools/releases/latest)

## Credits

Third-party scripts and shaders used in this configuration:

[mpv-player/TOOLS/lua](https://github.com/mpv-player/mpv/tree/master/TOOLS/lua)

- autocrop.lua

[fbriere/mpv-scripts](https://github.com/fbriere/mpv-scripts)

- sub-fonts-dir-auto.lua

[natural-harmonia-gropius/uosc](https://github.com/natural-harmonia-gropius/uosc) (forked from [tomasklaen/uosc](https://github.com/tomasklaen/uosc))

- scripts/uosc/\*
- fonts/uosc\_\*

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

[an3223/dotfiles](https://github.com/AN3223/dotfiles/tree/master/.config/mpv/shaders)

- nlmeans.glsl

[mr-berndt/cinegrain](https://github.com/mr-berndt/cinegrain)

- cinegrain.glsl

[natural-harmonia-gropius/hdr-toys](https://github.com/natural-harmonia-gropius/hdr-toys)

- shaders/hdr-toys/\*
