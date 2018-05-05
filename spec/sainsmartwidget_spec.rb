require_relative '../sainsmartwidget'

describe SainsmartWidget do
  before :all do
    @app = Qt::Application.new []
  end

  let :client do
    double 'Client'
  end

  let :widget do
    expect(client).to receive(:pos).at_least(:once).and_return([1, 2, 3, 4, 5, 6, 7])
    expect(client).to receive(:lower).and_return([-10, -20, -30, -45, -50, -60, -70])
    expect(client).to receive(:upper).and_return([+10, +20, +30, +45, +50, +60, +70])
    SainsmartWidget.new client
  end

  context 'when moving the base spin box' do
    context 'if robot is ready' do
      before :each do
        expect(client).to receive(:ready?).and_return true
      end

      it 'should move the base' do
        expect(client).to receive(:target).with(10, 2, 3, 4, 5, 6, 7)
        widget.ui.baseSpin.setValue 10
      end

      it 'should halt the drives if stop is pressed' do
        expect(client).to receive(:target)
        expect(client).to receive(:stop)
        widget.ui.baseSpin.setValue 10
        emit widget.ui.stopButton.clicked
        expect(widget.ui.baseSpin.value).to eq 1
      end

      it 'should halt the drives if the Escape key is pressed' do
        expect(client).to receive(:target)
        expect(client).to receive(:stop)
        widget.ui.baseSpin.setValue 10
        e = double 'Qt::KeyPressEvent'
        allow(e).to receive(:key).and_return Qt.Key_Escape
        widget.keyPressEvent e
      end

      it 'should not do anything if the Space key is pressed' do
        expect(client).to receive(:target)
        widget.ui.baseSpin.setValue 10
        e = double 'Qt::KeyPressEvent'
        allow(e).to receive(:key).and_return Qt.Key_Space
        widget.keyPressEvent e
      end
    end

    context 'if robot is busy' do
      before :each do
        expect(client).to receive(:ready?).and_return false
      end

      it 'should start polling' do
        expect(widget).to receive(:defer)
        widget.ui.baseSpin.setValue 10
      end

      it 'should stop polling if the stop button is pressed' do
        expect(widget).to receive(:defer)
        expect(widget).to receive(:kill_timer)
        expect(client).to receive(:stop)
        widget.ui.baseSpin.setValue 10
        widget.ui.stopButton.clicked
        expect(widget.ui.baseSpin.value).to eq 1
      end
    end
  end

  context 'with pending updates' do
    before :each do
      widget.defer
    end

    it 'should process them when ready' do
      expect(client).to receive(:ready?).and_return true
      expect(client).to receive(:target)
      widget.pending
    end

    it 'should defer them if robot is not ready' do
      widget.defer
      expect(client).to receive(:ready?).and_return false
      expect(widget).to receive(:defer)
      widget.pending
    end
  end

  it 'should use values from the shoulder spin box' do
    expect(client).to receive(:ready?).and_return true
    expect(client).to receive(:target).with(1, 10, 3, 4, 5, 6, 7)
    widget.ui.shoulderSpin.setValue 10
  end

  it 'should use values from the elbow spin box' do
    expect(client).to receive(:ready?).and_return true
    expect(client).to receive(:target).with(1, 2, 10, 4, 5, 6, 7)
    widget.ui.elbowSpin.setValue 10
  end

  it 'should use values from the gripper spin box' do
    expect(client).to receive(:ready?).and_return true
    expect(client).to receive(:target).with(1, 2, 3, 4, 5, 6, 10)
    widget.ui.gripperSpin.setValue 10
  end

  it 'should set the lower limits for the spin boxes' do
    expect(widget.ui.baseSpin.minimum    ).to eq -10
    expect(widget.ui.shoulderSpin.minimum).to eq -20
    expect(widget.ui.elbowSpin.minimum   ).to eq -30
    expect(widget.ui.gripperSpin.minimum ).to eq -70
  end

  it 'should set the upper limits for the spin boxes' do
    expect(widget.ui.baseSpin.maximum    ).to eq +10
    expect(widget.ui.shoulderSpin.maximum).to eq +20
    expect(widget.ui.elbowSpin.maximum   ).to eq +30
    expect(widget.ui.gripperSpin.maximum ).to eq +70
  end

  context 'synchronising GUI elements' do
    before :each do
      expect(client).to receive(:ready?).at_least(:once).and_return true
      expect(client).to receive(:target).at_least(:once)
    end

    it 'should update the base slider if the base spin box is changed' do
      widget.ui.baseSpin.setValue 10
      expect(widget.ui.baseSlider.value).to eq 10000
    end

    it 'should update the base spin box if the base slider is changed' do
      widget.ui.baseSlider.setValue 10000
      expect(widget.ui.baseSpin.value).to eq 10
    end

    it 'should update the shoulder slider if the shoulder spin box is changed' do
      widget.ui.shoulderSpin.setValue 0
      expect(widget.ui.shoulderSlider.value).to eq 5000
    end

    it 'should update the shoulder spin box if the shoulder slider is changed' do
      widget.ui.shoulderSlider.setValue 5000
      expect(widget.ui.shoulderSpin.value).to eq 0
    end

    it 'should update the elbow slider if the elbow spin box is changed' do
      widget.ui.elbowSpin.setValue 30
      expect(widget.ui.elbowSlider.value).to eq 10000
    end

    it 'should update the elbow spin box if the elbow slider is changed' do
      widget.ui.elbowSlider.setValue 10000
      expect(widget.ui.elbowSpin.value).to eq 30
    end

    it 'should update the spin box associated with open gripper state' do
      widget.ui.gripperSpin.setValue 10
      expect(widget.ui.gripperOpenSpin.value).to eq 10
    end

    context 'with closed gripper radio button toggled' do
      before :each do
        widget.ui.gripperClose.setChecked true
      end

      it 'should update the gripper spin' do
        expect(widget.ui.gripperSpin.value).to eq 45
      end

      it 'should update the spin box associated with closed gripper state' do
        widget.ui.gripperSpin.setValue 10
        expect(widget.ui.gripperCloseSpin.value).to eq 10
      end
    end
  end

  it 'should save teach point \'a\'' do
    expect(client).to receive(:save_teach_point).with 0
    emit widget.ui.saveButton.clicked
  end

  it 'should save teach point \'c\'' do
    expect(client).to receive(:save_teach_point).with 2
    widget.ui.teachPointCombo.setCurrentIndex 2
    emit widget.ui.saveButton.clicked
  end

  it 'should target teach point \'a\'' do
    expect(client).to receive(:load_teach_point).with(0).and_return [2, 3, 5, 7]
    emit widget.ui.loadButton.clicked
  end

  it 'should target teach point \'c\'' do
    expect(client).to receive(:load_teach_point).with(2).and_return [2, 3, 5, 7]
    widget.ui.teachPointCombo.setCurrentIndex 2
    emit widget.ui.loadButton.clicked
  end

  it 'should update the controls when targeting a teach point' do
    expect(client).to receive(:load_teach_point).with(0).and_return [2, 3, 5, 7, 11, 13, 17]
    emit widget.ui.loadButton.clicked
    expect(widget.ui.baseSpin.value    ).to eq +2
    expect(widget.ui.shoulderSpin.value).to eq +3
    expect(widget.ui.elbowSpin.value   ).to eq +5
    expect(widget.ui.gripperSpin.value ).to eq +17
  end

  it 'should select the second teach point when \'b\' is pressed' do
    e = double 'Qt::KeyPressEvent'
    allow(e).to receive(:key).and_return Qt.Key_B
    widget.keyPressEvent e
    expect(widget.ui.teachPointCombo.currentIndex).to be 1
  end

  it 'should select the last teach point when \'l\' is pressed' do
    e = double 'Qt::KeyPressEvent'
    allow(e).to receive(:key).and_return Qt.Key_L
    widget.keyPressEvent e
    expect(widget.ui.teachPointCombo.currentIndex).to be 11
  end
end
