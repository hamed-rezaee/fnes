import 'package:fnes/components/emulator_state.dart';
import 'package:fnes/core/event.dart';

class APU {
  int Function(int address)? dmcMemoryRead;
  EventBus? eventBus;

  static const List<List<int>> _dutySequences = [
    [0, 1, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 0, 0, 0],
    [1, 0, 0, 1, 1, 1, 1, 1],
  ];

  static const double _highPassCoeff = 0.999835;
  static const double _lowPassInput = 0.815686;
  static const double _lowPassFeedback = 0.184314;
  static const double _pulseGain = 2.5;

  int globalTime = 0;
  bool frameCounterMode = false;
  bool irqDisable = false;
  bool frameIrq = false;

  final PulseWave pulse1 = PulseWave();
  final PulseWave pulse2 = PulseWave();
  final TriangleWave triangle = TriangleWave();
  final NoiseWave noise = NoiseWave();
  final DMC dmc = DMC();

  static const List<int> _noiseTimerNTSC = [
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
  ];

  static const List<int> _noiseTimerPAL = [
    0x004,
    0x008,
    0x00E,
    0x01E,
    0x03C,
    0x058,
    0x076,
    0x094,
    0x0BC,
    0x0EC,
    0x162,
    0x1D8,
    0x2C4,
    0x3B0,
    0x762,
    0xEC4,
  ];

  static const List<int> _dmcTimerNTSC = [
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
  ];

  static const List<int> _dmcTimerPAL = [
    0x18E,
    0x162,
    0x13C,
    0x12A,
    0x114,
    0x0EC,
    0x0D2,
    0x0C6,
    0x0B0,
    0x094,
    0x084,
    0x076,
    0x062,
    0x04E,
    0x042,
    0x032,
  ];

  bool _isPal = false;

  @pragma('vm:prefer-inline')
  void setSystemType({required bool isPal}) => _isPal = isPal;

  void cpuWrite(int address, int data) {
    switch (address) {
      case 0x4000:
        pulse1.dutyIndex = (data >> 6) & 0x03;
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
        pulse2.dutyIndex = (data >> 6) & 0x03;
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
        triangle.lengthCounter.halt = (data & 0x80) != 0;
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
        noise.reload = (_isPal
            ? _noiseTimerPAL
            : _noiseTimerNTSC)[(data & 0x0F)];
      case 0x400F:
        noise.lengthCounter.load(data >> 3);
        noise.envelope.start = true;
      case 0x4010:
        dmc.irqEnabled = (data & 0x80) != 0;

        if (!dmc.irqEnabled) dmc.irqFlag = false;

        dmc.loop = (data & 0x40) != 0;
        dmc.timerLoad = (_isPal ? _dmcTimerPAL : _dmcTimerNTSC)[(data & 0x0F)];
      case 0x4011:
        dmc.dmcOutput = data & 0x7F;
      case 0x4012:
        dmc.sampleAddress = 0xC000 + (data * 0x40);
      case 0x4013:
        dmc.sampleLength = (data * 0x10) + 1;
      case 0x4015:
        pulse1.enable = (data & 0x01) != 0;
        if (!pulse1.enable) pulse1.lengthCounter.counter = 0;

        pulse2.enable = (data & 0x02) != 0;
        if (!pulse2.enable) pulse2.lengthCounter.counter = 0;

        triangle.enable = (data & 0x04) != 0;
        if (!triangle.enable) triangle.lengthCounter.counter = 0;

        noise.enable = (data & 0x08) != 0;
        if (!noise.enable) noise.lengthCounter.counter = 0;

        if ((data & 0x10) != 0) {
          if (dmc.duration == 0) {
            dmc.currentAddress = dmc.sampleAddress;
            dmc.duration = dmc.sampleLength;
          }
        } else {
          dmc.duration = 0;
          dmc.irqFlag = false;
        }
      case 0x4017:
        frameCounterMode = (data & 0x80) != 0;
        irqDisable = (data & 0x40) != 0;
        if (irqDisable) frameIrq = false;

        globalTime = 0;
        _frameStep = 0;

        if (frameCounterMode) {
          _clockEnvelopes();
          _clockLengthCounters();
          _clockSweepers();
        }
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
      data |= (dmc.irqFlag ? 0x80 : 0);

      frameIrq = false;
    }

    return data;
  }

