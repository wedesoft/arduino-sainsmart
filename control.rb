require_relative 'joystick'
require_relative 'serial_client'


class Control
  DEVICE = '/dev/ttyUSB0'
  BAUD = 115200
  def initialize device = DEVICE, baud = BAUD
    @joystick = Joystick.new
    @serial_client = SerialClient.new device, baud
  end
end
