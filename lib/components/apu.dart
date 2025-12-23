import 'package:fnes/components/emulator_state.dart';

class APU {
  APU();

  static const List<List<int>> _dutySequences = [
    [0, 1, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 0, 0, 0],
    [1, 0, 0, 1, 1, 1, 1, 1],
  ];

  static const double _highPassCoeff = 0.99925;
  static const double _lowPassInput = 1;
  static const double _lowPassFeedback = 0.50;
  static const double _pulseGain = 3;

  int globalTime = 0;
  bool frameCounterMode = false;
  bool irqDisable = false;
  bool frameIrq = false;

  final PulseWave pulse1 = PulseWave();
  final PulseWave pulse2 = PulseWave();
  final TriangleWave triangle = TriangleWave();
  final NoiseWave noise = NoiseWave();
  final DMC dmc = DMC();

  void cpuWrite(int address, int data) {
    switch (address) {
      case 0x4000:
        pulse1.dutycycle = ((data >> 6) & 0x03) / 8.0;
        pulse1.envelope.loop = (data & 0x20) != 0;
        pulse1.envelope.disable = (data & 0x10) != 0;
        pulse1.envelope.volume = data & 0x0F;
        pulse1.lengthCounter.halt = (data & 0x20) != 0;
      case 0x4001:
        pulse1.sweeper.enabled = (data & 0x80) != 0;
        pulse1.sweeper.period = ((data >> 4) & 0x07) + 1;
        pulse1.sweeper.down = (data & 0x08) != 0;
        pulse1.sweeper.shift = data & 0x07;
        pulse1.sweeper.reload = true;
        pulse1._updateSweepSilencing();
      case 0x4002:
        pulse1.reload = (pulse1.reload & 0xFF00) | data;
        pulse1._updateSweepSilencing();
      case 0x4003:
        pulse1.reload = (pulse1.reload & 0x00FF) | ((data & 0x07) << 8);
        pulse1.timer = pulse1.reload;
        pulse1.lengthCounter.load(data >> 3);
        pulse1.envelope.start = true;
        pulse1.phase = 0;
        pulse1._updateSweepSilencing();
      case 0x4004:
        pulse2.dutycycle = ((data >> 6) & 0x03) / 8.0;
        pulse2.envelope.loop = (data & 0x20) != 0;
        pulse2.envelope.disable = (data & 0x10) != 0;
        pulse2.envelope.volume = data & 0x0F;
        pulse2.lengthCounter.halt = (data & 0x20) != 0;
      case 0x4005:
        pulse2.sweeper.enabled = (data & 0x80) != 0;
        pulse2.sweeper.period = ((data >> 4) & 0x07) + 1;
        pulse2.sweeper.down = (data & 0x08) != 0;
        pulse2.sweeper.shift = data & 0x07;
        pulse2.sweeper.reload = true;
        pulse2._updateSweepSilencing();
      case 0x4006:
        pulse2.reload = (pulse2.reload & 0xFF00) | data;
        pulse2._updateSweepSilencing();
      case 0x4007:
        pulse2.reload = (pulse2.reload & 0x00FF) | ((data & 0x07) << 8);
        pulse2.timer = pulse2.reload;
        pulse2.lengthCounter.load(data >> 3);
        pulse2.envelope.start = true;
        pulse2.phase = 0;
        pulse2._updateSweepSilencing();
      case 0x4008:
        triangle.linearCounter.controlFlag = (data & 0x80) != 0;
        triangle.linearCounter.reload = data & 0x7F;
      case 0x400A:
        triangle.reload = (triangle.reload & 0xFF00) | data;
      case 0x400B:
        triangle.reload = (triangle.reload & 0x00FF) | ((data & 0x07) << 8);
        triangle.timer = triangle.reload;
        triangle.lengthCounter.load(data >> 3);
        triangle.linearCounter.setReloadFlag();
      case 0x400C:
        noise.envelope.loop = (data & 0x20) != 0;
        noise.envelope.disable = (data & 0x10) != 0;
        noise.envelope.volume = data & 0x0F;
        noise.lengthCounter.halt = (data & 0x20) != 0;
      case 0x400E:
        noise.mode = (data & 0x80) != 0;
        noise.reload = [
          0x004,
          0x008,
          0x010,
          0x020,
          0x040,
          0x060,
          0x080,
          0x0A0,
          0x0CA,
          0x0FE,
          0x17C,
          0x1FC,
          0x2FA,
          0x3F8,
          0x7F2,
          0xFE4,
        ][(data & 0x0F)];
      case 0x400F:
        noise.lengthCounter.load(data >> 3);
        noise.envelope.start = true;
      case 0x4010:
        dmc.irqEnabled = (data & 0x80) != 0;
        dmc.loop = (data & 0x40) != 0;
        dmc.timerLoad = [
          0x1AC,
          0x17C,
          0x154,
          0x140,
          0x11E,
          0x0FE,
          0x0E2,
          0x0D6,
          0x0BE,
          0x0A0,
          0x08E,
          0x080,
          0x06A,
          0x054,
          0x048,
          0x036,
        ][(data & 0x0F)];
      case 0x4011:
        dmc.dmcOutput = data & 0x7F;
      case 0x4012:
        dmc.sampleAddress = 0xC000 + (data * 0x40);
      case 0x4013:
        dmc.sampleLength = (data * 0x10) + 1;
      case 0x4015:
        pulse1.enable = (data & 0x01) != 0;
        pulse2.enable = (data & 0x02) != 0;
        triangle.enable = (data & 0x04) != 0;
        noise.enable = (data & 0x08) != 0;
        if ((data & 0x10) != 0) {
          dmc.enableDMC(dmc.sampleAddress, dmc.sampleLength);
        } else {
          dmc.disableDMC();
        }
      case 0x4017:
        frameCounterMode = (data & 0x80) != 0;
        irqDisable = (data & 0x40) != 0;
        if (irqDisable) frameIrq = false;

        globalTime = 0;

        if (frameCounterMode) _clockFrameCounter();
    }
  }

