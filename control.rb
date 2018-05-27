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

  def initialize translation_speed = 100, rotation_speed = 1, device = DEVICE, baud = BAUD
    @joystick = Joystick.new
    @serial_client = SerialClient.new device, baud
    @position = Vector[0, 0, 0, 0, 0, 0, 0]
    @neutral_pose = Kinematics.forward Vector[0, 0, 0, 0, 0, 0]
    @translation_speed = translation_speed
    @rotation_speed = rotation_speed
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
    Matrix.translation(*vector[0 ... 3]) *
      Matrix.rotate_y(vector[3]) *
      Matrix.rotate_x(vector[4]) *
      Matrix.rotate_z(vector[5])
  end

  def degrees vector
    vector.collect { |x| x * 180 / Math::PI }
  end

  def update elapsed = 1
    @joystick.update
    axis = @joystick.axis
    unless @joystick.button[0]
      x =  adapt(axis[0] || 0) * @translation_speed
      y =  adapt(axis[4] || 0) * @translation_speed
      z = -adapt(axis[1] || 0) * @translation_speed
      b = 0
      a = 0
      c =  adapt(axis[3] || 0) * @rotation_speed
    else
      x = 0
      y =  adapt(axis[4] || 0) * @translation_speed
      z = 0
      a = -adapt(axis[0] || 0) * @rotation_speed
      b =  adapt(axis[1] || 0) * @rotation_speed
      c =  adapt(axis[3] || 0) * @rotation_speed
    end
    gripper = (adapt(axis[5] || 0) - adapt(axis[2] || 0)) * @rotation_speed
    offset = Vector[x, y, z, a, b, c, gripper]
    @position += offset * elapsed
    pose_offset = pose_matrix @position
    solution = Kinematics.inverse(@neutral_pose * pose_offset)
    unless solution.nil?
      target = degrees solution.to_a + [@position[6]]
      if @serial_client.ready? and 2 * @serial_client.time_remaining <= @serial_client.time_required(*target)
        @serial_client.target *target
      end
    end
  end

  def quit?
    @joystick.button[2] || false
  end
end


if __FILE__ == $0
  control = Control.new
  time = Time.new.to_f
  while not control.quit?
    elapsed = Time.new.to_f - time
    control.update elapsed
    time += elapsed
  end
end
