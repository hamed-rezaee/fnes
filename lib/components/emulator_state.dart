import 'dart:convert';
import 'dart:typed_data';

class EmulatorState {
  EmulatorState({
    required this.cpuState,
    required this.ppuState,
    required this.apuState,
    required this.busState,
    required this.mapperState,
    required this.timestamp,
  });

  final CPUState cpuState;
  final PPUState ppuState;
  final APUState apuState;
  final BusState busState;
  final Map<String, dynamic> mapperState;
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
  final int oamAddress;
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
  RewindBuffer({this.maxFrames = 600});

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

extension EmulatorStateSerialization on EmulatorState {
  Map<String, dynamic> toJson() => {
        'cpuState': cpuState.toJson(),
        'ppuState': ppuState.toJson(),
        'apuState': apuState.toJson(),
        'busState': busState.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'mapperState': mapperState,
      };

  static EmulatorState fromJson(Map<String, dynamic> json) => EmulatorState(
        cpuState: CPUStateSerialization.fromJson(
          json['cpuState'] as Map<String, dynamic>,
        ),
        ppuState: PPUStateSerialization.fromJson(
          json['ppuState'] as Map<String, dynamic>,
        ),
        apuState: APUStateSerialization.fromJson(
          json['apuState'] as Map<String, dynamic>,
        ),
        busState: BusStateSerialization.fromJson(
          json['busState'] as Map<String, dynamic>,
        ),
        mapperState: (json['mapperState'] as Map<String, dynamic>?) ?? {},
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

extension CPUStateSerialization on CPUState {
  Map<String, dynamic> toJson() => {
        'a': a,
        'x': x,
        'y': y,
        'stkp': stkp,
        'pc': pc,
        'status': status,
        'fetched': fetched,
        'temp': temp,
        'addrAbs': addrAbs,
        'addrRel': addrRel,
        'opcode': opcode,
        'cycles': cycles,
        'clockCount': clockCount,
      };

  static CPUState fromJson(Map<String, dynamic> json) => CPUState(
        a: json['a'] as int,
        x: json['x'] as int,
        y: json['y'] as int,
        stkp: json['stkp'] as int,
        pc: json['pc'] as int,
        status: json['status'] as int,
        fetched: json['fetched'] as int,
        temp: json['temp'] as int,
        addrAbs: json['addrAbs'] as int,
        addrRel: json['addrRel'] as int,
        opcode: json['opcode'] as int,
        cycles: json['cycles'] as int,
        clockCount: json['clockCount'] as int,
      );
}

extension PPUStateSerialization on PPUState {
  Map<String, dynamic> toJson() => {
        'tableData': base64Encode(tableData),
        'paletteTable': base64Encode(paletteTable),
        'patternTable': base64Encode(patternTable),
        'statusReg': statusReg,
        'maskReg': maskReg,
        'controlReg': controlReg,
        'vramAddressReg': vramAddressReg,
        'tempAddressReg': tempAddressReg,
        'fineX': fineX,
        'addressLatch': addressLatch,
        'ppuDataBuffer': ppuDataBuffer,
        'oamAddress': oamAddress,
        'backgroundNextTileId': backgroundNextTileId,
        'backgroundNextTileAttrib': backgroundNextTileAttrib,
        'backgroundNextTileLsb': backgroundNextTileLsb,
        'backgroundNextTileMsb': backgroundNextTileMsb,
        'backgroundShifterPatternLow': backgroundShifterPatternLow,
        'backgroundShifterPatternHigh': backgroundShifterPatternHigh,
        'backgroundShifterAttribLow': backgroundShifterAttribLow,
        'backgroundShifterAttribHigh': backgroundShifterAttribHigh,
        'spriteShifterPatternLow': spriteShifterPatternLow,
        'spriteShifterPatternHigh': spriteShifterPatternHigh,
        'spriteCount': spriteCount,
        'spriteZeroHitPossible': spriteZeroHitPossible,
        'spriteZeroBeingRendered': spriteZeroBeingRendered,
        'scanline': scanline,
        'cycle': cycle,
        'frameCounter': frameCounter,
        'pOAM': base64Encode(pOAM),
        'screenPixels': screenPixels.map((row) => row).toList(),
        'nmi': nmi,
        'frameComplete': frameComplete,
        'spriteScanlineData':
            spriteScanlineData.map((e) => e.toJson()).toList(),
      };

  static PPUState fromJson(Map<String, dynamic> json) => PPUState(
        tableData:
            Uint8List.fromList(base64Decode(json['tableData'] as String)),
        paletteTable:
            Uint8List.fromList(base64Decode(json['paletteTable'] as String)),
        patternTable:
            Uint8List.fromList(base64Decode(json['patternTable'] as String)),
        statusReg: json['statusReg'] as int,
        maskReg: json['maskReg'] as int,
        controlReg: json['controlReg'] as int,
        vramAddressReg: json['vramAddressReg'] as int,
        tempAddressReg: json['tempAddressReg'] as int,
        fineX: json['fineX'] as int,
        addressLatch: json['addressLatch'] as int,
        ppuDataBuffer: json['ppuDataBuffer'] as int,
        oamAddress: (json['oamAddress'] as int?) ?? 0,
        backgroundNextTileId: json['backgroundNextTileId'] as int,
        backgroundNextTileAttrib: json['backgroundNextTileAttrib'] as int,
        backgroundNextTileLsb: json['backgroundNextTileLsb'] as int,
        backgroundNextTileMsb: json['backgroundNextTileMsb'] as int,
        backgroundShifterPatternLow: json['backgroundShifterPatternLow'] as int,
        backgroundShifterPatternHigh:
            json['backgroundShifterPatternHigh'] as int,
        backgroundShifterAttribLow: json['backgroundShifterAttribLow'] as int,
        backgroundShifterAttribHigh: json['backgroundShifterAttribHigh'] as int,
        spriteShifterPatternLow:
            (json['spriteShifterPatternLow'] as List).cast<int>(),
        spriteShifterPatternHigh:
            (json['spriteShifterPatternHigh'] as List).cast<int>(),
        spriteCount: json['spriteCount'] as int,
        spriteZeroHitPossible: json['spriteZeroHitPossible'] as bool,
        spriteZeroBeingRendered: json['spriteZeroBeingRendered'] as bool,
        scanline: json['scanline'] as int,
        cycle: json['cycle'] as int,
        frameCounter: json['frameCounter'] as int,
        pOAM: Uint8List.fromList(base64Decode(json['pOAM'] as String)),
        screenPixels: (json['screenPixels'] as List)
            .map((row) => (row as List).cast<int>())
            .toList(),
        nmi: json['nmi'] as bool,
        frameComplete: json['frameComplete'] as bool,
        spriteScanlineData: (json['spriteScanlineData'] as List)
            .map(
              (e) => SpriteScanlineEntrySerialization.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
}

extension SpriteScanlineEntrySerialization on SpriteScanlineEntry {
  Map<String, dynamic> toJson() => {
        'y': y,
        'id': id,
        'attribute': attribute,
        'x': x,
      };

  static SpriteScanlineEntry fromJson(Map<String, dynamic> json) =>
      SpriteScanlineEntry(
        y: json['y'] as int,
        id: json['id'] as int,
        attribute: json['attribute'] as int,
        x: json['x'] as int,
      );
}

extension APUStateSerialization on APUState {
  Map<String, dynamic> toJson() => {
        'globalTime': globalTime,
        'frameCounterMode': frameCounterMode,
        'irqDisable': irqDisable,
        'frameIrq': frameIrq,
        'frameStep': frameStep,
        'pulse1State': pulse1State.toJson(),
        'pulse2State': pulse2State.toJson(),
        'triangleState': triangleState.toJson(),
        'noiseState': noiseState.toJson(),
        'dmcState': dmcState.toJson(),
      };

  static APUState fromJson(Map<String, dynamic> json) => APUState(
        globalTime: json['globalTime'] as int,
        frameCounterMode: json['frameCounterMode'] as bool,
        irqDisable: json['irqDisable'] as bool,
        frameIrq: json['frameIrq'] as bool,
        frameStep: json['frameStep'] as int,
        pulse1State: PulseWaveStateSerialization.fromJson(
          json['pulse1State'] as Map<String, dynamic>,
        ),
        pulse2State: PulseWaveStateSerialization.fromJson(
          json['pulse2State'] as Map<String, dynamic>,
        ),
        triangleState: TriangleWaveStateSerialization.fromJson(
          json['triangleState'] as Map<String, dynamic>,
        ),
        noiseState: NoiseWaveStateSerialization.fromJson(
          json['noiseState'] as Map<String, dynamic>,
        ),
        dmcState: DMCStateSerialization.fromJson(
          json['dmcState'] as Map<String, dynamic>,
        ),
      );
}

extension PulseWaveStateSerialization on PulseWaveState {
  Map<String, dynamic> toJson() => {
        'enable': enable,
        'dutycycle': dutycycle,
        'timer': timer,
        'reload': reload,
        'phase': phase,
        'envelopeState': envelopeState.toJson(),
        'lengthCounterState': lengthCounterState.toJson(),
        'sweeperState': sweeperState.toJson(),
      };

  static PulseWaveState fromJson(Map<String, dynamic> json) => PulseWaveState(
        enable: json['enable'] as bool,
        dutycycle: (json['dutycycle'] as num).toDouble(),
        timer: json['timer'] as int,
        reload: json['reload'] as int,
        phase: json['phase'] as int,
        envelopeState: EnvelopeStateSerialization.fromJson(
          json['envelopeState'] as Map<String, dynamic>,
        ),
        lengthCounterState: LengthCounterStateSerialization.fromJson(
          json['lengthCounterState'] as Map<String, dynamic>,
        ),
        sweeperState: SweeperStateSerialization.fromJson(
          json['sweeperState'] as Map<String, dynamic>,
        ),
      );
}

extension TriangleWaveStateSerialization on TriangleWaveState {
  Map<String, dynamic> toJson() => {
        'enable': enable,
        'timer': timer,
        'reload': reload,
        'phase': phase,
        'lengthCounterState': lengthCounterState.toJson(),
        'linearCounterState': linearCounterState.toJson(),
      };

  static TriangleWaveState fromJson(Map<String, dynamic> json) =>
      TriangleWaveState(
        enable: json['enable'] as bool,
        timer: json['timer'] as int,
        reload: json['reload'] as int,
        phase: json['phase'] as int,
        lengthCounterState: LengthCounterStateSerialization.fromJson(
          json['lengthCounterState'] as Map<String, dynamic>,
        ),
        linearCounterState: LinearCounterStateSerialization.fromJson(
          json['linearCounterState'] as Map<String, dynamic>,
        ),
      );
}

extension NoiseWaveStateSerialization on NoiseWaveState {
  Map<String, dynamic> toJson() => {
        'enable': enable,
        'mode': mode,
        'timer': timer,
        'reload': reload,
        'shiftRegister': shiftRegister,
        'envelopeState': envelopeState.toJson(),
        'lengthCounterState': lengthCounterState.toJson(),
      };

  static NoiseWaveState fromJson(Map<String, dynamic> json) => NoiseWaveState(
        enable: json['enable'] as bool,
        mode: json['mode'] as bool,
        timer: json['timer'] as int,
        reload: json['reload'] as int,
        shiftRegister: json['shiftRegister'] as int,
        envelopeState: EnvelopeStateSerialization.fromJson(
          json['envelopeState'] as Map<String, dynamic>,
        ),
        lengthCounterState: LengthCounterStateSerialization.fromJson(
          json['lengthCounterState'] as Map<String, dynamic>,
        ),
      );
}

extension DMCStateSerialization on DMCState {
  Map<String, dynamic> toJson() => {
        'enable': enable,
        'irqEnabled': irqEnabled,
        'loop': loop,
        'timerLoad': timerLoad,
        'timer': timer,
        'dmcOutput': dmcOutput,
        'sampleAddress': sampleAddress,
        'currentAddress': currentAddress,
        'bytesRemaining': bytesRemaining,
        'sampleBuffer': sampleBuffer,
        'sampleBufferEmpty': sampleBufferEmpty,
        'shiftRegister': shiftRegister,
        'bitsRemaining': bitsRemaining,
        'silenceFlag': silenceFlag,
      };

  static DMCState fromJson(Map<String, dynamic> json) => DMCState(
        enable: json['enable'] as bool,
        irqEnabled: json['irqEnabled'] as bool,
        loop: json['loop'] as bool,
        timerLoad: json['timerLoad'] as int,
        timer: json['timer'] as int,
        dmcOutput: json['dmcOutput'] as int,
        sampleAddress: json['sampleAddress'] as int,
        currentAddress: json['currentAddress'] as int,
        bytesRemaining: json['bytesRemaining'] as int,
        sampleBuffer: json['sampleBuffer'] as int,
        sampleBufferEmpty: json['sampleBufferEmpty'] as bool,
        shiftRegister: json['shiftRegister'] as int,
        bitsRemaining: json['bitsRemaining'] as int,
        silenceFlag: json['silenceFlag'] as bool,
      );
}

extension EnvelopeStateSerialization on EnvelopeState {
  Map<String, dynamic> toJson() => {
        'start': start,
        'disable': disable,
        'dividerCount': dividerCount,
        'volume': volume,
        'output': output,
        'decayCount': decayCount,
        'loop': loop,
      };

  static EnvelopeState fromJson(Map<String, dynamic> json) => EnvelopeState(
        start: json['start'] as bool,
        disable: json['disable'] as bool,
        dividerCount: json['dividerCount'] as int,
        volume: json['volume'] as int,
        output: json['output'] as int,
        decayCount: json['decayCount'] as int,
        loop: json['loop'] as bool,
      );
}

extension LengthCounterStateSerialization on LengthCounterState {
  Map<String, dynamic> toJson() => {
        'counter': counter,
        'halt': halt,
      };

  static LengthCounterState fromJson(Map<String, dynamic> json) =>
      LengthCounterState(
        counter: json['counter'] as int,
        halt: json['halt'] as bool,
      );
}

extension SweeperStateSerialization on SweeperState {
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'down': down,
        'reload': reload,
        'shift': shift,
        'timer': timer,
        'period': period,
        'mute': mute,
      };

  static SweeperState fromJson(Map<String, dynamic> json) => SweeperState(
        enabled: json['enabled'] as bool,
        down: json['down'] as bool,
        reload: json['reload'] as bool,
        shift: json['shift'] as int,
        timer: json['timer'] as int,
        period: json['period'] as int,
        mute: json['mute'] as bool,
      );
}

extension LinearCounterStateSerialization on LinearCounterState {
  Map<String, dynamic> toJson() => {
        'counter': counter,
        'reload': reload,
        'controlFlag': controlFlag,
        'reloadFlag': reloadFlag,
      };

  static LinearCounterState fromJson(Map<String, dynamic> json) =>
      LinearCounterState(
        counter: json['counter'] as int,
        reload: json['reload'] as int,
        controlFlag: json['controlFlag'] as bool,
        reloadFlag: json['reloadFlag'] as bool,
      );
}

extension BusStateSerialization on BusState {
  Map<String, dynamic> toJson() => {
        'cpuRam': base64Encode(cpuRam),
        'controller': controller,
        'controllerState': controllerState,
        'systemClockCounter': systemClockCounter,
        'dmaPage': dmaPage,
        'dmaAddress': dmaAddress,
        'dmaData': dmaData,
        'dmaDummy': dmaDummy,
        'dmaTransfer': dmaTransfer,
      };

  static BusState fromJson(Map<String, dynamic> json) => BusState(
        cpuRam: Uint8List.fromList(base64Decode(json['cpuRam'] as String)),
        controller: (json['controller'] as List).cast<int>(),
        controllerState: (json['controllerState'] as List).cast<int>(),
        systemClockCounter: json['systemClockCounter'] as int,
        dmaPage: json['dmaPage'] as int,
        dmaAddress: json['dmaAddress'] as int,
        dmaData: json['dmaData'] as int,
        dmaDummy: json['dmaDummy'] as bool,
        dmaTransfer: json['dmaTransfer'] as bool,
      );
}
