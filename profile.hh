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
  
  // distance func take no argument & return m_distance as float of the object
  float getDistance(void) { return m_distance; }
  
  // duration func take no argument & return m_duration as float of the object
  float getDuration(void) { return m_duration; }
  
  // empty func take no argument & return if m_duration == 0 or not
  bool ifEmpty(void) { return m_duration == 0; }
  
  // value func take a float arugment "time"  
  float value(float time) { // The core func of this module calculating "time" with the object's fields - "m_distance" & "m_duration"
    float retval;
    if (time > 0) // If "time" is bigger than 0 then
      if (time < m_duration) // If "time" is smaller then 
        // ???
        retval = m_distance * (M_PI * time / m_duration - 0.5 * sin(2 * M_PI * time / m_duration)) / M_PI;
      else
        retval = m_distance; // IF "time" < 0 "retval" = "m_distance"
    else
      retval = 0;
    return retval;
  }
  // timeRequired func takes 2 float arguments: "distance" & " maxJerk"
  static float timeRequired(float distance, float maxJerk) {
    return cbrtf(4 * M_PI * M_PI * distance / maxJerk); // ???
  }
  
protected:
  float m_distance;
  float m_duration;
};

#endif
