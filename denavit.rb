require 'matrix'


# https://en.wikipedia.org/wiki/Denavit%E2%80%93Hartenberg_parameters
class Denavit
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

    def base angle
      hartenberg BASE, angle, FOOT, 0.5 * Math::PI
    end
  end
end
