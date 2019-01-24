#ifndef __CONTROLLER_HH
#define __CONTROLLER_HH

#include "calibration.hh"
#include "path.hh"

const int BASE     = 0;
const int SHOULDER = 1;
const int ELBOW    = 2;
const int ROLL     = 3;
const int PITCH    = 4;
const int WRIST    = 5;
const int DRIVES   = 6;

const float ELBOW_RANGE = 60;

class ControllerBase
{
public:
  ControllerBase(void): m_number(0), m_fraction(0), m_sign(0), m_teachFun(NULL), m_index(0) {
    memset(m_teach, 0, sizeof(m_teach));
    memset(m_configuration, 0, sizeof(m_configuration));
  }

  virtual ~ControllerBase() {}

  Path &curve(int drive) { return m_curve[drive]; }

  int drive(char c) {
    switch (tolower(c)) {
    case 's':
      return SHOULDER;
    case 'e':
      return ELBOW;
    case 'r':
      return ROLL;
    case 'p':
      return PITCH;
    case 'w':
      return WRIST;
    default:
      return BASE;
    };
  }

  float target(int drive) {
    return m_curve[drive].target();
  }

  float limit(float value, float lower, float upper) {
    return value < lower ? lower : value > upper ? upper : value;
  }

  float angleToPWM(int drive, float angle) {
    return offset(drive) + angle * resolution(drive);
  }

  float pwmToAngle(int drive, float pwm) {
    return (pwm - offset(drive)) / resolution(drive);
  }

  float clipPWM(int drive, float value) {
    return limit(value, lower(drive), upper(drive));
  }

  float clipAngle(int drive, float value) {
    return pwmToAngle(drive, clipPWM(drive, angleToPWM(drive, value)));
  }

  float limitJoint(float value, float other) {
    return limit(value, -ELBOW_RANGE - other, ELBOW_RANGE - other);
  }

  float limitArmAngle(int drive, float value)
  {
    switch (drive) {
    case ELBOW:
      return limitJoint(value, target(SHOULDER));
    case SHOULDER:
      return limitJoint(value, target(ELBOW));
    default:
      return value;
    };
  }

  void saveTeachPoint(int index) {
    for (int i=0; i<DRIVES; i++)
      m_teach[index][i] = target(i);
  }

  void loadTeachPoint(int index) {
    targetPoint(m_teach[index]);
  }

  void displayTeachPoint(int index) {
    reportTeachPoint(m_teach[index][0], m_teach[index][1], m_teach[index][2],
                     m_teach[index][3], m_teach[index][4], m_teach[index][5]);
  }

  void takeConfigurationValue(void) {
    if (m_index < DRIVES) {
      float angle = clipAngle(m_index, number());
      m_configuration[m_index] = angle;
      m_index++;
    };
    resetNumber();
  }

  float timeRequired(int drive, float angle) {
    return Profile::timeRequired(fabs(angle - target(drive)), MAXJERK);
  }

  float timeRequired(float point[]) {
    float retval = 0;
    for (int i=0; i<DRIVES; i++) {
      float driveTime = timeRequired(i, point[i]);
      retval = retval < driveTime ? driveTime : retval;
    };
    return retval;
  }

  void targetAngleUnsafe(int drive, float angle, float time) {
    m_curve[drive].retarget(angle, time);
  }

  void targetPWM(int drive, float pwm) {
    float angle = limitArmAngle(drive, pwmToAngle(drive, clipPWM(drive, pwm)));
    targetAngleUnsafe(drive, angle, timeRequired(drive, angle));
  }

  void targetAngle(int drive, float value) {
    float angle = limitArmAngle(drive, clipAngle(drive, value));
    targetAngleUnsafe(drive, angle, timeRequired(drive, angle));
  }

  void targetPoint(float point[])
  {
    float time = timeRequired(point);
    for (int i=0; i<DRIVES; i++)
      targetAngleUnsafe(i, i == ELBOW ? limitArmAngle(ELBOW, point[i]) : point[i], time);
  }

  void update(float dt) {
    for (int drive=0; drive<DRIVES; drive++)
      writePWM(drive, round(angleToPWM(drive, m_curve[drive].update(dt))));
  }

  void stopDrives(void) {
    resetParser();
    for (int drive=0; drive<DRIVES; drive++)
      m_curve[drive].stop(m_curve[drive].pos());
  }

  bool hasNumber(void) {
    return m_sign != 0;
  }

  float number(void) {
    float fraction = (m_fraction == 0) ? 1 : m_fraction;
    return m_number * fraction * m_sign;
  }