  int cpuRead(int address) {
    var data = 0;

    if (address == 0x4015) {
      data |= (pulse1.lengthCounter.counter > 0 ? 0x01 : 0);
      data |= (pulse2.lengthCounter.counter > 0 ? 0x02 : 0);
      data |= (triangle.lengthCounter.counter > 0 ? 0x04 : 0);
      data |= (noise.lengthCounter.counter > 0 ? 0x08 : 0);
      data |= (dmc.duration > 0 ? 0x10 : 0);
      data |= (frameIrq ? 0x40 : 0);

      frameIrq = false;
    }

    return data;
  }

  double _highPassPrev = 0;
  double _highPassOut = 0;
  double _lowPassPrev = 0;

  static final List<double> _pulseLookup = List.generate(31, (i) {
    if (i == 0) return 0.0;
    return 95.52 / (8128.0 / i + 100.0);
  });

  static final List<double> _tndLookup = List.generate(203, (i) {
    if (i == 0) return 0.0;
    return 163.67 / (24329.0 / i + 100.0);
  });

  double getOutputSample() {
    final p1 = pulse1.output();
    final p2 = pulse2.output();
    final tri = triangle.output();
    final noi = noise.output();
    final dmcOut = dmc.output();

    final pulseIndex = (p1 + p2).clamp(0, 30);
    final pulseOut = _pulseLookup[pulseIndex] * _pulseGain;

    final tndIndex = (tri * 3 + noi * 2 + dmcOut).clamp(0, 202);
    final tnd = _tndLookup[tndIndex];

    var sample = pulseOut + tnd;

    _highPassOut = sample - _highPassPrev + _highPassCoeff * _highPassOut;
    _highPassPrev = sample;
    sample = _highPassOut;

    sample = _lowPassInput * sample + _lowPassFeedback * _lowPassPrev;
    _lowPassPrev = sample;

    return sample.clamp(-1.0, 1.0);
  }

  void reset() {
    globalTime = 0;
    frameCounterMode = false;
    irqDisable = false;
    frameIrq = false;
    pulse1.reset();
    pulse2.reset();
    triangle.reset();
    noise.reset();
    dmc.reset();
    _highPassPrev = 0;
    _highPassOut = 0;
    _lowPassPrev = 0;
  }