  double _highPassPrev = 0;
  double _highPassOut = 0;
  double _lowPassPrev = 0;

  static final List<double> _pulseLookup = List.generate(
    31,
    (i) => (i == 0) ? 0.0 : 95.52 / (8128.0 / i + 100.0),
  );

  static final List<double> _tndLookup = List.generate(
    203,
    (i) => (i == 0) ? 0.0 : 163.67 / (24329.0 / i + 100.0),
  );

  @pragma('vm:prefer-inline')
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

  static const int _fcStep1NTSC = 7457;
  static const int _fcStep2NTSC = 14913;
  static const int _fcStep3NTSC = 22371;
  static const int _fcStep4NTSC = 29828;
  static const int _fcStep5NTSC = 37281;

  static const int _fcStep1PAL = 8314;
  static const int _fcStep2PAL = 16628;
  static const int _fcStep3PAL = 24940;
  static const int _fcStep4PAL = 33254;
  static const int _fcStep5PAL = 41566;

  @pragma('vm:prefer-inline')
  void clock() {
    final s1 = _isPal ? _fcStep1PAL : _fcStep1NTSC;
    final s2 = _isPal ? _fcStep2PAL : _fcStep2NTSC;
    final s3 = _isPal ? _fcStep3PAL : _fcStep3NTSC;
    final s4 = _isPal ? _fcStep4PAL : _fcStep4NTSC;
    final s5 = _isPal ? _fcStep5PAL : _fcStep5NTSC;

    if (frameCounterMode) {
      if (globalTime == s1) {
        _clockEnvelopes();
      } else if (globalTime == s2) {
        _clockEnvelopes();
        _clockLengthCounters();
        _clockSweepers();
      } else if (globalTime == s3) {
        _clockEnvelopes();
      } else if (globalTime == s4) {
      } else if (globalTime == s5) {
        _clockEnvelopes();
        _clockLengthCounters();
        _clockSweepers();
        globalTime = -1;
      }
    } else {
      if (globalTime == s1) {
        _clockEnvelopes();
      } else if (globalTime == s2) {
        _clockEnvelopes();
        _clockLengthCounters();
        _clockSweepers();
      } else if (globalTime == s3) {
        _clockEnvelopes();
      } else if (globalTime == s4 + 1) {
        _clockEnvelopes();
        _clockLengthCounters();
        _clockSweepers();
        if (!irqDisable) frameIrq = true;
      } else if (globalTime == s4 + 2) {
        if (!irqDisable) frameIrq = true;
        globalTime = -1;
      }
    }

    globalTime++;

    if ((globalTime & 1) == 0) {
      pulse1.clock();
      pulse2.clock();
      noise.clock();
    }

    triangle.clock();

    dmc.clock(dmcMemoryRead);
  }

  int _frameStep = 0;

  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
  EnvelopeState saveState() => EnvelopeState(
    start: start,
    disable: disable,
    dividerCount: dividerCount,
    volume: volume,
    output: output,
    decayCount: decayCount,
    loop: loop,
  );

  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
  void load(int index) {
    if (index < lengthTable.length) {
      counter = lengthTable[index];
    }
  }

  @pragma('vm:prefer-inline')
  void clock() {
    if (!halt && counter > 0) {
      counter--;
    }
  }

  @pragma('vm:prefer-inline')
  LengthCounterState saveState() => LengthCounterState(
    counter: counter,
    halt: halt,
  );

  @pragma('vm:prefer-inline')
  void restoreState(LengthCounterState state) {
    counter = state.counter;
    halt = state.halt;
  }
}

class PulseWave {
  bool debugEnable = true;
  int dutyIndex = 0;
  int timer = 0;
  int reload = 0;
  int phase = 0;
  bool enable = false;

  final Envelope envelope = Envelope();
  final LengthCounter lengthCounter = LengthCounter();
  final Sweeper sweeper = Sweeper();

