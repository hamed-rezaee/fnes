import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'emulator_state.g.dart';

@JsonSerializable()
class EmulatorState {
  EmulatorState({
    required this.cpuState,
    required this.ppuState,
    required this.apuState,
    required this.busState,
    required this.mapperState,
    required this.timestamp,
  });

  factory EmulatorState.fromJson(Map<String, dynamic> json) =>
      _$EmulatorStateFromJson(json);

  final CPUState cpuState;
  final PPUState ppuState;
  final APUState apuState;
  final BusState busState;
  final Map<String, dynamic> mapperState;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => _$EmulatorStateToJson(this);
}

@JsonSerializable()
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

  factory CPUState.fromJson(Map<String, dynamic> json) =>
      _$CPUStateFromJson(json);

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

  Map<String, dynamic> toJson() => _$CPUStateToJson(this);
}

@JsonSerializable()
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
    required this.oamAddress,
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

  factory PPUState.fromJson(Map<String, dynamic> json) =>
      _$PPUStateFromJson(json);

  @Uint8ListConverter()
  final Uint8List tableData;
  @Uint8ListConverter()
  final Uint8List paletteTable;
  @Uint8ListConverter()
  final Uint8List patternTable;
  final int statusReg;
  final int maskReg;
  final int controlReg;
  final int vramAddressReg;
  final int tempAddressReg;
  final int fineX;
  final int addressLatch;
  final int ppuDataBuffer;
  final int oamAddress;
  final int backgroundNextTileId;
  final int backgroundNextTileAttrib;
  final int backgroundNextTileLsb;
  final int backgroundNextTileMsb;
  final int backgroundShifterPatternLow;
  final int backgroundShifterPatternHigh;
  final int backgroundShifterAttribLow;
  final int backgroundShifterAttribHigh;
  @Uint8ListDirectConverter()
  final Uint8List spriteShifterPatternLow;
  @Uint8ListDirectConverter()
  final Uint8List spriteShifterPatternHigh;
  final int spriteCount;
  final bool spriteZeroHitPossible;
  final bool spriteZeroBeingRendered;
  final int scanline;
  final int cycle;
  final int frameCounter;
  @Uint8ListConverter()
  final Uint8List pOAM;
  @Uint8ListConverter()
  final Uint8List screenPixels;
  final bool nmi;
  final bool frameComplete;
  final List<SpriteScanlineEntry> spriteScanlineData;

  Map<String, dynamic> toJson() => _$PPUStateToJson(this);
}

@JsonSerializable()
class SpriteScanlineEntry {
  SpriteScanlineEntry({
    required this.y,
    required this.id,
    required this.attribute,
    required this.x,
  });

  factory SpriteScanlineEntry.fromJson(Map<String, dynamic> json) =>
      _$SpriteScanlineEntryFromJson(json);

  final int y;
  final int id;
  final int attribute;
  final int x;

  Map<String, dynamic> toJson() => _$SpriteScanlineEntryToJson(this);
}

@JsonSerializable()
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

  factory APUState.fromJson(Map<String, dynamic> json) =>
      _$APUStateFromJson(json);

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

  Map<String, dynamic> toJson() => _$APUStateToJson(this);
}

@JsonSerializable()
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

  factory PulseWaveState.fromJson(Map<String, dynamic> json) =>
      _$PulseWaveStateFromJson(json);

  final bool enable;
  final double dutycycle;
  final int timer;
  final int reload;
  final int phase;
  final EnvelopeState envelopeState;
  final LengthCounterState lengthCounterState;
  final SweeperState sweeperState;

  Map<String, dynamic> toJson() => _$PulseWaveStateToJson(this);
}

@JsonSerializable()
class TriangleWaveState {
  TriangleWaveState({
    required this.enable,
    required this.timer,
    required this.reload,
    required this.phase,
    required this.lengthCounterState,
    required this.linearCounterState,
  });

