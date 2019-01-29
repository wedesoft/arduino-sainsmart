#ifndef __PATH_HH
#define __PATH_HH

#include "profile.hh"

class Path
{
// All the "Path" public methods 
public:
  // Constructor take no argument that set initialize the default value to instance variables
  Path(void): m_offset(0) {
    m_time[0] = 0;
    m_time[1] = 0;
  }
  
  // "pos" func take no argument and yield the sum of "offset" with the "retval" value from "rofile" class
  float pos(void) {
    return m_offset + m_profile[0].value(m_time[0]) + m_profile[1].value(m_time[1]);
  }
  float update(float dt) {
    update(dt, m_time[0], m_profile[0]);
    update(dt, m_time[1], m_profile[1]);
    return pos();
  }
  void update(float dt, float &time, Profile &profile) {
    time += dt;
    if (time >= profile.duration()) {
      m_offset += profile.distance();
      profile.reset();
    };
  }
  void stop(float pos) {
    m_offset = pos;
    m_profile[0].reset();
    m_profile[1].reset();
  }
  bool ready(void) {
    return m_profile[0].empty() || m_profile[1].empty();
  }
  void retarget(float target, float duration) {
    retarget(target, duration, m_time[0], m_profile[0]) || retarget(target, duration, m_time[1], m_profile[1]);
  }
  float target(void) {
    return m_offset + m_profile[0].distance() + m_profile[1].distance();
  }
  bool retarget(float value, float duration, float &time, Profile &profile) {
    if (!profile.empty())
      return false;
    else {
      time = 0;
      profile.reset(value - target(), duration);
      return true;
    };
  }
  float timeRemaining(float time, Profile &profile) {
    return profile.empty() ? 0 : profile.duration() - time;
  }
  float timeRemaining(void) {
    float a = timeRemaining(m_time[0], m_profile[0]);
    float b = timeRemaining(m_time[1], m_profile[1]);
    return a >= b ? a : b;
  }
  
// All the protected attributes of "Path" class
protected:
  Profile m_profile[2]; // "Profile" objects
  float m_time[2];
  float m_offset;
};

#endif
