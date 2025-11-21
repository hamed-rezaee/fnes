class APU {
  APU();

  static const List<List<int>> _dutySequences = [
    [0, 1, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 0, 0, 0],
    [1, 0, 0, 1, 1, 1, 1, 1],
  ];

  static const double _highPassCoeff = 0.99925;
  static const double _lowPassInput = 0.8;
  static const double _lowPassFeedback = 0.2;

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
        pulse1.sweeper.period = (data >> 4) & 0x07;
        pulse1.sweeper.down = (data & 0x08) != 0;
        pulse1.sweeper.shift = data & 0x07;
        pulse1.sweeper.reload = true;
      case 0x4002:
        pulse1.reload = (pulse1.reload & 0xFF00) | data;
      case 0x4003:
        pulse1.reload = (pulse1.reload & 0x00FF) | ((data & 0x07) << 8);
        pulse1.timer = pulse1.reload;
        pulse1.lengthCounter.load(data >> 3);
        pulse1.envelope.start = true;
        pulse1.phase = 0;
      case 0x4004:
        pulse2.dutycycle = ((data >> 6) & 0x03) / 8.0;
        pulse2.envelope.loop = (data & 0x20) != 0;
        pulse2.envelope.disable = (data & 0x10) != 0;
        pulse2.envelope.volume = data & 0x0F;
        pulse2.lengthCounter.halt = (data & 0x20) != 0;
      case 0x4005:
        pulse2.sweeper.enabled = (data & 0x80) != 0;
        pulse2.sweeper.period = (data >> 4) & 0x07;
        pulse2.sweeper.down = (data & 0x08) != 0;
        pulse2.sweeper.shift = data & 0x07;
        pulse2.sweeper.reload = true;
      case 0x4006:
        pulse2.reload = (pulse2.reload & 0xFF00) | data;
      case 0x4007:
        pulse2.reload = (pulse2.reload & 0x00FF) | ((data & 0x07) << 8);
        pulse2.timer = pulse2.reload;
        pulse2.lengthCounter.load(data >> 3);
        pulse2.envelope.start = true;
        pulse2.phase = 0;
      case 0x4008:
        triangle.linearCounter.controlFlag = (data & 0x80) != 0;
        triangle.linearCounter.reload = data & 0x7F;
      case 0x400A:
        triangle.reload = (triangle.reload & 0xFF00) | data;
      case 0x400B:
        triangle.reload = (triangle.reload & 0x00FF) | ((data & 0x07) << 8);
        triangle.timer = triangle.reload;
        triangle.lengthCounter.load(data >> 3);
        triangle.linearCounter.controlFlag = true;
      case 0x400C:
        noise.envelope.loop = (data & 0x20) != 0;
        noise.envelope.disable = (data & 0x10) != 0;
        noise.envelope.volume = data & 0x0F;
        noise.lengthCounter.halt = (data & 0x20) != 0;
      case 0x400E:
        noise.mode = (data & 0x80) != 0;
        noise.reload = [
          4,
          8,
          16,
          32,
          64,
          96,
          128,
          160,
          202,
          254,
          380,
          508,
          762,
          1016,
          2034,
          4068,
        ][(data & 0x0F)];
      case 0x400F:
        noise.lengthCounter.load(data >> 3);
        noise.envelope.start = true;
      case 0x4010:
        dmc.irqEnabled = (data & 0x80) != 0;
        dmc.loop = (data & 0x40) != 0;
        dmc.timerLoad = [
          428,
          380,
          340,
          320,
          286,
          254,
          226,
          214,
          190,
          160,
          142,
          128,
          106,
          84,
          72,
          54,
        ][(data & 0x0F)];
      case 0x4011:
        dmc.dmcOutput = data & 0x7F;
      case 0x4012:
        dmc.sampleAddress = 0xC000 + (data * 64);
      case 0x4013:
        dmc.bytesRemaining = (data * 16) + 1;
      case 0x4015:
        pulse1.enable = (data & 0x01) != 0;
        pulse2.enable = (data & 0x02) != 0;
        triangle.enable = (data & 0x04) != 0;
        noise.enable = (data & 0x08) != 0;
        dmc.enable = (data & 0x10) != 0;
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
      data |= (dmc.bytesRemaining > 0 ? 0x10 : 0);
      data |= (frameIrq ? 0x40 : 0);

      frameIrq = false;
    }

    return data;
  }

  double _highPassPrev = 0;
  double _highPassOut = 0;

  double _lowPassPrev = 0;

  double getOutputSample() {
    final p1 = pulse1.output();
    final p2 = pulse2.output();
    final tri = triangle.output();
    final noi = noise.output();
    final dmcOut = dmc.output();

    double pulseOut = 0;
    final pulseSum = p1 + p2;
    if (pulseSum > 0) {
      pulseOut = 95.88 / ((8128.0 / pulseSum) + 100.0);
    }

    double tnd = 0;
    final tndSum = tri + noi + dmcOut;
    if (tndSum > 0) {
      tnd = 163.67 / ((24329.0 / tndSum) + 100.0);
    }

    var sample = pulseOut + tnd;

    _highPassOut = sample - _highPassPrev + _highPassCoeff * _highPassOut;
    _highPassPrev = sample;
    sample = _highPassOut;

    sample = _lowPassInput * sample + _lowPassFeedback * _lowPassPrev;
    _lowPassPrev = sample;

    return (sample * 100).clamp(-1.0, 1.0);
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
      if (globalTime == 3729 ||
          globalTime == 7457 ||
          globalTime == 11185 ||
          globalTime == 14913 ||
          globalTime == 18641) {
        globalTime = 0;
        _clockFrameCounter();
      }
    } else {
      if (globalTime == 3729 ||
          globalTime == 7457 ||
          globalTime == 11185 ||
          globalTime == 14914) {
        if (globalTime == 14914) globalTime = 0;
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
    _frameStep++;
    if (frameCounterMode) {
      if (_frameStep > 5) _frameStep = 1;
      if (_frameStep == 1 || _frameStep == 3) {
        _clockEnvelopes();
        _clockLinearCounter();
      }
      if (_frameStep == 2 || _frameStep == 4 || _frameStep == 5) {
        _clockEnvelopes();
        _clockLinearCounter();
        _clockLengthCounters();
        _clockSweepers();
      }
    } else {
      if (_frameStep > 4) _frameStep = 1;
      if (_frameStep == 1 || _frameStep == 3) {
        _clockEnvelopes();
        _clockLinearCounter();
      }
      if (_frameStep == 2 || _frameStep == 4) {
        _clockEnvelopes();
        _clockLinearCounter();
        _clockLengthCounters();
        _clockSweepers();
        if (_frameStep == 4 && !irqDisable) {
          frameIrq = true;
        }
      }
    }
  }

  void _clockEnvelopes() {
    pulse1.envelope.clock();
    pulse2.envelope.clock();
    noise.envelope.clock();
  }

  void _clockLinearCounter() {
    triangle.linearCounter.clock();
  }

  void _clockLengthCounters() {
    pulse1.lengthCounter.clock();
    pulse2.lengthCounter.clock();
    triangle.lengthCounter.clock();
    noise.lengthCounter.clock();
  }

  void _clockSweepers() {
    pulse1.sweeper
        .clock(pulse1.reload, (v) => pulse1.reload = v, isPulse1: true);
    pulse2.sweeper
        .clock(pulse2.reload, (v) => pulse2.reload = v, isPulse1: false);
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
      decayCount = 15;
      dividerCount = volume;
    } else {
      if (dividerCount == 0) {
        dividerCount = volume;
        if (decayCount == 0) {
          if (loop) {
            decayCount = 15;
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
}

class LengthCounter {
  int counter = 0;
  bool halt = false;

  static const List<int> lengthTable = [
    10,
    254,
    20,
    2,
    40,
    4,
    80,
    6,
    160,
    8,
    60,
    10,
    14,
    12,
    26,
    14,
    12,
    16,
    24,
    18,
    48,
    20,
    96,
    22,
    192,
    24,
    72,
    26,
    16,
    28,
    32,
    30,
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

  double output() {
    if (!enable || lengthCounter.counter == 0 || reload < 8 || sweeper.mute) {
      return 0;
    }

    final duty = ((dutycycle * 8).toInt() - 1).clamp(0, 3);
    return (APU._dutySequences[duty][phase] & envelope.output) / 16.0;
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
    var targetValue = target;

    final changeAmount = targetValue >> shift;
    mute = (targetValue < 8) || (targetValue > 0x7FF);

    if (timer == 0 && reload) {
      timer = period;
      reload = false;
    }

    if (timer == 0 && enabled && shift > 0 && !mute) {
      if (down) {
        targetValue -= changeAmount;
        if (isPulse1) {
          targetValue -= 1;
        }
      } else {
        targetValue += changeAmount;
      }

      if (targetValue >= 0 && targetValue <= 0x7FF) {
        setTarget(targetValue);
      } else {
        mute = true;
      }
    }

    if (timer == 0) {
      timer = period;
    } else {
      timer--;
    }
  }
}

class LinearCounter {
  int counter = 0;
  int reload = 0;
  bool controlFlag = false;

  void load(int value) {
    reload = value;
  }

  void clock() {
    if (controlFlag) {
      counter = reload;
    } else if (counter > 0) {
      counter--;
    }

    controlFlag = false;
  }
}

class TriangleWave {
  static const List<int> _sequence = [
    15,
    14,
    13,
    12,
    11,
    10,
    9,
    8,
    7,
    6,
    5,
    4,
    3,
    2,
    1,
    0,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
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

  double output() {
    if (!enable || lengthCounter.counter == 0 || linearCounter.counter == 0) {
      return 0;
    }

    return _sequence[phase] / 16.0;
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
      final bit =
          mode ? (shiftRegister >> 6) & 0x01 : (shiftRegister >> 1) & 0x01;
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

  double output() {
    if (!enable || lengthCounter.counter == 0 || (shiftRegister & 1) == 1) {
      return 0;
    }
    return envelope.output / 16.0;
  }
}

class DMC {
  int timerCounter = 0;
  int timerLoad = 0;
  int sampleBuffer = 0;
  int sampleBufferBits = 0;
  int dmcOutput = 0;
  int bitsRemaining = 0;
  int bytesRemaining = 0;
  int currentAddress = 0;
  int sampleAddress = 0;
  bool enable = false;
  bool irqEnabled = false;
  bool loop = false;
  bool sampleBufferEmpty = true;

  void clock() {
    if (!enable) return;

    if (timerCounter == 0) {
      timerCounter = timerLoad;

      if (bitsRemaining > 0) {
        bitsRemaining--;
        final bit = (sampleBuffer >> bitsRemaining) & 1;
        if (bit == 1) {
          if (dmcOutput < 126) dmcOutput += 2;
        } else {
          if (dmcOutput > 1) dmcOutput -= 2;
        }
      } else if (!sampleBufferEmpty) {
        sampleBuffer = sampleBufferBits;
        sampleBufferEmpty = true;
        bitsRemaining = 8;
      }
    } else {
      timerCounter--;
    }
  }

  void reset() {
    timerCounter = 0;
    timerLoad = 0;
    sampleBuffer = 0;
    sampleBufferBits = 0;
    dmcOutput = 0;
    bitsRemaining = 0;
    bytesRemaining = 0;
    currentAddress = 0;
    sampleAddress = 0;
    enable = false;
    irqEnabled = false;
    loop = false;
    sampleBufferEmpty = true;
  }

  double output() => dmcOutput / 127.0;
}