  void resetNumber(void) {
    m_number = 0;
    m_fraction = 0;
    m_sign = 0;
  }

  void resetParser(void) {
    resetNumber();
    memset(m_configuration, 0, sizeof(m_configuration));
    m_index = 0;
  }

  bool drivesReady(void) {
    bool retval = true;
    for (int i=0; i<DRIVES; i++)
      retval = retval && m_curve[i].ready();
    return retval;
  }

  void parseChar(char c) {
    if (m_teachFun) {
      if (c >= 'a' && c <= 'l')
        (this->*m_teachFun)(c - 'a');
      else
        stopDrives();
      resetParser();
      m_teachFun = NULL;
    } else {
      switch (c) {
      case 'o':
        reportReady(drivesReady());
        resetParser();
        break;
      case 't':
        if (hasNumber()) {
          takeConfigurationValue();
          reportRequired(timeRequired(m_configuration));
        } else
          reportTime();
        resetParser();
        break;
      case 'T':
        reportRemaining(m_curve[BASE].timeRemaining());
        resetParser();
        break;
      case '.':
        if (m_fraction > 0)
          resetParser();
        else
          m_fraction = 1;
        break;
      case '-':
        m_sign = m_sign == 0 ? -1 : -m_sign;
        m_number = 0;
        m_fraction = 0;
        break;
      case 'b':
      case 'B':
      case 'e':
      case 'E':
      case 's':
      case 'S':
      case 'r':
      case 'R':
      case 'p':
      case 'P':
      case 'w':
      case 'W':
        if (hasNumber()) {
          if (isupper(c))
            targetPWM(drive(c), number());
          else
            targetAngle(drive(c), number());
        } else
          if (isupper(c))
            reportPWM(round(angleToPWM(drive(c), m_curve[drive(c)].pos())));
          else
            reportAngle(m_curve[drive(c)].pos());
        resetParser();
        break;
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        m_number = 10 * m_number + (c - '0');
        m_fraction *= 0.1;
        if (m_sign == 0) m_sign = 1;
        break;
      case '\'':
        m_teachFun = &ControllerBase::loadTeachPoint;
        break;
      case 'm':
        m_teachFun = &ControllerBase::saveTeachPoint;
        break;
      case 'd':
        m_teachFun = &ControllerBase::displayTeachPoint;
        break;
      case ' ':
        takeConfigurationValue();
        break;
      case 'c':
        if (hasNumber()) {
          takeConfigurationValue();
          targetPoint(m_configuration);
        } else
          reportConfiguration(m_curve[0].pos(), m_curve[1].pos(), m_curve[2].pos(),
                              m_curve[3].pos(), m_curve[4].pos(), m_curve[5].pos());
        resetParser();
        break;
      case 'l':
        reportLower((lower(0) - offset(0)) / resolution(0),
                    (lower(1) - offset(1)) / resolution(1),
                    (lower(2) - offset(2)) / resolution(2),
                    (lower(3) - offset(3)) / resolution(3),
                    (lower(4) - offset(4)) / resolution(4),
                    (lower(5) - offset(5)) / resolution(5));
        resetParser();
        break;
      case 'u':
        reportUpper((upper(0) - offset(0)) / resolution(0),
                    (upper(1) - offset(1)) / resolution(1),
                    (upper(2) - offset(2)) / resolution(2),
                    (upper(3) - offset(3)) / resolution(3),
                    (upper(4) - offset(4)) / resolution(4),
                    (upper(5) - offset(5)) / resolution(5));
        resetParser();
        break;
      default:
        stopDrives();
      };
    };
  }

  virtual int offset(int drive) = 0;
  virtual float resolution(int drive) = 0;
  virtual int lower(int drive) = 0;
  virtual int upper(int drive) = 0;
  virtual void reportReady(bool ready) = 0;
  virtual void reportTime(void) = 0;
  virtual void reportRequired(float time) = 0;
  virtual void reportRemaining(float time) = 0;
  virtual void reportAngle(float) = 0;
  virtual void reportPWM(int) = 0;
  virtual void reportConfiguration(float, float, float, float, float, float) = 0;
  virtual void reportLower(float, float, float, float, float, float) = 0;
  virtual void reportUpper(float, float, float, float, float, float) = 0;
  virtual void reportTeachPoint(float, float, float, float, float, float) = 0;
  virtual void writePWM(int, int) = 0;

protected:
  float m_number;
  float m_fraction;
  char m_sign;
  void (ControllerBase::*m_teachFun)(int);
  float m_teach[12][DRIVES];
  int m_index;
  float m_configuration[DRIVES];
  Path m_curve[DRIVES];
};

#endif
