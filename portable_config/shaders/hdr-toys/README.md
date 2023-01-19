# HDR-toys

## How to use this?

Put this auto-profile in your mpv.conf  
Default combination matches ITU-R BT.2446 Conversion Method C

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

Also mention that you can also use this to play with bt2020

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
| clip     | rgb        | SDR peak              |
| linear   | YRGB       | metadata              |

[^1]: test