  void clock() {
    globalTime++;

    if (frameCounterMode) {
      if (globalTime == 0x1D21 ||
          globalTime == 0x3A41 ||
          globalTime == 0x5763 ||
          globalTime == 0x7485 ||
          globalTime == 0x91A1) {
        if (globalTime == 0x91A1) globalTime = 0;
        _clockFrameCounter();
      }
    } else {
      if (globalTime == 0x1D21 ||
          globalTime == 0x3A41 ||
          globalTime == 0x5763 ||
          globalTime == 0x7485) {
        if (globalTime == 0x7485) globalTime = 0;
        _clockFrameCounter();
      }
    }

    if ((globalTime & 1) == 0) {
      pulse1.clock();
      pulse2.clock();
      noise.clock();
    }

    triangle.clock();
    dmc.clock();
  }

  int _frameStep = 0;
  void _clockFrameCounter() {
    if (frameCounterMode) {
      switch (_frameStep) {
        case 0:
          _clockEnvelopes();
          _clockLengthCounters();
          _clockSweepers();
        case 1:
          _clockEnvelopes();
        case 2:
          _clockEnvelopes();
          _clockLengthCounters();
          _clockSweepers();
        case 3:
          _clockEnvelopes();
        case 4:
          break;
      }

      _frameStep = (_frameStep + 1) % 5;
    } else {
      switch (_frameStep) {
        case 0:
          _clockEnvelopes();
        case 1:
          _clockEnvelopes();
          _clockLengthCounters();
          _clockSweepers();
        case 2:
          _clockEnvelopes();
        case 3:
          _clockEnvelopes();
          _clockLengthCounters();
          _clockSweepers();
          if (!irqDisable) frameIrq = true;
      }

      _frameStep = (_frameStep + 1) % 4;
    }
  }

  void _clockEnvelopes() {
    pulse1.envelope.clock();
    pulse2.envelope.clock();
    noise.envelope.clock();
    triangle.linearCounter.clock();
  }

  void _clockLengthCounters() {
    pulse1.lengthCounter.clock();
    pulse2.lengthCounter.clock();
    triangle.lengthCounter.clock();
    noise.lengthCounter.clock();
  }

  void _clockSweepers() {
    pulse1.sweeper.clock(
      pulse1.reload,
      (v) => pulse1.reload = v,
      isPulse1: true,
    );
    pulse2.sweeper.clock(
      pulse2.reload,
      (v) => pulse2.reload = v,
      isPulse1: false,
    );
  }

  APUState saveState() => APUState(
    globalTime: globalTime,
    frameCounterMode: frameCounterMode,
    irqDisable: irqDisable,
    frameIrq: frameIrq,
    frameStep: _frameStep,
    pulse1State: pulse1.saveState(),
    pulse2State: pulse2.saveState(),
    triangleState: triangle.saveState(),
    noiseState: noise.saveState(),
    dmcState: dmc.saveState(),
  );

  void restoreState(APUState state) {
    globalTime = state.globalTime;
    frameCounterMode = state.frameCounterMode;
    irqDisable = state.irqDisable;
    frameIrq = state.frameIrq;
    _frameStep = state.frameStep;

    pulse1.restoreState(state.pulse1State);
    pulse2.restoreState(state.pulse2State);
    triangle.restoreState(state.triangleState);
    noise.restoreState(state.noiseState);
    dmc.restoreState(state.dmcState);

    _highPassPrev = 0;
    _highPassOut = 0;
    _lowPassPrev = 0;
  }
}

class Sequencer {
  int sequence = 0;
  int timer = 0;
  int reload = 0;
  int output = 0;

  int clock({required bool enable, required int Function(int) func}) {
    if (enable) {
      timer--;

      if (timer == -1) {
        timer = reload;
        sequence = func(sequence);
        output = sequence & 0x01;
      }
    }

    return output;
  }
}

class Envelope {
  bool start = false;
  bool disable = false;
  int dividerCount = 0;
  int volume = 0;
  int output = 0;
  int decayCount = 0;
  bool loop = false;

  void clock() {
    if (start) {
      start = false;
      decayCount = 0x0F;
      dividerCount = volume;
    } else {
      if (dividerCount == 0) {
        dividerCount = volume;
        if (decayCount == 0) {
          if (loop) {
            decayCount = 0x0F;
          }
        } else {
          decayCount--;
        }
      } else {
        dividerCount--;
      }
    }

    output = disable ? volume : decayCount;
  }

