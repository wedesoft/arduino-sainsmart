require_relative '../kinematics'


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

describe Kinematics do
  describe :rotate_z do
    it 'no rotation should generate the identity matrix' do
      expect(Kinematics.rotate_z(0)).to eq Matrix.identity(4)
    end

    it 'should perform rotation around z-axis' do
      expect(Kinematics.rotate_z(0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[0, -1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    end
  end

  describe :rotate_x do
    it 'no rotation should generate identity matrix' do
      expect(Kinematics.rotate_x(0)).to eq Matrix.identity(4)
    end

    it 'should perform rotation around x-axis' do
      expect(Kinematics.rotate_x(0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[1, 0, 0, 0], [0, 0, -1, 0], [0, 1, 0, 0], [0, 0, 0, 1]]
    end
  end

  describe :translate_x do
    it 'no translation should generate the identity matrix' do
      expect(Kinematics.translate_x(0)).to eq Matrix.identity(4)
    end

    it 'should perform translation along x-axis' do
      expect(Kinematics.translate_x(1)).to eq Matrix[[1, 0, 0, 1], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    end
  end

  describe :translate_z do
    it 'no translation should generate the identity matrix' do
      expect(Kinematics.translate_z(0)).to eq Matrix.identity(4)
    end

    it 'should perform translation along z-axis' do
      expect(Kinematics.translate_z(1)).to eq Matrix[[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 1], [0, 0, 0, 1]]
    end
  end

  describe :hartenberg do
    it 'zero parameters should generate identity matrix' do
      expect(Kinematics.hartenberg(0, 0, 0, 0)).to eq Matrix.identity(4)
    end

    it 'should perform translations' do
      expect(Kinematics.hartenberg(2, 0, 3, 0)).
        to eq Matrix[[1, 0, 0, 3], [0, 1, 0, 0], [0, 0, 1, 2], [0, 0, 0, 1]]
    end

    it 'should rotate around z-axis' do
      expect(Kinematics.hartenberg(2, 0.5 * Math::PI, 3, 0)).to be_within(1e-6).
        of Matrix[[0, -1, 0, 0], [1, 0, 0, 3], [0, 0, 1, 2], [0, 0, 0, 1]]
    end

    it 'should rotate around x-axis' do
      expect(Kinematics.hartenberg(2, 0, 3, 0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[1, 0, 0, 3], [0, 0, -1, 0], [0, 1, 0, 2], [0, 0, 0, 1]]
    end
  end

  BASE     = Kinematics::BASE
  FOOT     = Kinematics::FOOT
  SHOULDER = Kinematics::SHOULDER
  KNEE     = Kinematics::KNEE
  ELBOW    = Kinematics::ELBOW
  GRIPPER  = Kinematics::GRIPPER

  let(:pi2)    { Math::PI / 2 }
  let(:pi4)    { Math::PI / 4 }
  let(:origin) { Vector[0, 0, 0, 1] }
  let(:x) { Vector[1, 0, 0, 0] }
  let(:y) { Vector[0, 1, 0, 0] }
  let(:z) { Vector[0, 0, 1, 0] }

  describe :base do
    it 'should have the correct center' do
      expect(Kinematics.base(0) * origin).to eq Vector[FOOT, 0, BASE, 1]
    end

    it 'should orient the shoulder axis' do
      expect(Kinematics.base(0) * z).to be_within(1e-6).of -y
    end

    it 'should have the correct x-axis' do
      expect(Kinematics.base(0) * x).to be_within(1e-6).of x
    end

    it 'should support rotation of the base' do
      expect(Kinematics.base(pi2) * origin).to be_within(1e-6).
        of Vector[0, FOOT, BASE, 1]
    end
  end

  describe :shoulder do
    it 'should orient the z-axis' do
      expect(Kinematics.shoulder(0, -pi2) * z).to be_within(1e-6).of y
    end

    it 'should have the correct x-axis' do
      expect(Kinematics.shoulder(0, -pi2) * x).to be_within(1e-6).of x
    end

    it 'should have the correct center' do
      expect(Kinematics.shoulder(0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT, 0, BASE + SHOULDER, 1]
    end

    it 'should support rotation' do
      expect(Kinematics.shoulder(0, -pi2) * origin).to be_within(1e-6).
        of Vector[FOOT + SHOULDER, 0, BASE, 1]
    end
  end

  describe :elbow do
    it 'should orient the z-axis' do
      expect(Kinematics.elbow(0, 0, 0) * z).to be_within(1e-6).of x
    end

    it 'should orient the x-axis' do
      expect(Kinematics.elbow(0, 0, 0) * x).to be_within(1e-6).of -z
    end

    it 'should have the correct center' do
      expect(Kinematics.elbow(0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Kinematics.elbow(0, 0, pi2) * origin).to be_within(1e-6).
        of Vector[FOOT + KNEE, 0, BASE + SHOULDER, 1]
    end
  end

  describe :roll do
    it 'should orient the z-axis' do
      expect(Kinematics.roll(0, 0, 0, 0) * z).to be_within(1e-6).of -y
    end

    it 'should orient the x-axis' do
      expect(Kinematics.roll(0, 0, 0, 0) * x).to be_within(1e-6).of -z
    end

    it 'should have the correct center' do
      expect(Kinematics.roll(0, 0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT + ELBOW, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Kinematics.roll(0, 0, 0, pi2) * x).to be_within(1e-6).of y
    end
  end

  describe :pitch do
    it 'should orient the z-axis' do
      expect(Kinematics.pitch(0, 0, 0, 0, 0) * z).to be_within(1e-6).of x
    end

    it 'should orient the x-axis' do
      expect(Kinematics.pitch(0, 0, 0, 0, 0) * x).to be_within(1e-6).of z
    end

    it 'should have the correct center' do
      expect(Kinematics.pitch(0, 0, 0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT + ELBOW, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Kinematics.pitch(0, 0, 0, 0, pi2) * z).to be_within(1e-6).of z
    end
  end

  describe :wrist do
    it 'should orient the z-axis' do
      expect(Kinematics.wrist(0, 0, 0, 0, 0, 0) * z).to be_within(1e-6).of x
    end

    it 'should orient the x-axis along the way the gripper opens' do
      expect(Kinematics.wrist(0, 0, 0, 0, 0, 0) * x).to be_within(1e-6).of -y
    end

    it 'should have the correct center' do
      expect(Kinematics.wrist(0, 0, 0, 0, 0, 0) * origin).to be_within(1e-6).
        of Vector[FOOT + ELBOW + GRIPPER, 0, BASE + SHOULDER + KNEE, 1]
    end

    it 'should support rotation' do
      expect(Kinematics.wrist(0, 0, 0, 0, 0, pi2) * x).to be_within(1e-6).of -z
    end
  end

  describe :forward do
    it 'should invoke the complete kinematic chain' do
      expect(Kinematics).to receive(:wrist).with 1, 2, 3, 4, 5, 6
      Kinematics.forward Vector[1, 2, 3, 4, 5, 6]
    end
  end

  describe :inverse_kinematics do
    def round_trip *args
      Kinematics.inverse Kinematics.forward(*args)
    end

    it 'should work for the neutral position' do
      expect(round_trip(Vector[0, 0, 0, 0, 0, 0])).to be_within(1e-6).of Vector[0, 0, 0, 0, 0, 0]
    end

    it 'should determine rotation of base joint' do
      expect(round_trip(Vector[pi2, 0, 0, 0, 0, 0])).to be_within(1e-6).of Vector[pi2, 0, 0, 0, 0, 0]
    end

    it 'should determine the base joint angle when the gripper is orthogonal to the elbow' do
      expect(round_trip(Vector[pi2, 0, 0, pi2, pi2, 0])[0]).to be_within(1e-6).of pi2
    end

    it 'should determine the base joint when the gripper is tilted' do
      expect(round_trip(Vector[0, 0, 0, pi2, pi4, 0])[0]).to be_within(1e-6).of 0
    end
  end
end
