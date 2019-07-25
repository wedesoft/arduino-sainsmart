require_relative 'matrix_ext'


# https://en.wikipedia.org/wiki/Kinematics%E2%80%93Hartenberg_parameters
class Kinematics
  BASE     = 110.0 #d1
  FOOT     =  40.0 #a1
  SHOULDER = 127.0 #a2
  KNEE     =  26.0 #a3
  ELBOW    = 133.0 #d4
  SPAN     = Math.hypot ELBOW, KNEE #d4, a3
  GRIPPER  = 121.0 #d6

  class << self
    def hartenberg d, theta, r, alpha
      Matrix.translate_z(d) * Matrix.rotate_z(theta) * Matrix.translate_x(r) * Matrix.rotate_x(alpha)
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
      cos_angle =(b ** 2 + c ** 2 - a ** 2) / (2 * b * c)
      if cos_angle <= 1
        Math.acos cos_angle
      else
        nil
      end
    end

    def inverse matrix
      wrist_position = matrix.translation - matrix.z * GRIPPER
      base_angle = Math.atan2 wrist_position[1], wrist_position[0]
      arm_vector = wrist_position - Vector[Math.cos(base_angle) * FOOT, Math.sin(base_angle) * FOOT, BASE, 1]
      arm_elevation = Math.atan2 arm_vector[2], Math.hypot(arm_vector[0], arm_vector[1])
      elbow_elevation = cosinus_theorem SPAN, arm_vector.norm, SHOULDER
      unless elbow_elevation.nil?
        shoulder_angle = arm_elevation + elbow_elevation - 0.5 * Math::PI
        elbow_angle = 0.5 * Math::PI - cosinus_theorem(arm_vector.norm, SHOULDER, SPAN) + Math.atan(KNEE / ELBOW)
        head_matrix = Matrix.rotate_y(shoulder_angle - elbow_angle) * Matrix.rotate_z(-base_angle) * matrix
        gripper_vector = head_matrix.z
        pitch_angle = Math.atan2 Math.hypot(gripper_vector[1], gripper_vector[2]), gripper_vector[0]
        if Math.hypot(gripper_vector[1], gripper_vector[2]) < 1e-5
          roll_angle = 0
        elsif gripper_vector[2] >= 0
          roll_angle = Math.atan2 -gripper_vector[1], gripper_vector[2]
        else
          roll_angle = Math.atan2 gripper_vector[1], -gripper_vector[2]
          pitch_angle = -pitch_angle
        end
        adapter_matrix = Matrix[[0, -1, 0, 0], [0, 0, -1, 0], [1, 0, 0, 0], [0, 0, 0, 0]]
        wrist_matrix = Matrix.rotate_x(-pitch_angle) * Matrix.rotate_z(-roll_angle) * adapter_matrix * head_matrix
        wrist_vector = wrist_matrix.x
        wrist_angle = Math.atan2 wrist_vector[1], wrist_vector[0]
        Vector[base_angle, shoulder_angle, elbow_angle - shoulder_angle, roll_angle, pitch_angle, wrist_angle]
      else
        nil
      end
    end
  end
end
