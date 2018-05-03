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
a(x):=2*sin(x)*cos(x)*jerk;
v(x):=jerk-jerk*cos(x)^2;
s(x):=jerk*x-(jerk*(sin(2*x)/2+x))/2;

s(x,l,d):=l*(x*2/d-sin(2*x*%pi/d)/(2*%pi)-x/d);
v(x,l,d):=l*(1/d-cos(2*%pi*x/d)/d);
a(x,l,d):=2*%pi*l*sin(2*%pi*x/d)/d^2;

a(d/4,l,d)=2*%pi*l/d^2=maxjerk;
d=sqrt(2*%pi*l/maxjerk);
```
