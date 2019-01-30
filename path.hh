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
  
  // "pos" func take no argument and yield the sum of "offset" with the "retval" value from "m_profile" object
  float pos(void) {
    return m_offset + m_profile[0].value(m_time[0]) + m_profile[1].value(m_time[1]);
  }
  
  // "update" func that returns float take a float argument & call "update" func that take 3 arguments below
  float update(float dt) {
    update(dt, m_time[0], m_profile[0]);
    update(dt, m_time[1], m_profile[1]);
    return pos(); // Return the float value from "pos(void)" func
  }
  
  // "update" func with no return type & take 3 arguments
  void update(float dt, float &time, Profile &profile) {
    time += dt;
    // Check "time" is larger or equals to the duration of profile object
    if (time >= profile.getDuration()) {
      m_offset += profile.getDistance(); // Sum all the distance from profile object
      profile.reset(); // Then give default value to profile object variables
    };
  }
  void stop(float pos) {
    m_offset = pos;
    m_profile[0].reset();
    m_profile[1].reset();
  }
  bool ready(void) {
    return m_profile[0].ifEmpty() || m_profile[1].ifEmpty();
  }
  void retarget(float target, float duration) {
    retarget(target, duration, m_time[0], m_profile[0]) || retarget(target, duration, m_time[1], m_profile[1]);
  }
  float target(void) {
    return m_offset + m_profile[0].getDistance() + m_profile[1].getDistance();
  }
  bool retarget(float value, float duration, float &time, Profile &profile) {
    if (!profile.ifEmpty())
      return false;
    else {
      time = 0;
      profile.reset(value - target(), duration);
      return true;
    };
  }
  float timeRemaining(float time, Profile &profile) {
    return profile.ifEmpty() ? 0 : profile.getDuration() - time;
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
