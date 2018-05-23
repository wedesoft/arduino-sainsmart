require 'sdl2'


class Joystick
  attr_reader :axis
  attr_reader :button

  def initialize
    SDL2.init SDL2::INIT_JOYSTICK
    @axis = {}
    @button = {}
  end

  def update
    while event = SDL2::Event.poll
      case event
      when SDL2::Event::JoyDeviceAdded
        @device = SDL2::Joystick.open event.which
      when SDL2::Event::JoyAxisMotion
        @axis[event.axis] = event.value
      when SDL2::Event::JoyButtonDown
        @button[event.button] = true
      when SDL2::Event::JoyButtonUp
        @button[event.button] = false
      end
    end
  end
end
