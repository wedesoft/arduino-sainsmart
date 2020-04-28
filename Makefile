ARDUINO_DIR = /usr/share/arduino
ARDMK_DIR = /usr/share/arduino
BOARD_TAG = uno

ARDUINO_PORT = /dev/ttyACM*
ARDUINO_LIBS = Adafruit_PWMServoDriver Wire
SCREEN = screen

include $(ARDMK_DIR)/Arduino.mk

$(OBJDIR)/sainsmart.o: profile.hh path.hh controllerbase.hh calibration.hh

repl:
	$(SCREEN) $(ARDUINO_PORT) 115200
