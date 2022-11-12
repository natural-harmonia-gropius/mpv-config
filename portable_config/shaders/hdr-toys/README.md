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
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/piecewise.glsl
glsl-shader=~~/shaders/hdr-toys/utils/crosstalk_inverse.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/bt.2407_matrix.glsl
glsl-shader=~~/shaders/hdr-toys/transfer-function/linear_to_bt1886.glsl
```

## Roadmap

Tone Mapping

- [x] Linear
- [x] Reinhard
- [x] Hable
- [ ] BT.2446 Method A
- [ ] BT.2446 Method C
- [ ] BT.2390

Gamut Mapping

- [x] BT.2407 Matrix
- [ ] BT.2407 Annex 1
- [ ] BT.2407 Annex 2
- [ ] BT.2407 Annex 3
- [ ] BT.2407 Annex 4
- [ ] BT.2407 Annex 5
- [ ] BT.2407 Annex 6

Overkill

- [ ] ACES Output Transform
