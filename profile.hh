#ifndef __PROFILE_HH
#define __PROFILE_HH

#include <math.h>

class Profile
{
public:
  Profile(void) { reset(); }
  Profile(float distance, float duration) {
    reset(distance, duration);
  }
  void reset(void) {
    m_distance = 0;
    m_duration = 0;
  }
  void reset(float distance, float duration) {
    m_distance = distance;
    m_duration = duration;
  };
  float distance(void) { return m_distance; }
  float duration(void) { return m_duration; }
  bool empty(void) { return m_duration == 0; }
  float value(float time) {
    float retval;
    if (time > 0)
      if (time < m_duration)
        retval = m_distance * (M_PI * time / m_duration - 0.5 * sin(2 * M_PI * time / m_duration)) / M_PI;
      else
        retval = m_distance;
    else
      retval = 0;
    return retval;
  }
  static float timeRequired(float distance, float maxJerk) {
    return cbrtf(4 * M_PI * M_PI * distance / maxJerk);
  }
protected:
  float m_distance;
  float m_duration;
};

#endif
