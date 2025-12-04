import 'dart:typed_data';

class EmulatorState {
  EmulatorState({
    required this.cpuState,
    required this.ppuState,
    required this.apuState,
    required this.busState,
    required this.timestamp,
  });

  final CPUState cpuState;
  final PPUState ppuState;
  final APUState apuState;
  final BusState busState;
  final DateTime timestamp;
}

class CPUState {
  CPUState({
    required this.a,
    required this.x,
    required this.y,
    required this.stkp,
    required this.pc,
    required this.status,
    required this.fetched,
    required this.temp,
    required this.addrAbs,
    required this.addrRel,
    required this.opcode,
    required this.cycles,
    required this.clockCount,
  });

  final int a;
  final int x;
  final int y;
  final int stkp;
  final int pc;
  final int status;
  final int fetched;
  final int temp;
  final int addrAbs;
  final int addrRel;
  final int opcode;
  final int cycles;
  final int clockCount;
}

class PPUState {
  PPUState({
    required this.tableData,
    required this.paletteTable,
    required this.patternTable,
    required this.statusReg,
    required this.maskReg,
    required this.controlReg,
    required this.vramAddressReg,
    required this.tempAddressReg,
    required this.fineX,
    required this.addressLatch,
    required this.ppuDataBuffer,
    required this.backgroundNextTileId,
    required this.backgroundNextTileAttrib,
    required this.backgroundNextTileLsb,
    required this.backgroundNextTileMsb,
    required this.backgroundShifterPatternLow,
    required this.backgroundShifterPatternHigh,
    required this.backgroundShifterAttribLow,
    required this.backgroundShifterAttribHigh,
    required this.spriteShifterPatternLow,
    required this.spriteShifterPatternHigh,
    required this.spriteCount,
    required this.spriteZeroHitPossible,
    required this.spriteZeroBeingRendered,
    required this.scanline,
    required this.cycle,
    required this.frameCounter,
    required this.pOAM,
    required this.screenPixels,
    required this.nmi,
    required this.frameComplete,
    required this.spriteScanlineData,
  });

  final Uint8List tableData;
  final Uint8List paletteTable;
  final Uint8List patternTable;
  final int statusReg;
  final int maskReg;
  final int controlReg;
  final int vramAddressReg;
  final int tempAddressReg;
  final int fineX;
  final int addressLatch;
  final int ppuDataBuffer;
  final int backgroundNextTileId;
  final int backgroundNextTileAttrib;
  final int backgroundNextTileLsb;
  final int backgroundNextTileMsb;
  final int backgroundShifterPatternLow;
  final int backgroundShifterPatternHigh;
  final int backgroundShifterAttribLow;
  final int backgroundShifterAttribHigh;
  final List<int> spriteShifterPatternLow;
  final List<int> spriteShifterPatternHigh;
  final int spriteCount;
  final bool spriteZeroHitPossible;
  final bool spriteZeroBeingRendered;
  final int scanline;
  final int cycle;
  final int frameCounter;
  final Uint8List pOAM;
  final List<List<int>> screenPixels;
  final bool nmi;
  final bool frameComplete;
  final List<SpriteScanlineEntry> spriteScanlineData;
}

class SpriteScanlineEntry {
  SpriteScanlineEntry({
    required this.y,
    required this.id,
    required this.attribute,
    required this.x,
  });

  final int y;
  final int id;
  final int attribute;
  final int x;
}

class APUState {
  APUState({
    required this.globalTime,
    required this.frameCounterMode,
    required this.irqDisable,
    required this.frameIrq,
    required this.frameStep,
    required this.pulse1State,
    required this.pulse2State,
    required this.triangleState,
    required this.noiseState,
    required this.dmcState,
  });

  final int globalTime;
  final bool frameCounterMode;
  final bool irqDisable;
  final bool frameIrq;
  final int frameStep;
  final PulseWaveState pulse1State;
  final PulseWaveState pulse2State;
  final TriangleWaveState triangleState;
  final NoiseWaveState noiseState;
  final DMCState dmcState;
}

class PulseWaveState {
  PulseWaveState({
    required this.enable,
    required this.dutycycle,
    required this.timer,
    required this.reload,
    required this.phase,
    required this.envelopeState,
    required this.lengthCounterState,
    required this.sweeperState,
  });

  final bool enable;
  final double dutycycle;
  final int timer;
  final int reload;
  final int phase;
  final EnvelopeState envelopeState;
  final LengthCounterState lengthCounterState;
  final SweeperState sweeperState;
}

class TriangleWaveState {
  TriangleWaveState({
    required this.enable,
    required this.timer,
    required this.reload,
    required this.phase,
    required this.lengthCounterState,
    required this.linearCounterState,
  });