  EnvelopeState saveState() => EnvelopeState(
    start: start,
    disable: disable,
    dividerCount: dividerCount,
    volume: volume,
    output: output,
    decayCount: decayCount,
    loop: loop,
  );

  void restoreState(EnvelopeState state) {
    start = state.start;
    disable = state.disable;
    dividerCount = state.dividerCount;
    volume = state.volume;
    output = state.output;
    decayCount = state.decayCount;
    loop = state.loop;
  }
}

class LengthCounter {
  int counter = 0;
  bool halt = false;

  static const List<int> lengthTable = [
    0x0A,
    0xFE,
    0x14,
    0x02,
    0x28,
    0x04,
    0x50,
    0x06,
    0xA0,
    0x08,
    0x3C,
    0x0A,
    0x0E,
    0x0C,
    0x1A,
    0x0E,
    0x0C,
    0x10,
    0x18,
    0x12,
    0x30,
    0x14,
    0x60,
    0x16,
    0xC0,
    0x18,
    0x48,
    0x1A,
    0x10,
    0x1C,
    0x20,
    0x1E,
  ];

  void load(int index) {
    if (index < lengthTable.length) {
      counter = lengthTable[index];
    }
  }

  void clock() {
    if (!halt && counter > 0) {
      counter--;
    }
  }

  LengthCounterState saveState() => LengthCounterState(
    counter: counter,
    halt: halt,
  );

  void restoreState(LengthCounterState state) {
    counter = state.counter;
    halt = state.halt;
  }
}

class PulseWave {
  double dutycycle = 0.5;
  int timer = 0;
  int reload = 0;
  int phase = 0;
  bool enable = false;

  final Envelope envelope = Envelope();
  final LengthCounter lengthCounter = LengthCounter();
  final Sweeper sweeper = Sweeper();

  void clock() {
    if (timer == 0) {
      timer = reload;
      phase = (phase + 1) & 0x07;
    } else {
      timer--;
    }
  }

  void reset() {
    timer = 0;
    reload = 0;
    phase = 0;
    enable = false;
    dutycycle = 0.5;
    envelope.disable = false;
    envelope.start = false;
    envelope.loop = false;
    envelope.volume = 0;
    lengthCounter.counter = 0;
    lengthCounter.halt = false;
    sweeper.enabled = false;
    sweeper.period = 0;
    sweeper.down = false;
    sweeper.shift = 0;
    sweeper.reload = false;
  }

  int output() {
    if (!enable ||
        lengthCounter.counter == 0 ||
        reload < 0x08 ||
        sweeper.mute) {
      return 0;
    }

    final duty = (dutycycle * 8).clamp(0, 3).toInt();

    return APU._dutySequences[duty][phase] * envelope.output;
  }

  void _updateSweepSilencing() {
    final offset = reload >> sweeper.shift;
    sweeper.mute =
        (reload < 8) || (!sweeper.down && ((reload + offset) > 0x7FF));
  }

  PulseWaveState saveState() => PulseWaveState(
    enable: enable,
    dutycycle: dutycycle,
    timer: timer,
    reload: reload,
    phase: phase,
    envelopeState: envelope.saveState(),
    lengthCounterState: lengthCounter.saveState(),
    sweeperState: sweeper.saveState(),
  );

  void restoreState(PulseWaveState state) {
    enable = state.enable;
    dutycycle = state.dutycycle;
    timer = state.timer;
    reload = state.reload;
    phase = state.phase;

    envelope.restoreState(state.envelopeState);
    lengthCounter.restoreState(state.lengthCounterState);
    sweeper.restoreState(state.sweeperState);
  }
}

class Sweeper {
  bool enabled = false;
  bool down = false;
  bool reload = false;
  int shift = 0;
  int timer = 0;
  int period = 0;
  int change = 0;
  bool mute = false;

  void clock(
    int target,
    void Function(int) setTarget, {
    required bool isPulse1,
  }) {
    if (timer == 0 && enabled) {
      timer = period;

      final changeAmount = target >> shift;
      int newPeriod;

      if (down) {
        newPeriod = target - changeAmount - (isPulse1 ? 1 : 0);
      } else {
        newPeriod = target + changeAmount;
      }

      if (shift > 0 && newPeriod >= 0 && newPeriod <= 0x7FF) {
        setTarget(newPeriod);
      }
    } else if (timer > 0) {
      timer--;
    }

    if (reload) {
      timer = period;
      reload = false;
    }

    mute = (target < 8) || (target > 0x7FF);

    if (!down && shift > 0) {
      final futureValue = target + (target >> shift);
      if (futureValue > 0x7FF) mute = true;
    }
  }

