var o = {
  temporal_stable_time: 1 / 3,
};

var current = {
  temporal_stable_frames: 8,
};

function set_temporal_stable_frames(x) {
  x = x * o.temporal_stable_time;
  x = Math.round(x);
  x = Math.min(Math.max(x, 0), 120);

  mp.command("no-osd set glsl-shader-opts temporal_stable_frames=" + x);
  current.temporal_stable_frames = x;
}

mp.observe_property("container-fps", "native", function (property, value) {
  if (!value) return;
  set_temporal_stable_frames(value);
});