  factory TriangleWaveState.fromJson(Map<String, dynamic> json) =>
      _$TriangleWaveStateFromJson(json);

  final bool enable;
  final int timer;
  final int reload;
  final int phase;
  final LengthCounterState lengthCounterState;
  final LinearCounterState linearCounterState;

  Map<String, dynamic> toJson() => _$TriangleWaveStateToJson(this);
}

@JsonSerializable()
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

  factory NoiseWaveState.fromJson(Map<String, dynamic> json) =>
      _$NoiseWaveStateFromJson(json);

  final bool enable;
  final bool mode;
  final int timer;
  final int reload;
  final int shiftRegister;
  final EnvelopeState envelopeState;
  final LengthCounterState lengthCounterState;

  Map<String, dynamic> toJson() => _$NoiseWaveStateToJson(this);
}

@JsonSerializable()
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

  factory DMCState.fromJson(Map<String, dynamic> json) =>
      _$DMCStateFromJson(json);

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

  Map<String, dynamic> toJson() => _$DMCStateToJson(this);
}

@JsonSerializable()
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

  factory EnvelopeState.fromJson(Map<String, dynamic> json) =>
      _$EnvelopeStateFromJson(json);

  final bool start;
  final bool disable;
  final int dividerCount;
  final int volume;
  final int output;
  final int decayCount;
  final bool loop;

  Map<String, dynamic> toJson() => _$EnvelopeStateToJson(this);
}

@JsonSerializable()
class LengthCounterState {
  LengthCounterState({
    required this.counter,
    required this.halt,
  });

  factory LengthCounterState.fromJson(Map<String, dynamic> json) =>
      _$LengthCounterStateFromJson(json);

  final int counter;
  final bool halt;

  Map<String, dynamic> toJson() => _$LengthCounterStateToJson(this);
}

@JsonSerializable()
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

  factory SweeperState.fromJson(Map<String, dynamic> json) =>
      _$SweeperStateFromJson(json);

  final bool enabled;
  final bool down;
  final bool reload;
  final int shift;
  final int timer;
  final int period;
  final bool mute;

  Map<String, dynamic> toJson() => _$SweeperStateToJson(this);
}

@JsonSerializable()
class LinearCounterState {
  LinearCounterState({
    required this.counter,
    required this.reload,
    required this.controlFlag,
    required this.reloadFlag,
  });

  factory LinearCounterState.fromJson(Map<String, dynamic> json) =>
      _$LinearCounterStateFromJson(json);

  final int counter;
  final int reload;
  final bool controlFlag;
  final bool reloadFlag;

  Map<String, dynamic> toJson() => _$LinearCounterStateToJson(this);
}

@JsonSerializable()
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

  factory BusState.fromJson(Map<String, dynamic> json) =>
      _$BusStateFromJson(json);

  @Uint8ListConverter()
  final Uint8List cpuRam;
  @Uint8ListDirectConverter()
  final Uint8List controller;
  @Uint8ListDirectConverter()
  final Uint8List controllerState;
  final int systemClockCounter;
  final int dmaPage;
  final int dmaAddress;
  final int dmaData;
  final bool dmaDummy;
  final bool dmaTransfer;

  Map<String, dynamic> toJson() => _$BusStateToJson(this);
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
    _states.add(state);

    final excess = _states.length - maxFrames;

    if (excess > 0) _states.removeRange(0, excess);

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

// Custom converters for types that json_serializable doesn't handle by default
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => Uint8List.fromList(base64Decode(json));

  @override
  String toJson(Uint8List object) => base64Encode(object);
}

class Uint8ListDirectConverter
    implements JsonConverter<Uint8List, List<dynamic>> {
  const Uint8ListDirectConverter();

  @override
  Uint8List fromJson(List<dynamic> json) =>
      Uint8List.fromList(json.cast<int>());

  @override
  List<int> toJson(Uint8List object) => object;
}