  SweeperState saveState() => SweeperState(
    enabled: enabled,
    down: down,
    reload: reload,
    shift: shift,
    timer: timer,
    period: period,
    mute: mute,
  );

  void restoreState(SweeperState state) {
    enabled = state.enabled;
    down = state.down;
    reload = state.reload;
    shift = state.shift;
    timer = state.timer;
    period = state.period;
    mute = state.mute;
  }
}

class LinearCounter {
  int counter = 0;
  int reload = 0;
  bool controlFlag = false;
  bool reloadFlag = false;

  void load(int value) => reload = value;

  void setReloadFlag() => reloadFlag = true;

  void clock() {
    if (reloadFlag) {
      counter = reload;
    } else if (counter > 0) {
      counter--;
    }

    if (!controlFlag) reloadFlag = false;
  }

  LinearCounterState saveState() => LinearCounterState(
    counter: counter,
    reload: reload,
    controlFlag: controlFlag,
    reloadFlag: reloadFlag,
  );

  void restoreState(LinearCounterState state) {
    counter = state.counter;
    reload = state.reload;
    controlFlag = state.controlFlag;
    reloadFlag = state.reloadFlag;
  }
}

class TriangleWave {
  static const List<int> _sequence = [
    0x0F,
    0x0E,
    0x0D,
    0x0C,
    0x0B,
    0x0A,
    0x09,
    0x08,
    0x07,
    0x06,
    0x05,
    0x04,
    0x03,
    0x02,
    0x01,
    0x00,
    0x00,
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08,
    0x09,
    0x0A,
    0x0B,
    0x0C,
    0x0D,
    0x0E,
    0x0F,
  ];

  int timer = 0;
  int reload = 0;
  int phase = 0;
  bool enable = false;

  final LengthCounter lengthCounter = LengthCounter();
  final LinearCounter linearCounter = LinearCounter();

  void clock() {
    if (linearCounter.counter > 0 && lengthCounter.counter > 0) {
      if (timer == 0) {
        timer = reload;
        phase = (phase + 1) & 0x1F;
      } else {
        timer--;
      }
    }
  }

  void reset() {
    timer = 0;
    reload = 0;
    phase = 0;
    enable = false;
    lengthCounter.counter = 0;
    lengthCounter.halt = false;
    linearCounter.counter = 0;
    linearCounter.reload = 0;
    linearCounter.controlFlag = false;
  }

  int output() {
    if (!enable || lengthCounter.counter == 0 || linearCounter.counter == 0) {
      return 0;
    }

    return _sequence[phase];
  }

  TriangleWaveState saveState() => TriangleWaveState(
    enable: enable,
    timer: timer,
    reload: reload,
    phase: phase,
    lengthCounterState: lengthCounter.saveState(),
    linearCounterState: linearCounter.saveState(),
  );

  void restoreState(TriangleWaveState state) {
    enable = state.enable;
    timer = state.timer;
    reload = state.reload;
    phase = state.phase;

    lengthCounter.restoreState(state.lengthCounterState);
    linearCounter.restoreState(state.linearCounterState);
  }
}

class NoiseWave {
  int timer = 0;
  int reload = 0;
  int shiftRegister = 0x0001;
  bool mode = false;
  bool enable = false;

  final Envelope envelope = Envelope();
  final LengthCounter lengthCounter = LengthCounter();

  void clock() {
    if (timer == 0) {
      timer = reload;
      final bit0 = shiftRegister & 0x0001;
      final bit = mode
          ? (shiftRegister >> 6) & 0x01
          : (shiftRegister >> 1) & 0x01;
      final feedback = bit0 ^ bit;
      shiftRegister = (shiftRegister >> 1) | (feedback << 14);
    } else {
      timer--;
    }
  }

  void reset() {
    timer = 0;
    reload = 0;
    shiftRegister = 0x0001;
    mode = false;
    enable = false;
    envelope.disable = false;
    envelope.start = false;
    envelope.loop = false;
    envelope.volume = 0;
    lengthCounter.counter = 0;
    lengthCounter.halt = false;
  }

