# HDR-toys

## How to use this?

Put this auto-profile in your `mpv.conf`.  
Default combination matches ITU-R BT.2446 Conversion Method C.

```ini
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
glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt2446c.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk_inverse.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/compress.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
```

Also mention that you can also use this to get better playback experience for BT.2020 content.

```ini
[bt.2020]
profile-cond=get("video-params/primaries") == "bt.2020" and get("video-params/sig-peak") == 1
profile-restore=copy
target-prim=bt.2020
glsl-shader=~~/shaders/hdr-toys/transfer-function/bt1886_to_linear.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/compress.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
```

## What are these? What are they for?

### Tone mapping operators

You can change the [tone mapping operator](https://github.com/Natural-Harmonia-Gropius/mpv_config/tree/main/portable_config/shaders/hdr-toys/tone-mapping) by replacing this line.  
For example, use reinhard instead of bt2446c.

```diff
-glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt2446c.glsl
+glsl-shader=~~/shaders/hdr-toys/tone-mapping/reinhard.glsl
```

This table lists the features of operators.

| Operator | Applied to | Conversion peak       |
| -------- | ---------- | --------------------- |
| bt2390   | Ictcp      | metadata[^1]          |
| bt2446a  | YCbCr      | metadata              |
| bt2446c  | xyY        | 1000nit (adjustable)  |
| reinhard | YRGB       | metadata              |
| hable    | YRGB       | metadata              |
| hable2   | YRGB       | metadata              |
| suzuki   | YRGB       | 10000nit (adjustable) |
| uchimura | YRGB       | 1000nit               |
| hejl2015 | RGB        | metadata              |
| lottes   | maxRGB     | metadata              |
|          |            |                       |
| heatmap  | (Various)  | 10000nit              |
| clip     | RGB        | SDR peak[^2]          |
| linear   | YRGB       | metadata              |

[^1]:
    Default to 1000nit.  
    [hdr-toys-helper.lua](https://github.com/Natural-Harmonia-Gropius/mpv_config/blob/main/portable_config/scripts/hdr-toys-helper.lua) can get it automatically from the video's metadata.  
    You can also set it manually like this `set glsl-shader-opts L_hdr=1000`

[^2]:
    Default to 203nit.
    You can also set it manually like this `set glsl-shader-opts L_sdr=203`

### WIP