  @pragma('vm:prefer-inline')
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
    dutyIndex = 0;
    envelope.disable = false;
    envelope.start = false;
    envelope.loop = false;
    envelope.volume = 0;
    envelope.dividerCount = 0;
    envelope.decayCount = 0;
    lengthCounter.counter = 0;
    lengthCounter.halt = false;
    sweeper.enabled = false;
    sweeper.period = 0;
    sweeper.down = false;
    sweeper.shift = 0;
    sweeper.reload = false;
    sweeper.timer = 0;
    sweeper.mute = false;
  }

  @pragma('vm:prefer-inline')
  int output() {
    if (!debugEnable ||
        !enable ||
        lengthCounter.counter == 0 ||
        reload < 0x08 ||
        sweeper.mute) {
      return 0;
    }

    return APU._dutySequences[dutyIndex][phase] * envelope.output;
  }

  @pragma('vm:prefer-inline')
  void _updateSweepSilencing() {
    final offset = reload >> sweeper.shift;
    sweeper.mute =
        (reload < 8) || (!sweeper.down && ((reload + offset) > 0x7FF));
  }

  @pragma('vm:prefer-inline')
  PulseWaveState saveState() => PulseWaveState(
    enable: enable,
    dutycycle: dutyIndex.toDouble(),
    timer: timer,
    reload: reload,
    phase: phase,
    envelopeState: envelope.saveState(),
    lengthCounterState: lengthCounter.saveState(),
    sweeperState: sweeper.saveState(),
  );

  @pragma('vm:prefer-inline')
  void restoreState(PulseWaveState state) {
    enable = state.enable;
    dutyIndex = state.dutycycle.round();
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
    if (timer == 0 && enabled && shift > 0 && !mute) {
      final changeAmount = target >> shift;
      int newPeriod;

      if (down) {
        newPeriod = target - changeAmount - (isPulse1 ? 1 : 0);
      } else {
        newPeriod = target + changeAmount;
      }

      if (newPeriod >= 0 && newPeriod <= 0x7FF) {
        setTarget(newPeriod);
      }
      _updateMute(newPeriod, isPulse1);
    }

    if (timer == 0 || reload) {
      timer = period;
      reload = false;
    } else {
      timer--;
    }

    _updateMute(target, isPulse1);
  }

  @pragma('vm:prefer-inline')
  void _updateMute(int target, bool isPulse1) {
    if (target < 8) {
      mute = true;
      return;
    }

    if (!down && shift > 0) {
      final futureValue = target + (target >> shift);
      mute = futureValue > 0x7FF;
    } else {
      mute = false;
    }
  }

  @pragma('vm:prefer-inline')
  SweeperState saveState() => SweeperState(
    enabled: enabled,
    down: down,
    reload: reload,
    shift: shift,
    timer: timer,
    period: period,
    mute: mute,
  );

  @pragma('vm:prefer-inline')
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

  @pragma('vm:prefer-inline')
  void load(int value) => reload = value;

  @pragma('vm:prefer-inline')
  void setReloadFlag() => reloadFlag = true;

  @pragma('vm:prefer-inline')
  void clock() {
    if (reloadFlag) {
      counter = reload;
    } else if (counter > 0) {
      counter--;
    }

    if (!controlFlag) reloadFlag = false;
  }

  @pragma('vm:prefer-inline')
  LinearCounterState saveState() => LinearCounterState(
    counter: counter,
    reload: reload,
    controlFlag: controlFlag,
    reloadFlag: reloadFlag,
  );

  @pragma('vm:prefer-inline')
  void restoreState(LinearCounterState state) {
    counter = state.counter;
    reload = state.reload;
    controlFlag = state.controlFlag;
    reloadFlag = state.reloadFlag;
  }
}

class TriangleWave {
  bool debugEnable = true;
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

