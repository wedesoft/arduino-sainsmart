#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "controllerbase.hh"
#include "profile.hh"
#include "path.hh"

using namespace testing;

TEST(ProfileTest, DefaultProfile)
{
  EXPECT_EQ(0, Profile().value(-1));
  EXPECT_EQ(0, Profile().value( 0));
  EXPECT_EQ(0, Profile().value( 1));
}

TEST(ProfileTest, StartWithZero)
{
  EXPECT_NEAR(0, Profile(1, 10).value(0.001), 0.01);
}

TEST(ProfileTest, EmptyOrNot)
{
  ASSERT_TRUE(Profile().empty());
  ASSERT_FALSE(Profile(1, 10).empty());
}

TEST(ProfileTest, EndWithDistance)
{
  EXPECT_NEAR(1, Profile(1, 10).value(9.999), 0.001);
  EXPECT_NEAR(2, Profile(2, 10).value(9.999), 0.001);
}

TEST(ProfileTest, PassesMiddle)
{
  EXPECT_NEAR(0.5, Profile(1, 10).value(5), 0.001);
}

TEST(ProfileTest, DistanceCubicWithDuration)
{
  EXPECT_NEAR(2 * Profile::timeRequired(1, 0.01), Profile::timeRequired(8, 0.01), 0.001);
}

TEST(ProfileTest, DistanceCubicWithMaxJerk)
{
  EXPECT_NEAR(2 * Profile::timeRequired(1, 0.08), Profile::timeRequired(1, 0.01), 0.001);
}

TEST(ProfileTest, TestTimeRequiredPoint)
{
  EXPECT_NEAR(2, Profile::timeRequired(200, 314), 2.001);
}

TEST(ProfileTest, Accelerates)
{
  EXPECT_GT(0.2, Profile(1, 4).value(1));
}

TEST(ProfileTest, StartAndEndStationary)
{
  EXPECT_FLOAT_EQ(  0, Profile(123, 10).value(-1));
  EXPECT_FLOAT_EQ(123, Profile(123, 10).value(11));
}

class PathTest: public Test {
protected:
  Path m_path;
};

TEST_F(PathTest, StartWithZero)
{
  EXPECT_EQ(0, m_path.pos());
}

TEST_F(PathTest, StayConstantOverTime)
{
  m_path.update(5);
  EXPECT_EQ(0, m_path.pos());
}

TEST_F(PathTest, StopSetsValue)
{
  m_path.stop(100);
  EXPECT_EQ(100, m_path.pos());
}

TEST_F(PathTest, ApproachTarget)
{
  m_path.stop(100);
  m_path.retarget(200, 1);
  m_path.update(0.5);
  EXPECT_NEAR(150, m_path.pos(), 0.001);
  m_path.update(0.5);
  EXPECT_NEAR(200, m_path.pos(), 0.001);
}

TEST_F(PathTest, UseSpecifiedDuration)
{
  m_path.stop(100);
  m_path.retarget(200, 2);
  m_path.update(1);
  EXPECT_NEAR(150, m_path.pos(), 0.001);
  m_path.update(1);
  EXPECT_NEAR(200, m_path.pos(), 0.001);
}

TEST_F(PathTest, UpdateReturnsPosition)
{
  m_path.stop(100);
  m_path.retarget(200, 2);
  EXPECT_NEAR(150, m_path.update(1), 0.001);
  EXPECT_NEAR(200, m_path.update(1), 0.001);
}

TEST_F(PathTest, AbortMotion) {
  m_path.stop(100);
  m_path.retarget(200, 2);
  m_path.update(1);
  m_path.stop(m_path.pos());
  m_path.update(1);
  EXPECT_NEAR(150, m_path.pos(), 0.001);
}

TEST_F(PathTest, ModifyTarget) {
  m_path.stop(100);
  m_path.retarget(200, 2);
  m_path.update(1);
  m_path.retarget(300, 2);
  EXPECT_NEAR(150, m_path.pos(), 0.001);
  m_path.update(1);
  EXPECT_NEAR(250, m_path.pos(), 0.001);
  m_path.update(1);
  EXPECT_NEAR(300, m_path.pos(), 0.001);
}

TEST_F(PathTest, IgnoreThirdTarget) {
  m_path.retarget(1, 1);
  m_path.retarget(2, 1);
  m_path.retarget(4, 1);
  m_path.update(1);
  EXPECT_FLOAT_EQ(2, m_path.pos());
}

