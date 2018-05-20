require_relative '../denavit'


class Vector
  def abs
    Math.sqrt inject(0) { |s, x| s + x ** 2 }
  end
end

class Matrix
  def abs
    Math.sqrt inject { |s, x| s + x ** 2 }
  end
end

describe Denavit do
  describe :rotate_z do
    it 'no rotation should generate the identity matrix' do
      expect(Denavit.rotate_z(0)).to eq Matrix.identity(4)
    end

    it 'should perform rotation around z-axis' do
      expect(Denavit.rotate_z(0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[0, -1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    end
  end

  describe :rotate_x do
    it 'no rotation should generate identity matrix' do
      expect(Denavit.rotate_x(0)).to eq Matrix.identity(4)
    end

    it 'should perform rotation around x-axis' do
      expect(Denavit.rotate_x(0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[1, 0, 0, 0], [0, 0, -1, 0], [0, 1, 0, 0], [0, 0, 0, 1]]
    end
  end

  describe :translate_x do
    it 'no translation should generate the identity matrix' do
      expect(Denavit.translate_x(0)).to eq Matrix.identity(4)
    end

    it 'should perform translation along x-axis' do
      expect(Denavit.translate_x(1)).to eq Matrix[[1, 0, 0, 1], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    end
  end

  describe :translate_z do
    it 'no translation should generate the identity matrix' do
      expect(Denavit.translate_z(0)).to eq Matrix.identity(4)
    end

    it 'should perform translation along z-axis' do
      expect(Denavit.translate_z(1)).to eq Matrix[[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 1], [0, 0, 0, 1]]
    end
  end

  describe :hartenberg do
    it 'zero parameters should generate identity matrix' do
      expect(Denavit.hartenberg(0, 0, 0, 0)).to eq Matrix.identity(4)
    end

    it 'should perform translations' do
      expect(Denavit.hartenberg(2, 0, 3, 0)).
        to eq Matrix[[1, 0, 0, 3], [0, 1, 0, 0], [0, 0, 1, 2], [0, 0, 0, 1]]
    end

    it 'should rotate around z-axis' do
      expect(Denavit.hartenberg(2, 0.5 * Math::PI, 3, 0)).to be_within(1e-6).
        of Matrix[[0, -1, 0, 0], [1, 0, 0, 3], [0, 0, 1, 2], [0, 0, 0, 1]]
    end

    it 'should rotate around x-axis' do
      expect(Denavit.hartenberg(2, 0, 3, 0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[1, 0, 0, 3], [0, 0, -1, 0], [0, 1, 0, 2], [0, 0, 0, 1]]
    end
  end

  BASE     = Denavit::BASE
  FOOT     = Denavit::FOOT
  SHOULDER = Denavit::SHOULDER
  KNEE     = Denavit::KNEE
  ELBOW    = Denavit::ELBOW
  GRIPPER  = Denavit::GRIPPER

  let(:pi2)    { Math::PI / 2 }
  let(:origin) { Vector[0, 0, 0, 1] }
  let(:x) { Vector[1, 0, 0, 0] }
  let(:y) { Vector[0, 1, 0, 0] }
  let(:z) { Vector[0, 0, 1, 0] }

  describe :base do
    it 'should have the correct center' do
      expect(Denavit.base(0) * origin).to eq Vector[FOOT, 0, BASE, 1]
    end

    it 'should orient the shoulder axis' do
      expect(Denavit.base(0) * z).to be_within(1e-6).of -y
    end

    it 'should have the correct x-axis' do
      expect(Denavit.base(0) * x).to be_within(1e-6).of x
    end

    it 'should support rotation of the base' do
      expect(Denavit.base(pi2) * origin).to be_within(1e-6).
        of Vector[0, FOOT, BASE, 1]
    end
  end

  describe :shoulder do
    it 'should orient the z-axis' do
      expect(Denavit.shoulder(0, -pi2) * z).to be_within(1e-6).of y
    end

    it 'should have the correct x-axis' do
      expect(Denavit.shoulder(0, -pi2) * x).to be_within(1e-6).of x
    end

    it 'should have the correct center' do
      expect(Denavit.shoulder(0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT, 0, BASE + SHOULDER, 1]
    end

    it 'should support rotation' do
      expect(Denavit.shoulder(0, -pi2) * origin).to be_within(1e-6).
        of Vector[FOOT + SHOULDER, 0, BASE, 1]
    end
  end

  describe :elbow do
    it 'should orient the z-axis' do
      expect(Denavit.elbow(0, 0, 0) * z).to be_within(1e-6).of x
    end

    it 'should orient the x-axis' do
      expect(Denavit.elbow(0, 0, 0) * x).to be_within(1e-6).of -z
    end

    it 'should have the correct center' do
      expect(Denavit.elbow(0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Denavit.elbow(0, 0, pi2) * origin).to be_within(1e-6).
        of Vector[FOOT + KNEE, 0, BASE + SHOULDER, 1]
    end
  end

  describe :roll do
    it 'should orient the z-axis' do
      expect(Denavit.roll(0, 0, 0, 0) * z).to be_within(1e-6).of -y
    end

    it 'should orient the x-axis' do
      expect(Denavit.roll(0, 0, 0, 0) * x).to be_within(1e-6).of -z
    end

    it 'should have the correct center' do
      expect(Denavit.roll(0, 0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT + ELBOW, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Denavit.roll(0, 0, 0, pi2) * x).to be_within(1e-6).of y
    end
  end

  describe :pitch do
    it 'should orient the z-axis' do
      expect(Denavit.pitch(0, 0, 0, 0, 0) * z).to be_within(1e-6).of x
    end

    it 'should orient the x-axis' do
      expect(Denavit.pitch(0, 0, 0, 0, 0) * x).to be_within(1e-6).of z
    end

    it 'should have the correct center' do
      expect(Denavit.pitch(0, 0, 0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT + ELBOW, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Denavit.pitch(0, 0, 0, 0, pi2) * z).to be_within(1e-6).of z
    end
  end

  describe :wrist do
    it 'should orient the z-axis' do
      expect(Denavit.wrist(0, 0, 0, 0, 0, 0) * z).to be_within(1e-6).of x
    end

    it 'should orient the x-axis along the way the gripper opens' do
      expect(Denavit.wrist(0, 0, 0, 0, 0, 0) * x).to be_within(1e-6).of -y
    end

    it 'should have the correct center' do
      expect(Denavit.wrist(0, 0, 0, 0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT + ELBOW + GRIPPER, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Denavit.wrist(0, 0, 0, 0, 0, pi2) * x).to be_within(1e-6).of -z
    end
  end
end
