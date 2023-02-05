# HDR-toys

Put this in your `mpv.conf`.  
The default combination is based on ITU-R BT.2446 Conversion Method C, highlights are optimized.

```ini
vo=gpu-next

[bt.2100]
profile-cond=get("video-params/sig-peak") > 1
profile-restore=copy
target-trc=pq
target-prim=bt.2020
glsl-shader=~~/shaders/hdr-toys/utils/clip_both.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/pq_to_l.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/l_to_linear.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk.glsl
glsl-shader=~~/shaders/hdr-toys/utils/chroma_correction.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/hybrid.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk_inverse.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/compress.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
glsl-shader-opts=alpha=0
```

- `vo=gpu-next` is required, the minimum version of mpv required is v0.35.0.
- Dolby Vision Profile 5 is not tagged as HDR by mpv, so it wouldn't activate this auto-profile.

Also you can use it to get a better experience to play BT.2020 content.

```ini
[bt.2020]
profile-cond=get("video-params/primaries") == "bt.2020" and get("video-params/sig-peak") == 1
profile-restore=copy
target-prim=bt.2020
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886_to_linear.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/compress.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
```

- If you use `gamut-mapping/matrix` here, you will see that the result is different from mpv (vo=gpu-next), this is due to the black point of BT.1886, I personally consider that the black point in color conversion is always 0.

## What are these? What are they for?

### Workflow

```mermaid
graph TD
    A[BT.2100-pq, BT.2100-hlg, HDR10+, Dolby Vision, etc.] -->|mpv --target-trc=pq --target-prim=bt.2020| B(BT.2100-pq)
    B -->|linearize and normalize| C(BT.2020 linear)
    C -->|tone mapping| D(BT.2020 linear - tone mapped)
    D -->|gamut mapping| E(BT.709 linear)
    E -->|bt1886| F[BT.709]
```

### Tone mapping

You can change the [tone mapping operator](https://github.com/Natural-Harmonia-Gropius/mpv_config/tree/main/portable_config/shaders/hdr-toys/tone-mapping) by replacing this line.  
For example, use reinhard instead of bt2446c.

```diff
- glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt2446c.glsl
+ glsl-shader=~~/shaders/hdr-toys/tone-mapping/reinhard.glsl
```

This table lists the features of operators.

- Operators below the blank row are for testing and should not be used for watching.

| Operator | Applied to | Conversion peak |
| -------- | ---------- | --------------- |
| hybrid   | JzCzhz     | 1000nit         |
| bt2390   | ICtCp      | HDR peak        |
| bt2446a  | YCbCr      | HDR peak        |
| bt2446c  | xyY        | 1000nit         |
| reinhard | YRGB       | HDR peak        |
| hable    | YRGB       | HDR peak        |
| hable2   | YRGB       | HDR peak        |
| suzuki   | YRGB       | 10000nit        |
| uchimura | YRGB       | 1000nit         |
| lottes   | maxRGB     | HDR peak        |
| hejl2015 | RGB        | HDR peak        |
|          |            |                 |
| clip     | RGB        | SDR peak        |
| linear   | YRGB       | HDR peak        |
| heatmap  | Y          | 10000nit        |

- HDR peak defaults to 1000nit.  
  You can set it manually with `set glsl-shader-opts L_hdr=N`  
  [hdr-toys-helper.lua](https://github.com/Natural-Harmonia-Gropius/mpv_config/blob/main/portable_config/scripts/hdr-toys-helper.lua) can get it automatically from the mpv's video-out-params/sig-peak.

- SDR peak defaults to 203nit.  
  You can set it manually with `set glsl-shader-opts L_sdr=N`  
  In some grading workflows it is 100nit, if so you'll get a dim result, unfortunately you have to guess the value and set it manually.

- That the BT.2390 EETF designed for display transform,  
  To get the desired result, you need to set reference white to your monitor's peak white by `set glsl-shader-opts L_sdr=N`.  
  To adapt the black point, you need to set the contrast to your monitor's contrast by `set glsl-shader-opts CONTRAST_sdr=N`.

### Chroma correction

This is a part of tone mapping, also known as "highlights desaturate".  
You can set the intensity of it by `set glsl-shader-opts sigma=N`.

In real world, the brighter the color, the less saturated it becomes, and eventually it turns white.

| `sigma=0`                                                                                                       | `sigma=0.2`                                                                                                     | `sigma=1`                                                                                                       |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/216247628-8647c010-ff70-488c-bc40-1d57612d1d9f.png) | ![image](https://user-images.githubusercontent.com/50797982/216247654-fc3066a1-098b-4f81-b4c5-a9c8eb6720cd.png) | ![image](https://user-images.githubusercontent.com/50797982/216247675-71c50982-2061-49b1-93b7-87ebe85951d6.png) |

### Crosstalk

This is a part of tone mapping, the screenshot below will show you how it works.  
You can set the intensity of it by `set glsl-shader-opts alpha=N`.

It makes the color less chromatic when tone mapping and the lightness between colors more even.  
And for non-perceptual conversions (e.g. hejl2015) it brings achromatically highlights.

| without crosstalk_inverse                                                                                       | heatmap, Y, alpha=0                                                                                             | heatmap, Y, alpha=0.3                                                                                           | hejl2015, RGB, alpha=0                                                                                          | hejl2015, RGB, alpha=0.3                                                                                        |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/213441412-7f43f19c-afc3-4b31-8b5c-55c1ac064ff7.png) | ![image](https://user-images.githubusercontent.com/50797982/213441611-fd6e6afa-e39b-4a44-82da-45a667dfe88a.png) | ![image](https://user-images.githubusercontent.com/50797982/213441631-3f87b965-8206-4e91-a8dd-d867c07cbf0d.png) | ![image](https://user-images.githubusercontent.com/50797982/213442007-411fd942-c930-4629-8dc1-88da8705639e.png) | ![image](https://user-images.githubusercontent.com/50797982/213442036-45e0a832-7d14-40f5-b4ca-1320ad59358d.png) |

### Gamut mapping

`matrix` is the exact conversion.  
`compress` restores the excess color by reducing the distance of the achromatic axis.  
`warning` shows the excess color after conversion as inverse color.

| matrix                                                                                                          | compress                                                                                                        | warning                                                                                                         |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| ![image](https://user-images.githubusercontent.com/50797982/215457620-7920720a-c6a2-4f71-aa30-cc97bd8f03ea.png) | ![image](https://user-images.githubusercontent.com/50797982/215457533-802154a7-cfd0-442b-9882-35cce210308f.png) | ![image](https://user-images.githubusercontent.com/50797982/215457770-e1822c28-d1ac-4938-b3cc-48dcdee5738a.png) |
