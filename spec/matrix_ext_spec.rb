require_relative '../matrix_ext'


describe Matrix do
  it 'should provide the x-vector' do
    expect(Matrix.identity(4).x).to eq Vector[1, 0, 0, 0]
  end

  it 'should provide the y-vector' do
    expect(Matrix.identity(4).y).to eq Vector[0, 1, 0, 0]
  end

  it 'should provide the z-vector' do
    expect(Matrix.identity(4).z).to eq Vector[0, 0, 1, 0]
  end

  it 'should provide the translation vector' do
    expect(Matrix.identity(4).translation).to eq Vector[0, 0, 0, 1]
  end

  describe :rotate_x do
    it 'no rotation should generate identity matrix' do
      expect(Matrix.rotate_x(0)).to eq Matrix.identity(4)
    end

    it 'should perform rotation around x-axis' do
      expect(Matrix.rotate_x(0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[1, 0, 0, 0], [0, 0, -1, 0], [0, 1, 0, 0], [0, 0, 0, 1]]
    end
  end

  describe :rotate_y do
    it 'no rotation should generate identity matrix' do
      expect(Matrix.rotate_y(0)).to eq Matrix.identity(4)
    end

    it 'should perform rotation around y-axis' do
      expect(Matrix.rotate_y(0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[0, 0, 1, 0], [0, 1, 0, 0], [-1, 0, 0, 0], [0, 0, 0, 1]]
    end
  end

  describe :rotate_z do
    it 'no rotation should generate the identity matrix' do
      expect(Matrix.rotate_z(0)).to eq Matrix.identity(4)
    end

    it 'should perform rotation around z-axis' do
      expect(Matrix.rotate_z(0.5 * Math::PI)).to be_within(1e-6).
        of Matrix[[0, -1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    end
  end

  describe :translate_x do
    it 'should perform translation along the x-axis' do
      expect(Matrix.translate_x(3)).to eq Matrix[[1, 0, 0, 3], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    end
  end

  describe :translate_y do
    it 'should perform translation along the y-axis' do
      expect(Matrix.translate_y(3)).to eq Matrix[[1, 0, 0, 0], [0, 1, 0, 3], [0, 0, 1, 0], [0, 0, 0, 1]]
    end
  end

  describe :translate_z do
    it 'should perform translation along the z-axis' do
      expect(Matrix.translate_z(3)).to eq Matrix[[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 3], [0, 0, 0, 1]]
    end
  end

  describe :translation do
    it 'should perform the specified translation' do
      expect(Matrix.translation(2, 3, 5)).to eq Matrix[[1, 0, 0, 2], [0, 1, 0, 3], [0, 0, 1, 5], [0, 0, 0, 1]]
    end
  end
end
