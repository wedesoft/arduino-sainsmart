#ifndef __CALIBRATION_HH
#define __CALIBRATION_HH



// BASE, SHOULDER, ELBOW, ROLL, PITCH, WRIST, GRIPPER (defined in controllerbase.hh)
const int SERVOPIN[] = {0, 1, 2, 3, 4, 5};
const int OFFSET[] = {1471, 1465, 700, 1240, 1550, 1366};// normally around 1500 except for elbow and gripper

#warning "Adjust these values for your robot to avoid self-collisions!"
#warning "Control your robot carefully until you have inserted appropriate boundaries here!"
const int MIN[] = {544, 938, 638, 544, 544, 544};// must not be below 544
const int MAX[] = {2400, 2400, 2400, 2400, 2253, 2400};// must not be above 2400

const float RESOLUTION[] = {8.844444444444445, 8.844444444444445, 8.844444444444445, 8.844444444444445, 11.433333333333334, 10.133333333333333};
const float MAXJERK = 250;

#endif
