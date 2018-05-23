require_relative '../control'


describe Control do
  before :each do
    allow(Joystick).to receive :new
    allow(SerialClient).to receive :new
  end

  it 'should initialize the joystick' do
    expect(Joystick).to receive :new
    Control.new
  end

  it 'should initialize serial communication' do
    expect(SerialClient).to receive(:new).with '/dev/ttyUSB0', 115200
    Control.new '/dev/ttyUSB0', 115200
  end
end
