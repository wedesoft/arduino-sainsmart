#!/usr/bin/env ruby
require_relative '../joystick'
require_relative '../serial_client'
require_relative '../kinematics'


DEVICE = '/dev/ttyUSB0'
BAUD = 115200
joystick = Joystick.new
client = SerialClient.new DEVICE, BAUD
initial = Kinematics.forward Vector[0, 0, 0, 0, 0, 0]
t = Time.new.to_f
offset1 = 0
offset2 = 0
offset3 = 0
angle1 = 0
angle2 = 0
angle3 = 0
speed = 100
roll = 1
def adapt value
  if value >= 4000
    (value.to_f - 4000) / (32768 - 4000)
  elsif value <= -4000
    (value.to_f + 4000) / (32768 - 4000)
  else
    0
  end
end
while not joystick.button[2]
  joystick.update
  if joystick.button[0]
    change1 = 0
    change3 = 0
    change5 =  adapt(joystick.axis[1] || 0)
    change6 = -adapt(joystick.axis[0] || 0)
  else
    change1 =  adapt(joystick.axis[0] || 0)
    change3 = -adapt(joystick.axis[1] || 0)
    change5 = 0
    change6 = 0
  end
  change2 =  adapt(joystick.axis[4] || 0)
  change4 =  adapt(joystick.axis[3] || 0)
  dt = Time.new.to_f - t
  t += dt
  offset1 = offset1 + speed * change1 * dt
  offset2 = offset2 + speed * change2 * dt
  offset3 = offset3 + speed * change3 * dt
  angle1 = angle1 + roll * change4 * dt
  angle2 = angle2 + roll * change5 * dt
  angle3 = angle3 + roll * change6 * dt
  translate = Matrix[[1, 0, 0, offset1], [0, 1, 0, offset2], [0, 0, 1, offset3], [0, 0, 0, 1]]
  rotate = Matrix.rotate_y(angle3) * Matrix.rotate_x(angle2) * Matrix.rotate_z(angle1)
  target = Kinematics.inverse(initial * translate * rotate)
  target = target.collect { |x| x * 180 / Math::PI }
  if client.ready? and 2 * client.time_remaining <= client.time_required(*target)
    client.target *target
  end
end