TEST_F(PathTest, MakeFirstProfileAvailableWhenFinished) {
  m_path.retarget(1, 1);
  m_path.retarget(2, 2);
  m_path.update(1);
  m_path.retarget(4, 1);
  m_path.update(1);
  EXPECT_FLOAT_EQ(4, m_path.pos());
}

TEST_F(PathTest, MakeSecondProfileAvailableWhenFinished) {
  m_path.retarget(1, 2);
  m_path.retarget(2, 1);
  m_path.update(1);
  m_path.retarget(4, 1);
  m_path.update(1);
  EXPECT_FLOAT_EQ(4, m_path.pos());
}

TEST_F(PathTest, QueryTarget) {
  m_path.stop(100);
  EXPECT_FLOAT_EQ(100, m_path.target());
  m_path.retarget(200, 2);
  m_path.update(1);
  EXPECT_FLOAT_EQ(200, m_path.target());
  m_path.retarget(300, 2);
  m_path.update(1);
  EXPECT_FLOAT_EQ(300, m_path.target());
}

TEST_F(PathTest, QueryTimeRequired) {
  m_path.stop(100);
  EXPECT_FLOAT_EQ(0, m_path.timeRemaining());
  m_path.retarget(200, 3);
  EXPECT_FLOAT_EQ(3, m_path.timeRemaining());
  m_path.update(1);
  EXPECT_FLOAT_EQ(2, m_path.timeRemaining());
  m_path.retarget(300, 3);
  EXPECT_FLOAT_EQ(3, m_path.timeRemaining());
  m_path.update(4);
  EXPECT_FLOAT_EQ(0, m_path.timeRemaining());
}

TEST_F(PathTest, ReadyCheck) {
  EXPECT_TRUE(m_path.ready());
  m_path.retarget(100, 1);
  EXPECT_TRUE(m_path.ready());
  m_path.retarget(200, 3);
  EXPECT_FALSE(m_path.ready());
  m_path.update(2);
  EXPECT_TRUE(m_path.ready());
}

class MockController: public ControllerBase
{
public:
  int offset(int drive) { return 1500; }
  float resolution(int drive) { return 12.0; }
  int lower(int drive) { return 544; }
  int upper(int drive) { return 2400; }
  MOCK_METHOD1(reportReady, void(bool));
  MOCK_METHOD0(reportTime, void());
  MOCK_METHOD1(reportRequired, void(float));
  MOCK_METHOD1(reportAngle, void(float));
  MOCK_METHOD1(reportPWM, void(int));
  MOCK_METHOD2(writePWM, void(int,int));
  MOCK_METHOD7(reportConfiguration, void(float,float,float,float,float,float, float));
  MOCK_METHOD7(reportLower, void(float,float,float,float,float,float, float));
  MOCK_METHOD7(reportUpper, void(float,float,float,float,float,float, float));
  MOCK_METHOD7(reportTeachPoint, void(float,float,float,float,float,float, float));
};

class ControllerTest: public Test {
public:
  ControllerTest(void) {
    m_controller.curve(BASE    ).stop( 45);
    m_controller.curve(SHOULDER).stop(-10);
    m_controller.curve(ELBOW   ).stop( 20);
    m_controller.curve(ROLL    ).stop( 30);
    m_controller.curve(PITCH   ).stop( 15);
    m_controller.curve(WRIST   ).stop(-20);
    m_controller.curve(GRIPPER ).stop( 70);
  }
protected:
  void send(const char *str) {
    while (*str)
      m_controller.parseChar(*str++);
  };
  MockController m_controller;
};

TEST_F(ControllerTest, CheckTime) {
  EXPECT_CALL(m_controller, reportTime());
  send("t");
}

TEST_F(ControllerTest, ReportBase) {
  EXPECT_CALL(m_controller, reportAngle(45));
  send("b");
}

TEST_F(ControllerTest, ReportBasePWM) {
  EXPECT_CALL(m_controller, reportPWM(2040));
  send("B");
}

TEST_F(ControllerTest, ClipAcceptsValues) {
  EXPECT_EQ(1500, m_controller.clipPWM(BASE, 1500));
}

TEST_F(ControllerTest, ClipLowerBound) {
  EXPECT_EQ(544, m_controller.clipPWM(BASE, 500));
}

TEST_F(ControllerTest, ClipUpperBound) {
  EXPECT_EQ(2400, m_controller.clipPWM(BASE, 2500));
}

TEST_F(ControllerTest, ConvertZeroAngleToPWM) {
  EXPECT_EQ(1500, m_controller.angleToPWM(SHOULDER, 0));
}

