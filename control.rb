#!/usr/bin/env ruby
require_relative 'matrix_ext'
require_relative 'joystick'
require_relative 'serial_client'
require_relative 'kinematics'


class Control
  DEVICE = '/dev/ttyUSB0'
  BAUD = 115200
  DEADZONE = 4000.0

  attr_reader :position

  def initialize device = DEVICE, baud = BAUD
    @joystick = Joystick.new
    @serial_client = SerialClient.new device, baud
    @position = Vector[0, 0, 0]
    @neutral_pose = Kinematics.forward Vector[0, 0, 0, 0, 0, 0]
  end

  def adapt value
    if value > DEADZONE
      (value - DEADZONE) / (32768 - DEADZONE)
    elsif value < -DEADZONE
      (value + DEADZONE) / (32768 - DEADZONE)
    else
      0
    end
  end

  def pose_matrix vector
    x, y, z = *vector
    Matrix[[1, 0, 0, x], [0, 1, 0, y], [0, 0, 1, z], [0, 0, 0, 1]]
  end

  def update
    @joystick.update
    axis = @joystick.axis
    offset = Vector[adapt(axis[0] || 0), adapt(axis[4] || 0), -adapt(axis[1] || 0)]
    @position += offset
    pose_offset = pose_matrix @position
    target = Kinematics.inverse @neutral_pose * pose_offset
    # target = target.collect { |x| x * 180 / Math::PI } TODO
    if @serial_client.ready? and 2 * @serial_client.time_remaining <= @serial_client.time_required(*target)
      @serial_client.target *target
    end
  end

  def quit?
    @joystick.button[0] || false
  end
end


if __FILE__ == $0
  control = Control.new
  while not control.quit?
    control.update
  end
end
