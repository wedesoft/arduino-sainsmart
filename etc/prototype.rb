#!/usr/bin/env ruby
require_relative '../joystick'
require_relative '../serial_client'
require_relative '../kinematics'


DEVICE = '/dev/ttyUSB0'
BAUD = 115200
joystick = JoyStick.new
client = SerialClient.new DEVICE, BAUD
initial = Kinematics.forward Vector[0, 0, 0, 0, 0, 0]
t = Time.new.to_f
offset1 = 0
offset2 = 0
offset3 = 0
speed = 100
def adapt value
  if value >= 4000
    (value.to_f - 4000) / (32768 - 4000)
  elsif value <= -4000
    (value.to_f + 4000) / (32768 - 4000)
  else
    0
  end
end
while not joystick.button[0]
  joystick.update
  change1 = -adapt(joystick.axis[1] || 0)
  change2 = -adapt(joystick.axis[0] || 0)
  change3 = -adapt(joystick.axis[4] || 0)
  dt = Time.new.to_f - t
  t += dt
  offset1 = offset1 + speed * change1 * dt
  offset2 = offset2 + speed * change2 * dt
  offset3 = offset3 + speed * change3 * dt
  diff = Matrix[[1, 0, 0, offset1], [0, 1, 0, offset2], [0, 0, 1, offset3], [0, 0, 0, 1]]
  target = Kinematics.inverse(diff * initial)
  target = target.collect { |x| x * 180 / Math::PI }
  if client.ready? and 2 * client.time_remaining <= client.time_required(*target)
    client.target *target
  end
end
