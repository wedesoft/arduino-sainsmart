require 'serialport'

class Client
  def initialize device, baud
    @serial = SerialPort.new device, baud
    @serial.read_timeout = 2000
  end

  def time_required value
    write_serial "#{value}t"
    read_serial.to_f
  end

  def time
    write_serial 't'
    read_serial.to_i * 0.001
  end

  def target *values
    write_serial "#{values.join " "}c"
  end

  def configuration str
    write_serial str
    read_serial.split(' ').collect &:to_f
  end

  def pos
    configuration 'c'
  end

  def lower
    configuration 'l'
  end

  def upper
    configuration 'u'
  end

  def ready?
    write_serial 'o'
    read_serial.to_i != 0
  end

  def teach_point_name index
    (index + 'a'.ord).chr
  end

  def save_teach_point index
    write_serial "m#{teach_point_name(index)}"
  end

  def load_teach_point index
    c = teach_point_name index
    configuration "'#{c}d#{c}"
  end

  def stop
    write_serial 'x'
  end

  def write_serial str
    @serial.write str
    @serial.flush
  end

  def read_serial
    result = @serial.readline
    result
  end
end

