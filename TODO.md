# TODO

* synchronous point-to-point for samples of cartesian path (fly-by-point)
* speed: sin^2 profile (sin^2+cos^2=1) with x in [0, pi] for interpolation (Klaus Wüst),
  acceleration is 2 cos(x) sin(x), position is 1/2 (x - 1/2 sin(2x))
* off-board path planning
* inverse kinematic
* serial control
* XBox controller (rotation- and translation mode), python-pygame
* audio output
* machine vision
* servos with feedback
* visualise nominal vs actual position
* instructions (screw terminal)

```
v(t, d, c) := c * sin(%pi * t / d) ^ 2;
plot2d(v(t, 10, 1), [t, 0, 10]);
s(t, d, c) := (c * d * (%pi * t / d - sin(2 * %pi * t / d) / 2)) / (2 * %pi);
plot2d(s(t, 10, 1), [t, 0, 10]);
solve(s(d, d, c) = l, c);

ss(t, d, l) := s(t, d, 2 * l / d);
ss(t, d, l) := l * (%pi * t / d - sin(2 * %pi * t / d) / 2) / %pi;
diff(ss(t, d, l), t);
vv(t, d, l) := l * (%pi / d - %pi * cos(2 * %pi * t / d) / d) / %pi;
diff(vv(t, d, l), t);
aa(t, d, l) := 2 * %pi * l * sin(2 * %pi * t / d) / d ^ 2;
diff(aa(t, d, l), t);
jj(t, d, l) := 4 * %pi ^ 2 * l * cos(2 * %pi * t / d) / d ^ 3;
solve(jj(0, d, l) = m, d);
d = (4 * %pi ^ 2 * l / m) ^ (1 / 3);
```
