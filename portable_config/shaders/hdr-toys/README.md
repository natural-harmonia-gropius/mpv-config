# HDR-toys

## How to use this?

mpv.conf

```ini
[hdr]
profile-cond=get("video-params/sig-peak") > 1
profile-restore=copy
target-trc=pq
target-prim=bt.2020
glsl-shader=~~/shaders/hdr-toys/utils/clip_both.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/pq_to_l.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/l_to_linear.glsl
glsl-shader=~~/shaders/hdr-toys/utils/exposure.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk.glsl
glsl-shader=~~/shaders/hdr-toys/utils/chroma_correction.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt2446c.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk_inverse.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/bt2407_matrix.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
```

## 一些碎碎念

我理想的曲线

k1=0.009, k2=0.8 (大概，我猜的)

| part       | from                                      | to                 | curve    |
| ---------- | ----------------------------------------- | ------------------ | -------- |
| black      | [0.0, HDR_ref_black)                      | 0.0                |          |
| shadow     | [HDR_ref_black, SDR_ref_black + k1)       | [0.0, k1)          | ease in  |
| mid        | [SDR_ref_black + k1, SDR_ref_white \* k2] | [k1, k2)           | linear   |
| highlight  | [SDR_ref_white \* k2, HDR_ref_white)      | [k2, 1.0)          | ease out |
| white      | [HDR_ref_white]                           | [1.0]              |          |
| over-white | (HDR_ref_white, 1.0]                      | [saturated, white] | linear   |

**色度映射**  
现在通过降低 HSV.S 来实现，之后可能改成基于 JzCzHz.C 的。  
映射曲线是线性的。  
BT.2446 里给的 LCH 函数在经过五六轮往返转换后会出现可视的偏色。  
color.js 的 demo 里 LCH(150, 100, 0) 也不是白平衡的，很接近白，但并不是白，这点非常奇怪。

**色相映射**  
在亮度之外还有色域映射，这部分我希望能保持饱和度只校正色相。  
HSV 校正出来的结果很奇怪，之后看看 LCH、JzCzHz 表现如何。

ACES output transform 更适合调色，而非回放，对于已经经过良好调色的内容产生的结果（我认为）很糟糕。

## Thanks

<https://github.com/ampas/aces-dev>  
<https://github.com/tizian/tonemapper>
