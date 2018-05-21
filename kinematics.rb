require 'matrix'


# https://en.wikipedia.org/wiki/Kinematics%E2%80%93Hartenberg_parameters
class Kinematics
  BASE     = 110
  FOOT     = 40
  SHOULDER = 127
  KNEE     = 26
  ELBOW    = 133
  GRIPPER  = 121

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

    def inverse matrix
      translation = matrix.column_vectors[3]
      rotation = matrix.column_vectors[2]
      wrist_position = translation - rotation * GRIPPER
      base_angle = Math.atan2 wrist_position[1], wrist_position[0]
      arm_vector = wrist_position - Vector[Math.cos(base_angle) * FOOT, Math.sin(base_angle) * FOOT, BASE, 1]
      arm_elevation = Math.atan2 arm_vector[2], Math.hypot(arm_vector[0], arm_vector[1])
      elbow_knee_length = Math.hypot ELBOW, KNEE
      elbow_elevation = Math.acos((arm_vector.norm ** 2 + SHOULDER ** 2 - elbow_knee_length ** 2) / (2 * arm_vector.norm * SHOULDER))
      shoulder_angle = arm_elevation + elbow_elevation - 0.5 * Math::PI
      Vector[base_angle, shoulder_angle, -shoulder_angle, 0, 0, 0]
    end
  end
end