  @pragma('vm:prefer-inline')
  void clock() {
    if (timer == 0) {
      timer = reload;

      if (reload >= 2 &&
          linearCounter.counter > 0 &&
          lengthCounter.counter > 0) {
        phase = (phase + 1) & 0x1F;
      }
    } else {
      timer--;
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
    linearCounter.reloadFlag = false;
  }

  @pragma('vm:prefer-inline')
  int output() {
    if (!debugEnable) return 0;
    if (reload < 2) return 7;

    return _sequence[phase];
  }

  @pragma('vm:prefer-inline')
  TriangleWaveState saveState() => TriangleWaveState(
    enable: enable,
    timer: timer,
    reload: reload,
    phase: phase,
    lengthCounterState: lengthCounter.saveState(),
    linearCounterState: linearCounter.saveState(),
  );

  @pragma('vm:prefer-inline')
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
  bool debugEnable = true;
  int timer = 0;
  int reload = 0;
  int shiftRegister = 0x0001;
  bool mode = false;
  bool enable = false;

  final Envelope envelope = Envelope();
  final LengthCounter lengthCounter = LengthCounter();

  @pragma('vm:prefer-inline')
  void clock() {
    if (timer == 0) {
      timer = reload;
      final bit0 = shiftRegister & 0x0001;
      final otherBit = mode
          ? (shiftRegister >> 6) & 0x01
          : (shiftRegister >> 1) & 0x01;
      final feedback = bit0 ^ otherBit;
      shiftRegister = ((shiftRegister >> 1) & 0x3FFF) | (feedback << 14);
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
    envelope.dividerCount = 0;
    envelope.decayCount = 0;
    lengthCounter.counter = 0;
    lengthCounter.halt = false;
  }

  @pragma('vm:prefer-inline')
  int output() {
    if (!debugEnable || !enable || lengthCounter.counter == 0) return 0;
    if ((shiftRegister & 1) == 0) return envelope.output;

    return 0;
  }

  @pragma('vm:prefer-inline')
  NoiseWaveState saveState() => NoiseWaveState(
    enable: enable,
    mode: mode,
    timer: timer,
    reload: reload,
    shiftRegister: shiftRegister,
    envelopeState: envelope.saveState(),
    lengthCounterState: lengthCounter.saveState(),
  );

  @pragma('vm:prefer-inline')
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
  bool debugEnable = true;
  int timerCounter = 0;
  int timerLoad = 0;
  int outputShift = 0;
  int dmcOutput = 0;
  int bitsRemaining = 8;
  int currentAddress = 0;
  int sampleAddress = 0;
  int sampleLength = 0;
  bool irqEnabled = false;
  bool irqFlag = false;
  bool loop = false;
  bool sampleBufferEmpty = true;
  int sampleBuffer = 0;
  bool silence = true;
  int duration = 0;

  @pragma('vm:prefer-inline')
  void clock(int Function(int)? memoryRead) {
    if (sampleBufferEmpty && duration > 0) {
      if (memoryRead != null) {
        sampleBuffer = memoryRead(currentAddress);
      }
      sampleBufferEmpty = false;

      currentAddress = (currentAddress == 0xFFFF) ? 0x8000 : currentAddress + 1;
      duration--;

      if (duration == 0) {
        if (loop) {
          currentAddress = sampleAddress;
          duration = sampleLength;
        } else if (irqEnabled) {
          irqFlag = true;
        }
      }
    }

    if (timerCounter == 0) {
      timerCounter = timerLoad;

      if (!silence) {
        if ((outputShift & 0x01) != 0) {
          if (dmcOutput <= 125) dmcOutput += 2;
        } else {
          if (dmcOutput >= 2) dmcOutput -= 2;
        }
      }

      outputShift >>= 1;
      bitsRemaining--;

      if (bitsRemaining == 0) {
        bitsRemaining = 8;
        if (sampleBufferEmpty) {
          silence = true;
        } else {
          silence = false;
          outputShift = sampleBuffer;
          sampleBufferEmpty = true;
        }
      }
    } else {
      timerCounter--;
    }
  }

  void reset() {
    timerCounter = 0;
    timerLoad = 0x1AC;
    outputShift = 0;
    dmcOutput = 0;
    bitsRemaining = 8;
    currentAddress = 0;
    sampleAddress = 0xC000;
    sampleLength = 1;
    irqEnabled = false;
    irqFlag = false;
    loop = false;
    sampleBufferEmpty = true;
    sampleBuffer = 0;
    silence = true;
    duration = 0;
  }

  @pragma('vm:prefer-inline')
  int output() => (!debugEnable) ? 0 : dmcOutput;

  @pragma('vm:prefer-inline')
  DMCState saveState() => DMCState(
    enable: duration > 0,
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

  @pragma('vm:prefer-inline')
  void restoreState(DMCState state) {
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