TEST_F(ControllerTest, ConvertAngleToPWM) {
  EXPECT_EQ(1740, m_controller.angleToPWM(SHOULDER, 20));
}

TEST_F(ControllerTest, ConvertCenterPWMToAngle) {
  EXPECT_EQ(0, m_controller.pwmToAngle(BASE, 1500));
}

TEST_F(ControllerTest, ConvertPWMToAngle) {
  EXPECT_EQ(20, m_controller.pwmToAngle(BASE, 1740));
}

TEST_F(ControllerTest, TargetBaseAngle) {
  send("12b");
  EXPECT_EQ(12, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, TargetBasePWM) {
  send("1320B");
  EXPECT_EQ(-15.0, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, RetargetBaseFloat) {
  send("12.5b");
  EXPECT_EQ(12.5, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, TargetBasePWMFloat) {
  send("1501.5B");
  EXPECT_EQ(0.125, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, TargetBasePWMLowerLimit) {
  send("0B");
  EXPECT_LT(-80, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, TargetShoulderPWMLimitAgainstElbow) {
  send("2400S");
  EXPECT_GE(40, m_controller.curve(SHOULDER).target());
}

TEST_F(ControllerTest, RetargetNegativeNumber) {
  send("-1.5b");
  EXPECT_EQ(-1.5, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, DoubleMinus) {
  send("--1b");
  EXPECT_EQ(1, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, MinusClearsNumber) {
  send(".5-3b");
  EXPECT_EQ(-3, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, RetargetZero) {
  send("0b");
  EXPECT_EQ(0, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, TargetTwice) {
  send("3b3b");
  EXPECT_EQ(3, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, IgnoreInvalidFloat) {
  send("3.4.5b");
  EXPECT_EQ(5, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, AbortRetargetBase) {
  EXPECT_CALL(m_controller, reportAngle(45));
  send("5xb");
  EXPECT_EQ(45, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, CorrectTarget) {
  send("5x3b");
  EXPECT_EQ(3, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, RetargetBaseOnce) {
  EXPECT_CALL(m_controller, reportAngle(45));
  send("30bb");
  EXPECT_EQ(30, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, ReportElbow) {
  EXPECT_CALL(m_controller, reportAngle(20));
  send("e");
}

TEST_F(ControllerTest, ReportElbowPWM) {
  EXPECT_CALL(m_controller, reportPWM(1740));
  send("E");
}

TEST_F(ControllerTest, RetargetElbow) {
  send("10e");
  EXPECT_EQ(10, m_controller.curve(ELBOW).target());
}

TEST_F(ControllerTest, ReportShoulder) {
  EXPECT_CALL(m_controller, reportAngle(-10));
  send("s");
}

TEST_F(ControllerTest, ReportShoulderPWM) {
  EXPECT_CALL(m_controller, reportPWM(1380));
  send("S");
}

TEST_F(ControllerTest, ReportRoll) {
  EXPECT_CALL(m_controller, reportAngle(30));
  send("r");
}

TEST_F(ControllerTest, ReportRollPWM) {
  EXPECT_CALL(m_controller, reportPWM(1860));
  send("R");
}

TEST_F(ControllerTest, ReportPitch) {
  EXPECT_CALL(m_controller, reportAngle(15));
  send("p");
}

TEST_F(ControllerTest, ReportPitchPWM) {
  EXPECT_CALL(m_controller, reportPWM(1680));
  send("P");
}

TEST_F(ControllerTest, ReportWrist) {
  EXPECT_CALL(m_controller, reportAngle(-20));
  send("w");
}

TEST_F(ControllerTest, ReportWristPWM) {
  EXPECT_CALL(m_controller, reportPWM(1260));
  send("W");
}

TEST_F(ControllerTest, ReportGripper) {
  EXPECT_CALL(m_controller, reportAngle(70));
  send("g");
}

TEST_F(ControllerTest, ReportGripperPWM) {
  EXPECT_CALL(m_controller, reportPWM(2340));
  send("G");
}

TEST_F(ControllerTest, UseBase) {
  EXPECT_EQ(-90, m_controller.limitArmAngle(BASE, -90));
  EXPECT_EQ( 90, m_controller.limitArmAngle(BASE,  90));
}

TEST_F(ControllerTest, RestrictElbow) {
  m_controller.curve(SHOULDER).stop(0);
  EXPECT_EQ( 60, m_controller.limitArmAngle(ELBOW,  70));
  EXPECT_EQ(-60, m_controller.limitArmAngle(ELBOW, -70));
}

TEST_F(ControllerTest, RestrictElbowRelativeToShoulder) {

  EXPECT_EQ( 70, m_controller.limitArmAngle(ELBOW, 90));
  EXPECT_EQ(-50, m_controller.limitArmAngle(ELBOW,-90));
}

TEST_F(ControllerTest, UseElbowRestriction) {
  send("90e");
  EXPECT_EQ(70, m_controller.curve(ELBOW).target());
}

TEST_F(ControllerTest, RestrictShoulder) {
  m_controller.curve(ELBOW).stop(0);
  EXPECT_EQ( 60, m_controller.limitArmAngle(SHOULDER, 70));
  EXPECT_EQ(-60, m_controller.limitArmAngle(SHOULDER,-70));
}

TEST_F(ControllerTest, RestrictShoulderRelativeToElbow) {
  m_controller.curve(ELBOW).stop(-20);
  EXPECT_EQ( 80, m_controller.limitArmAngle(SHOULDER, 90));
  EXPECT_EQ(-40, m_controller.limitArmAngle(SHOULDER,-90));
}

TEST_F(ControllerTest, UpdateInformsServos) {
  m_controller.targetAngle(BASE, 0);
  EXPECT_CALL(m_controller, writePWM(BASE    , 2040));
  EXPECT_CALL(m_controller, writePWM(SHOULDER, 1380));
  EXPECT_CALL(m_controller, writePWM(ELBOW   , 1740));
  EXPECT_CALL(m_controller, writePWM(ROLL    , 1860));
  EXPECT_CALL(m_controller, writePWM(PITCH   , 1680));
  EXPECT_CALL(m_controller, writePWM(WRIST   , 1260));
  EXPECT_CALL(m_controller, writePWM(GRIPPER , 2340));
  m_controller.update(0);
}

TEST_F(ControllerTest, UpdateAppliesTargets) {
  m_controller.targetAngle(BASE, 0);
  EXPECT_CALL(m_controller, writePWM(BASE    , 1500));
  EXPECT_CALL(m_controller, writePWM(SHOULDER, 1380));
  EXPECT_CALL(m_controller, writePWM(ELBOW   , 1740));
  EXPECT_CALL(m_controller, writePWM(ROLL    , 1860));
  EXPECT_CALL(m_controller, writePWM(PITCH   , 1680));
  EXPECT_CALL(m_controller, writePWM(WRIST   , 1260));
  EXPECT_CALL(m_controller, writePWM(GRIPPER , 2340));
  m_controller.update(10);
}

TEST_F(ControllerTest, StopDrives) {
  for (int i=0; i<DRIVES; i++)
    m_controller.targetAngle(i, 0);
  EXPECT_CALL(m_controller, writePWM(BASE    , 2040));
  EXPECT_CALL(m_controller, writePWM(SHOULDER, 1380));
  EXPECT_CALL(m_controller, writePWM(ELBOW   , 1740));
  EXPECT_CALL(m_controller, writePWM(ROLL    , 1860));
  EXPECT_CALL(m_controller, writePWM(PITCH   , 1680));
  EXPECT_CALL(m_controller, writePWM(WRIST   , 1260));
  EXPECT_CALL(m_controller, writePWM(GRIPPER , 2340));
  send("x");
  m_controller.update(10);
}

TEST_F(ControllerTest, AdaptDuration) {
  m_controller.targetAngle(BASE, -35);
  m_controller.targetAngle(SHOULDER, 0);
  EXPECT_NEAR(m_controller.curve(BASE).timeRemaining(), 2 * m_controller.curve(SHOULDER).timeRemaining(), 0.001);
}

TEST_F(ControllerTest, ApproachTeachPoint) {
  send("'b");
  EXPECT_CALL(m_controller, writePWM(BASE    , 1500));
  EXPECT_CALL(m_controller, writePWM(SHOULDER, 1500));
  EXPECT_CALL(m_controller, writePWM(ELBOW   , 1500));
  EXPECT_CALL(m_controller, writePWM(ROLL    , 1500));
  EXPECT_CALL(m_controller, writePWM(PITCH   , 1500));
  EXPECT_CALL(m_controller, writePWM(WRIST   , 1500));
  EXPECT_CALL(m_controller, writePWM(GRIPPER , 1500));
  m_controller.update(10);
}

TEST_F(ControllerTest, FinishTeachPointSelection) {
  send("'b");
  EXPECT_CALL(m_controller, reportAngle(_));
  send("b");
}

TEST_F(ControllerTest, OnlyAlphabeticTeachPoints) {
  send("''");
  EXPECT_EQ(45, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, WrongTeachPointKeyStopsDrives) {
  m_controller.targetAngle(BASE, 0);
  send("''");
  EXPECT_EQ(45, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, TeachPointLoadingClearsNumber) {
  send("0'b");
  EXPECT_CALL(m_controller, reportAngle(_));
  send("b");
}

TEST_F(ControllerTest, SaveTeachPoint) {
  send("mb'b");
  EXPECT_EQ( 45, m_controller.curve(BASE    ).target());
  EXPECT_EQ(-10, m_controller.curve(SHOULDER).target());
  EXPECT_EQ( 20, m_controller.curve(ELBOW   ).target());
  EXPECT_EQ( 30, m_controller.curve(ROLL    ).target());
  EXPECT_EQ( 15, m_controller.curve(PITCH   ).target());
  EXPECT_EQ(-20, m_controller.curve(WRIST   ).target());
  EXPECT_EQ( 70, m_controller.curve(GRIPPER ).target());
}

TEST_F(ControllerTest, PrintDefaultTeachPoint) {
  EXPECT_CALL(m_controller, reportTeachPoint(0, 0, 0, 0, 0, 0, 0));
  send("da");
}

TEST_F(ControllerTest, PrintTeachPoint) {
  EXPECT_CALL(m_controller, reportTeachPoint(45, -10, 20, 30, 15, -20, 70));
  send("mbdb");
}

TEST_F(ControllerTest, FinishTeachPointSaving) {
  EXPECT_CALL(m_controller, reportAngle(_));
  send("mbb");
}

TEST_F(ControllerTest, TeachPointSavingClearsNumber) {
  EXPECT_CALL(m_controller, reportAngle(_));
  send("0mbb");
}

TEST_F(ControllerTest, WrongTeachPointSelectionStopsDrives) {
  m_controller.targetAngle(BASE, 0);
  send("m'");
  EXPECT_EQ(45, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, SaveSecondTeachPoint) {
  send("mb'a");
  EXPECT_EQ(0, m_controller.curve(BASE    ).target());
  EXPECT_EQ(0, m_controller.curve(SHOULDER).target());
  EXPECT_EQ(0, m_controller.curve(ELBOW   ).target());
  EXPECT_EQ(0, m_controller.curve(ROLL    ).target());
  EXPECT_EQ(0, m_controller.curve(PITCH   ).target());
  EXPECT_EQ(0, m_controller.curve(WRIST   ).target());
  EXPECT_EQ(0, m_controller.curve(GRIPPER ).target());
}

TEST_F(ControllerTest, SynchroniseProfilesWithBase) {
  send("ma");
  m_controller.curve(BASE).stop(0);
  send("'a");
  float time = m_controller.curve(BASE).timeRemaining();
  EXPECT_LT(0, time);
  EXPECT_FLOAT_EQ(time, m_controller.curve(SHOULDER).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(ELBOW   ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(ROLL    ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(PITCH   ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(WRIST   ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(GRIPPER ).timeRemaining());
}

TEST_F(ControllerTest, SynchroniseProfilesWithShoulder) {
  send("ma");
  m_controller.curve(SHOULDER).stop(0);
  send("'a");
  float time = m_controller.curve(SHOULDER).timeRemaining();
  EXPECT_LT(0, time);
  EXPECT_FLOAT_EQ(time, m_controller.curve(BASE    ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(ELBOW   ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(ROLL    ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(PITCH   ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(WRIST   ).timeRemaining());
  EXPECT_FLOAT_EQ(time, m_controller.curve(GRIPPER ).timeRemaining());
}

TEST_F(ControllerTest, TargetConfiguration) {
  send("2 3 5 7 11 13 17c");
  EXPECT_EQ( 2, m_controller.curve(BASE    ).target());
  EXPECT_EQ( 3, m_controller.curve(SHOULDER).target());
  EXPECT_EQ( 5, m_controller.curve(ELBOW   ).target());
  EXPECT_EQ( 7, m_controller.curve(ROLL    ).target());
  EXPECT_EQ(11, m_controller.curve(PITCH   ).target());
  EXPECT_EQ(13, m_controller.curve(WRIST   ).target());
  EXPECT_EQ(17, m_controller.curve(GRIPPER ).target());
}

TEST_F(ControllerTest, IgnoreSuperfluous) {
  send("2 3 5 7 11 13 17c");
  EXPECT_EQ( 2, m_controller.curve(BASE    ).target());
  EXPECT_EQ( 3, m_controller.curve(SHOULDER).target());
  EXPECT_EQ( 5, m_controller.curve(ELBOW   ).target());
  EXPECT_EQ( 7, m_controller.curve(ROLL    ).target());
  EXPECT_EQ(11, m_controller.curve(PITCH   ).target());
  EXPECT_EQ(13, m_controller.curve(WRIST   ).target());
  EXPECT_EQ(17, m_controller.curve(GRIPPER ).target());
}

TEST_F(ControllerTest, MultipleConfigurations) {
  send("2c3c");
  EXPECT_EQ(3, m_controller.curve(BASE    ).target());
  EXPECT_EQ(0, m_controller.curve(SHOULDER).target());
  EXPECT_EQ(0, m_controller.curve(ELBOW   ).target());
  EXPECT_EQ(0, m_controller.curve(ROLL    ).target());
  EXPECT_EQ(0, m_controller.curve(PITCH   ).target());
  EXPECT_EQ(0, m_controller.curve(WRIST   ).target());
  EXPECT_EQ(0, m_controller.curve(GRIPPER ).target());
}

TEST_F(ControllerTest, ConfigurationBoundValues) {
  send("-99c");
  EXPECT_LT(-80, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, ClearConfiguration) {
  send("2 3c4c");
  EXPECT_EQ(4, m_controller.curve(BASE    ).target());
  EXPECT_EQ(0, m_controller.curve(SHOULDER).target());
  EXPECT_EQ(0, m_controller.curve(ELBOW   ).target());
  EXPECT_EQ(0, m_controller.curve(ROLL    ).target());
  EXPECT_EQ(0, m_controller.curve(PITCH   ).target());
  EXPECT_EQ(0, m_controller.curve(WRIST   ).target());
  EXPECT_EQ(0, m_controller.curve(GRIPPER ).target());
}

TEST_F(ControllerTest, ZeroTimeRequired) {
  EXPECT_CALL(m_controller, reportRequired(0));
  send("45 -10 20 30 15 -20 70t");
}

TEST_F(ControllerTest, NonZeroTimeRequired) {
  EXPECT_CALL(m_controller, reportRequired(Gt(0)));
  send("50 -10 20 30 15 -20 70t");
}

TEST_F(ControllerTest, ReportingTimeRequiredClearsNumber) {
  EXPECT_CALL(m_controller, reportRequired(0));
  send("45 -10 20 30 15 -20 70t0c");
  EXPECT_EQ(0, m_controller.curve(BASE).target());
}

TEST_F(ControllerTest, DrivesReady) {
  EXPECT_CALL(m_controller, reportReady(true));
  send("o");
}

TEST_F(ControllerTest, ReportingReadyStateClearsNumber) {
  EXPECT_CALL(m_controller, reportReady(_));
  EXPECT_CALL(m_controller, reportAngle(_));
  send("0ob");
}

TEST_F(ControllerTest, BaseDriveNotReady) {
  EXPECT_CALL(m_controller, reportReady(false));
  send("0b10bo");
}

TEST_F(ControllerTest, ShoulderDriveNotReady) {
  EXPECT_CALL(m_controller, reportReady(false));
  send("0s10so");
}

TEST_F(ControllerTest, ReportConfiguration) {
  EXPECT_CALL(m_controller, reportConfiguration(45, -10, 20, 30, 15, -20, 70));
  send("c");
}

TEST_F(ControllerTest, ReportLowerLimits) {
  float lower = -79.666667f;
  EXPECT_CALL(m_controller, reportLower(lower, lower, lower, lower, lower, lower, lower));
  send("l");
}

TEST_F(ControllerTest, ReportingLowerLimitsClearsNumber) {
  EXPECT_CALL(m_controller, reportLower(_, _, _, _, _, _, _));
  EXPECT_CALL(m_controller, reportAngle(_));
  send("0lb");
}

TEST_F(ControllerTest, ReportUpperLimits) {
  float upper = 75.0f;
  EXPECT_CALL(m_controller, reportUpper(upper, upper, upper, upper, upper, upper, upper));
  send("u");
}

TEST_F(ControllerTest, ReportingUpperLimitsClearsNumber) {
  EXPECT_CALL(m_controller, reportUpper(_, _, _, _, _, _, _));
  EXPECT_CALL(m_controller, reportAngle(_));
  send("0ub");
}

int main(int argc, char **argv) {
  InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
