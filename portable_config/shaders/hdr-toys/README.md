# HDR-toys

## How to use this?

mpv.conf

```ini
[hdr]
profile-cond=get("video-params/sig-peak") > 1
profile-restore=copy
target-trc=pq
target-prim=bt.2020
glsl-shader=~~/shaders/hdr-toys/utils/clip_black.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/pq_to_l.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/l_to_linear.glsl
glsl-shader=~~/shaders/hdr-toys/utils/exposure.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk.glsl
glsl-shader=~~/shaders/hdr-toys/utils/chroma_correction_hsv.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/piecewise.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk_inverse.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/bt.2407_matrix.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
```

## How to handle very bright images?

- Metering -> Auto Exposure
- Histogram -> Dynamic Tonemapping Curve
- Blend between Bilateral and Gaussian -> Local Tonemapping
- Exposure Bracketing -> Exposure Fusion