  int output() {
    if (!enable || lengthCounter.counter == 0) return 0;
    if ((shiftRegister & 1) == 0) return envelope.output;

    return 0;
  }

  NoiseWaveState saveState() => NoiseWaveState(
    enable: enable,
    mode: mode,
    timer: timer,
    reload: reload,
    shiftRegister: shiftRegister,
    envelopeState: envelope.saveState(),
    lengthCounterState: lengthCounter.saveState(),
  );

  void restoreState(NoiseWaveState state) {
    enable = state.enable;
    mode = state.mode;
    timer = state.timer;
    reload = state.reload;
    shiftRegister = state.shiftRegister;

    envelope.restoreState(state.envelopeState);
    lengthCounter.restoreState(state.lengthCounterState);
  }
}

class DMC {
  int timerCounter = 0;
  int timerLoad = 0;
  int outputShift = 0;
  int dmcOutput = 0;
  int bitsRemaining = 0;
  int currentAddress = 0;
  int sampleAddress = 0;
  int sampleLength = 0;
  bool enable = false;
  bool irqEnabled = false;
  bool irqFlag = false;
  bool loop = false;
  bool sampleBufferEmpty = true;
  int sampleBuffer = 0;
  bool silence = true;
  int duration = 0;

  void clock() {
    if (!enable) return;

    if (timerCounter == 0) {
      timerCounter = timerLoad;

      if (!silence) {
        if (outputShift & 0x01 != 0) {
          if (dmcOutput < 126) dmcOutput += 2;
        } else {
          if (dmcOutput > 1) dmcOutput -= 2;
        }
      }

      outputShift >>= 1;
      if (--bitsRemaining == 0) {
        bitsRemaining = 8;
        if (sampleBufferEmpty) {
          silence = true;
        } else {
          outputShift = sampleBuffer;
          sampleBufferEmpty = true;
          _fillSampleBuffer();
          silence = false;
        }
      }
    } else {
      timerCounter--;
    }
  }

  void _fillSampleBuffer() {
    if (sampleBufferEmpty && duration > 0) {
      sampleBufferEmpty = false;

      if (--duration == 0) {
        if (loop) {
          currentAddress = sampleAddress;
          duration = sampleLength;
        } else {
          if (irqEnabled) irqFlag = true;
        }
      }
    }
  }

  void enableDMC(int startAddress, int length) {
    if (duration == 0) {
      currentAddress = startAddress;
      duration = length;
      sampleBufferEmpty = true;
      _fillSampleBuffer();
      enable = true;
    }
  }

  void disableDMC() {
    enable = false;
    duration = 0;
  }

  void reset() {
    timerCounter = 0;
    timerLoad = 0;
    outputShift = 0;
    dmcOutput = 0;
    bitsRemaining = 1;
    currentAddress = 0;
    sampleAddress = 0;
    sampleLength = 0;
    enable = false;
    irqEnabled = false;
    irqFlag = false;
    loop = false;
    sampleBufferEmpty = true;
    sampleBuffer = 0;
    silence = true;
    duration = 0;
  }

  int output() => dmcOutput;

  DMCState saveState() => DMCState(
    enable: enable,
    irqEnabled: irqEnabled,
    loop: loop,
    timerLoad: timerLoad,
    timer: timerCounter,
    dmcOutput: dmcOutput,
    sampleAddress: sampleAddress,
    currentAddress: currentAddress,
    bytesRemaining: duration,
    sampleBuffer: sampleBuffer,
    sampleBufferEmpty: sampleBufferEmpty,
    shiftRegister: outputShift,
    bitsRemaining: bitsRemaining,
    silenceFlag: silence,
  );

  void restoreState(DMCState state) {
    enable = state.enable;
    irqEnabled = state.irqEnabled;
    loop = state.loop;
    timerLoad = state.timerLoad;
    timerCounter = state.timer;
    dmcOutput = state.dmcOutput;
    sampleAddress = state.sampleAddress;
    currentAddress = state.currentAddress;
    duration = state.bytesRemaining;
    sampleBuffer = state.sampleBuffer;
    sampleBufferEmpty = state.sampleBufferEmpty;
    outputShift = state.shiftRegister;
    bitsRemaining = state.bitsRemaining;
    silence = state.silenceFlag;
  }
}
