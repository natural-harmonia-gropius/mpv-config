# HDR-toys

## How to use this?

mpv.conf

```ini
[hdr]
profile-cond=get("video-params/sig-peak") > 1
profile-restore=copy
target-trc=pq
target-prim=bt.2020
# glsl-shader=~~/shaders/BT2100PQ_to_BT709.glsl
glsl-shader=~~/shaders/hdr-toys/utils/clip_black.glsl
glsl-shader=~~/shaders/hdr-toys/PQ_to_Y.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt.2446c.glsl
glsl-shader=~~/shaders/hdr-toys/Y_to_CV.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/linear.glsl
glsl-shader=~~/shaders/hdr-toys/tone-mapping/reinhard.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/hable.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/aces.glsl
# glsl-shader=~~/shaders/hdr-toys/tone-mapping/bt.2446a.glsl
glsl-shader=~~/shaders/hdr-toys/gamut-mapping/bt.2407_matrix.glsl
glsl-shader=~~/shaders/hdr-toys/CV_to_BT1886.glsl
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
