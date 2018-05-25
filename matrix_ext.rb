require 'matrix'


class Vector
  def abs
    Math.sqrt inject(0) { |s, x| s + x ** 2 }
  end
end

class Matrix
end

class Matrix
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

    def translation x, y, z
      arr = Matrix.identity(4).to_a
      arr[0][3] = x
      arr[1][3] = y
      arr[2][3] = z
      Matrix[*arr]
    end

    def translate_x distance
      translation distance, 0, 0
    end

    def translate_y distance
      translation 0, distance, 0
    end

    def translate_z distance
      translation 0, 0, distance
    end
  end

  def abs
    Math.sqrt inject { |s, x| s + x ** 2 }
  end


  def x
    column_vectors[0]
  end

  def y
    column_vectors[1]
  end

  def z
    column_vectors[2]
  end

  def translation
    column_vectors[3]
  end
end
