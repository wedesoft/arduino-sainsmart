#include "../calibration.hh"
#include "../controllerbase.hh"
#include <Adafruit_PWMServoDriver.h>


// Humble Object connecting device to tested code http://xunitpatterns.com/Humble%20Object.html

class Controller: public ControllerBase
{
public:
  Controller(void) {}
	void setup(void) {
		m_servo.begin();
		m_servo.setPWMFreq(60);
	}	
  int offset(int drive) { return OFFSET[drive]; }
  float resolution(int drive) { return RESOLUTION[drive]; }
  int lower(int drive) { return MIN[drive]; }
  int upper(int drive) { return MAX[drive]; }
  void reportInteger(int value) {
    Serial.print(value);
    Serial.write("\r\n");
  }
  void reportFloat(float value) {
    Serial.print(value);
    Serial.write("\r\n");
  }
  void reportTime(void) {
    Serial.print(millis());
    Serial.write("\r\n");
  }
  void reportReady(bool ready) {
    reportInteger(ready ? 1 : 0);
  }
  void reportRequired(float time) {
    reportFloat(time);
  }
  void reportRemaining(float time) {
    reportFloat(time);
  }
  void reportAngle(float angle) {
    reportFloat(angle);
  }
  void reportPWM(int pwm) {
    reportInteger(pwm);
  }
  void reportConfiguration(float base, float shoulder, float elbow, float roll, float pitch, float wrist) {
    Serial.print(base);
    Serial.write(" ");
    Serial.print(shoulder);
    Serial.write(" ");
    Serial.print(elbow);
    Serial.write(" ");
    Serial.print(roll);
    Serial.write(" ");
    Serial.print(pitch);
    Serial.write(" ");
    Serial.print(wrist);
    Serial.write("\r\n");
  }
  void reportLower(float base, float shoulder, float elbow, float roll, float pitch, float wrist) {
    reportConfiguration(base, shoulder, elbow, roll, pitch, wrist);
  }
  void reportUpper(float base, float shoulder, float elbow, float roll, float pitch, float wrist) {
    reportConfiguration(base, shoulder, elbow, roll, pitch, wrist);
  }
  void reportTeachPoint(float base, float shoulder, float elbow, float roll, float pitch, float wrist) {
    reportConfiguration(base, shoulder, elbow, roll, pitch, wrist);
  }
  void writePWM(int drive, int pwm) {
		m_servo.setPWM(drive, 0, pwm); 	   
  }
protected:
  Adafruit_PWMServoDriver m_servo = Adafruit_PWMServoDriver();
};

unsigned long t0;

Controller controller;

void setup() {
  controller.setup();
  Serial.begin(115200);
  t0 = millis();
}

void loop() {
  int dt = millis() - t0;
  while (Serial.available())
    controller.parseChar(Serial.read());
  controller.update(dt * 0.001);
  t0 += dt;
}
