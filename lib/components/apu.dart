class APU {
  APU();

  void cpuWrite(int address, int data) {}

  int cpuRead(int address) => 0;

  double getOutputSample() => 0;

  void reset() {}

  void clock() {}
}

class Sequencer {
  int reload = 0;
  int newSequence = 0;
  int sequence = 0;
  int timer = 0;
  int output = 0;

  void clock() {}
}

class Envelope {
  int volume = 0;
  bool disable = false;
  bool start = false;
  int divider = 0;
  int decayLevel = 0;
  int period = 0;
  int output = 0;

  void clock() {}
}

class LengthCounter {
  int counter = 0;
  bool halt = false;

  void clock() {}
}

class OscPulse {
  double dutycycle = 0.5;
  int timer = 0;
  int reload = 0;
  int phase = 0;

  void clock() {}

  double output() => 0;
}

class Sweeper {
  bool enabled = false;
  int period = 0;
  bool down = false;
  int shift = 0;
  bool reload = false;
  int divider = 0;
  bool mute = false;
  int change = 0;

  void clock() {}
}