  final bool enable;
  final int timer;
  final int reload;
  final int phase;
  final LengthCounterState lengthCounterState;
  final LinearCounterState linearCounterState;
}

class NoiseWaveState {
  NoiseWaveState({
    required this.enable,
    required this.mode,
    required this.timer,
    required this.reload,
    required this.shiftRegister,
    required this.envelopeState,
    required this.lengthCounterState,
  });

  final bool enable;
  final bool mode;
  final int timer;
  final int reload;
  final int shiftRegister;
  final EnvelopeState envelopeState;
  final LengthCounterState lengthCounterState;
}

class DMCState {
  DMCState({
    required this.enable,
    required this.irqEnabled,
    required this.loop,
    required this.timerLoad,
    required this.timer,
    required this.dmcOutput,
    required this.sampleAddress,
    required this.currentAddress,
    required this.bytesRemaining,
    required this.sampleBuffer,
    required this.sampleBufferEmpty,
    required this.shiftRegister,
    required this.bitsRemaining,
    required this.silenceFlag,
  });

  final bool enable;
  final bool irqEnabled;
  final bool loop;
  final int timerLoad;
  final int timer;
  final int dmcOutput;
  final int sampleAddress;
  final int currentAddress;
  final int bytesRemaining;
  final int sampleBuffer;
  final bool sampleBufferEmpty;
  final int shiftRegister;
  final int bitsRemaining;
  final bool silenceFlag;
}

class EnvelopeState {
  EnvelopeState({
    required this.start,
    required this.disable,
    required this.dividerCount,
    required this.volume,
    required this.output,
    required this.decayCount,
    required this.loop,
  });

  final bool start;
  final bool disable;
  final int dividerCount;
  final int volume;
  final int output;
  final int decayCount;
  final bool loop;
}

class LengthCounterState {
  LengthCounterState({
    required this.counter,
    required this.halt,
  });

  final int counter;
  final bool halt;
}

class SweeperState {
  SweeperState({
    required this.enabled,
    required this.down,
    required this.reload,
    required this.shift,
    required this.timer,
    required this.period,
    required this.mute,
  });

  final bool enabled;
  final bool down;
  final bool reload;
  final int shift;
  final int timer;
  final int period;
  final bool mute;
}

class LinearCounterState {
  LinearCounterState({
    required this.counter,
    required this.reload,
    required this.controlFlag,
    required this.reloadFlag,
  });

  final int counter;
  final int reload;
  final bool controlFlag;
  final bool reloadFlag;
}

class BusState {
  BusState({
    required this.cpuRam,
    required this.controller,
    required this.controllerState,
    required this.systemClockCounter,
    required this.dmaPage,
    required this.dmaAddress,
    required this.dmaData,
    required this.dmaDummy,
    required this.dmaTransfer,
  });

  final Uint8List cpuRam;
  final List<int> controller;
  final List<int> controllerState;
  final int systemClockCounter;
  final int dmaPage;
  final int dmaAddress;
  final int dmaData;
  final bool dmaDummy;
  final bool dmaTransfer;
}

class RewindBuffer {
  RewindBuffer({this.maxFrames = 300});

  final int maxFrames;
  final List<EmulatorState> _states = [];
  int _currentIndex = -1;

  int get length => _states.length;

  bool get canRewind => _states.isNotEmpty;

  int get currentIndex => _currentIndex;

  double get maxRewindSeconds => maxFrames / 60.0;

  double get availableRewindSeconds => _states.length / 60.0;

  void pushState(EmulatorState state) {
    if (_currentIndex >= 0 && _currentIndex < _states.length - 1) {
      _states.removeRange(_currentIndex + 1, _states.length);
    }

    _states.add(state);

    while (_states.length > maxFrames) {
      _states.removeAt(0);
    }

    _currentIndex = _states.length - 1;
  }

  EmulatorState? popState() {
    if (_states.isEmpty) return null;

    final state = _states.removeLast();
    _currentIndex = _states.length - 1;
    return state;
  }

  EmulatorState? getStateAtFramesBack(int framesBack) {
    final targetIndex = _states.length - 1 - framesBack;
    if (targetIndex < 0 || targetIndex >= _states.length) return null;
    return _states[targetIndex];
  }

  EmulatorState? rewindFrames(int frames) {
    if (_states.isEmpty) return null;

    _currentIndex = (_currentIndex - frames).clamp(0, _states.length - 1);

    if (_currentIndex < _states.length - 1) {
      _states.removeRange(_currentIndex + 1, _states.length);
    }

    return _states.isNotEmpty ? _states[_currentIndex] : null;
  }

  void clear() {
    _states.clear();
    _currentIndex = -1;
  }
}
