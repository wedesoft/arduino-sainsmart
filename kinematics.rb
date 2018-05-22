require 'matrix'


# https://en.wikipedia.org/wiki/Kinematics%E2%80%93Hartenberg_parameters
class Kinematics
  BASE     = 110.0
  FOOT     =  40.0
  SHOULDER = 127.0
  KNEE     =  26.0
  ELBOW    = 133.0
  GRIPPER  = 121.0

  class << self
    def rotate angle, i, j
      cos_angle, sin_angle = Math.cos(angle), Math.sin(angle)
      arr = Matrix.identity(4).to_a
      arr[i][i], arr[i][j] = cos_angle, -sin_angle
      arr[j][i], arr[j][j] = sin_angle,  cos_angle
      Matrix[*arr]
    end

    def rotate_x angle
      rotate angle, 1, 2
    end

    def rotate_y angle
      rotate angle, 2, 0
    end

    def rotate_z angle
      rotate angle, 0, 1
    end

    def translate distance, i
      arr = Matrix.identity(4).to_a
      arr[i][3] = distance
      Matrix[*arr]
    end

    def translate_x distance
      translate distance, 0
      arr = Matrix.identity(4).to_a
      arr[0][3] = distance
      Matrix[*arr]
    end

    def translate_z distance
      translate distance, 2
    end

    def hartenberg d, theta, r, alpha
      translate_z(d) * rotate_z(theta) * translate_x(r) * rotate_x(alpha)
    end

    def base base_angle
      hartenberg BASE, base_angle, FOOT, 0.5 * Math::PI
    end

    def shoulder base_angle, shoulder_angle
      base(base_angle) *
        hartenberg(0, shoulder_angle + 0.5 * Math::PI, SHOULDER, Math::PI)
    end

    def elbow base_angle, shoulder_angle, elbow_angle
      shoulder(base_angle, shoulder_angle) *
        hartenberg(0, elbow_angle + Math::PI, -KNEE, 0.5 * Math::PI)
    end

    def roll base_angle, shoulder_angle, elbow_angle, roll_angle
      elbow(base_angle, shoulder_angle, elbow_angle) *
        hartenberg(ELBOW, roll_angle, 0, 0.5 * Math::PI)
    end

    def pitch base_angle, shoulder_angle, elbow_angle, roll_angle, pitch_angle
      roll(base_angle, shoulder_angle, elbow_angle, roll_angle) *
        hartenberg(0, Math::PI + pitch_angle, 0, 0.5 * Math::PI)
    end

    def wrist base_angle, shoulder_angle, elbow_angle, roll_angle, pitch_angle, wrist_angle
      pitch(base_angle, shoulder_angle, elbow_angle, roll_angle, pitch_angle) *
        hartenberg(GRIPPER, 0.5 * Math::PI + wrist_angle, 0, 0)
    end

    def forward servo_angle
      wrist servo_angle[0], servo_angle[1], servo_angle[1] + servo_angle[2], *servo_angle[3...6]
    end

    def cosinus_theorem a, b, c
      Math.acos (b ** 2 + c ** 2 - a ** 2) / (2 * b * c)
    end

    def inverse matrix
      translation = matrix * Vector[0, 0, 0, 1]
      rotation = matrix * Vector[0, 0, 1, 0]
      wrist_position = translation - rotation * GRIPPER
      base_angle = Math.atan2 wrist_position[1], wrist_position[0]
      arm_vector = wrist_position - Vector[Math.cos(base_angle) * FOOT, Math.sin(base_angle) * FOOT, BASE, 1]
      arm_elevation = Math.atan2 arm_vector[2], Math.hypot(arm_vector[0], arm_vector[1])
      elbow_knee_length = Math.hypot ELBOW, KNEE
      elbow_elevation = cosinus_theorem elbow_knee_length, arm_vector.norm, SHOULDER
      shoulder_angle = arm_elevation + elbow_elevation - 0.5 * Math::PI
      elbow_angle = 0.5 * Math::PI - cosinus_theorem(arm_vector.norm, SHOULDER, elbow_knee_length) + Math.atan(KNEE / ELBOW)
      head_matrix = rotate_y(shoulder_angle - elbow_angle) * rotate_z(-base_angle) * matrix
      gripper_vector = head_matrix * Vector[0, 0, 1, 0]
      pitch_angle = Math.atan2 Math.hypot(gripper_vector[1], gripper_vector[2]), gripper_vector[0]
      if Math.hypot(gripper_vector[1], gripper_vector[2]) < 1e-5
        roll_angle = 0
      elsif gripper_vector[2] >= 0
        roll_angle = Math.atan2 -gripper_vector[1], gripper_vector[2]
      else
        roll_angle = Math.atan2 gripper_vector[1], -gripper_vector[2]
        pitch_angle = -pitch_angle
      end
      Vector[base_angle, shoulder_angle, elbow_angle - shoulder_angle, roll_angle, pitch_angle, 0]
    end
  end
end
