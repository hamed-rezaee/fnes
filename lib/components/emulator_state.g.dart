// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emulator_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmulatorState _$EmulatorStateFromJson(Map<String, dynamic> json) =>
    EmulatorState(
      cpuState: CPUState.fromJson(json['cpuState'] as Map<String, dynamic>),
      ppuState: PPUState.fromJson(json['ppuState'] as Map<String, dynamic>),
      apuState: APUState.fromJson(json['apuState'] as Map<String, dynamic>),
      busState: BusState.fromJson(json['busState'] as Map<String, dynamic>),
      mapperState: json['mapperState'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$EmulatorStateToJson(EmulatorState instance) =>
    <String, dynamic>{
      'cpuState': instance.cpuState.toJson(),
      'ppuState': instance.ppuState.toJson(),
      'apuState': instance.apuState.toJson(),
      'busState': instance.busState.toJson(),
      'mapperState': instance.mapperState,
      'timestamp': instance.timestamp.toIso8601String(),
    };

CPUState _$CPUStateFromJson(Map<String, dynamic> json) => CPUState(
  a: (json['a'] as num).toInt(),
  x: (json['x'] as num).toInt(),
  y: (json['y'] as num).toInt(),
  stkp: (json['stkp'] as num).toInt(),
  pc: (json['pc'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  fetched: (json['fetched'] as num).toInt(),
  temp: (json['temp'] as num).toInt(),
  addrAbs: (json['addrAbs'] as num).toInt(),
  addrRel: (json['addrRel'] as num).toInt(),
  opcode: (json['opcode'] as num).toInt(),
  cycles: (json['cycles'] as num).toInt(),
  clockCount: (json['clockCount'] as num).toInt(),
);

Map<String, dynamic> _$CPUStateToJson(CPUState instance) => <String, dynamic>{
  'a': instance.a,
  'x': instance.x,
  'y': instance.y,
  'stkp': instance.stkp,
  'pc': instance.pc,
  'status': instance.status,
  'fetched': instance.fetched,
  'temp': instance.temp,
  'addrAbs': instance.addrAbs,
  'addrRel': instance.addrRel,
  'opcode': instance.opcode,
  'cycles': instance.cycles,
  'clockCount': instance.clockCount,
};

PPUState _$PPUStateFromJson(Map<String, dynamic> json) => PPUState(
  tableData: const Uint8ListConverter().fromJson(json['tableData'] as String),
  paletteTable: const Uint8ListConverter().fromJson(
    json['paletteTable'] as String,
  ),
  patternTable: const Uint8ListConverter().fromJson(
    json['patternTable'] as String,
  ),
  statusReg: (json['statusReg'] as num).toInt(),
  maskReg: (json['maskReg'] as num).toInt(),
  controlReg: (json['controlReg'] as num).toInt(),
  vramAddressReg: (json['vramAddressReg'] as num).toInt(),
  tempAddressReg: (json['tempAddressReg'] as num).toInt(),
  fineX: (json['fineX'] as num).toInt(),
  addressLatch: (json['addressLatch'] as num).toInt(),
  ppuDataBuffer: (json['ppuDataBuffer'] as num).toInt(),
  oamAddress: (json['oamAddress'] as num).toInt(),
  backgroundNextTileId: (json['backgroundNextTileId'] as num).toInt(),
  backgroundNextTileAttrib: (json['backgroundNextTileAttrib'] as num).toInt(),
  backgroundNextTileLsb: (json['backgroundNextTileLsb'] as num).toInt(),
  backgroundNextTileMsb: (json['backgroundNextTileMsb'] as num).toInt(),
  backgroundShifterPatternLow: (json['backgroundShifterPatternLow'] as num)
      .toInt(),
  backgroundShifterPatternHigh: (json['backgroundShifterPatternHigh'] as num)
      .toInt(),
  backgroundShifterAttribLow: (json['backgroundShifterAttribLow'] as num)
      .toInt(),
  backgroundShifterAttribHigh: (json['backgroundShifterAttribHigh'] as num)
      .toInt(),
  spriteShifterPatternLow: const Uint8ListDirectConverter().fromJson(
    json['spriteShifterPatternLow'] as List,
  ),
  spriteShifterPatternHigh: const Uint8ListDirectConverter().fromJson(
    json['spriteShifterPatternHigh'] as List,
  ),
  spriteCount: (json['spriteCount'] as num).toInt(),
  spriteZeroHitPossible: json['spriteZeroHitPossible'] as bool,
  spriteZeroBeingRendered: json['spriteZeroBeingRendered'] as bool,
  scanline: (json['scanline'] as num).toInt(),
  cycle: (json['cycle'] as num).toInt(),
  frameCounter: (json['frameCounter'] as num).toInt(),
  pOAM: const Uint8ListConverter().fromJson(json['pOAM'] as String),
  screenPixels: const Uint8ListConverter().fromJson(
    json['screenPixels'] as String,
  ),
  nmi: json['nmi'] as bool,
  frameComplete: json['frameComplete'] as bool,
  spriteScanlineData: (json['spriteScanlineData'] as List<dynamic>)
      .map((e) => SpriteScanlineEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PPUStateToJson(PPUState instance) => <String, dynamic>{
  'tableData': const Uint8ListConverter().toJson(instance.tableData),
  'paletteTable': const Uint8ListConverter().toJson(instance.paletteTable),
  'patternTable': const Uint8ListConverter().toJson(instance.patternTable),
  'statusReg': instance.statusReg,
  'maskReg': instance.maskReg,
  'controlReg': instance.controlReg,
  'vramAddressReg': instance.vramAddressReg,
  'tempAddressReg': instance.tempAddressReg,
  'fineX': instance.fineX,
  'addressLatch': instance.addressLatch,
  'ppuDataBuffer': instance.ppuDataBuffer,
  'oamAddress': instance.oamAddress,
  'backgroundNextTileId': instance.backgroundNextTileId,
  'backgroundNextTileAttrib': instance.backgroundNextTileAttrib,
  'backgroundNextTileLsb': instance.backgroundNextTileLsb,
  'backgroundNextTileMsb': instance.backgroundNextTileMsb,
  'backgroundShifterPatternLow': instance.backgroundShifterPatternLow,
  'backgroundShifterPatternHigh': instance.backgroundShifterPatternHigh,
  'backgroundShifterAttribLow': instance.backgroundShifterAttribLow,
  'backgroundShifterAttribHigh': instance.backgroundShifterAttribHigh,
  'spriteShifterPatternLow': const Uint8ListDirectConverter().toJson(
    instance.spriteShifterPatternLow,
  ),
  'spriteShifterPatternHigh': const Uint8ListDirectConverter().toJson(
    instance.spriteShifterPatternHigh,
  ),
  'spriteCount': instance.spriteCount,
  'spriteZeroHitPossible': instance.spriteZeroHitPossible,
  'spriteZeroBeingRendered': instance.spriteZeroBeingRendered,
  'scanline': instance.scanline,
  'cycle': instance.cycle,
  'frameCounter': instance.frameCounter,
  'pOAM': const Uint8ListConverter().toJson(instance.pOAM),
  'screenPixels': const Uint8ListConverter().toJson(instance.screenPixels),
  'nmi': instance.nmi,
  'frameComplete': instance.frameComplete,
  'spriteScanlineData': instance.spriteScanlineData
      .map((e) => e.toJson())
      .toList(),
};

SpriteScanlineEntry _$SpriteScanlineEntryFromJson(Map<String, dynamic> json) =>
    SpriteScanlineEntry(
      y: (json['y'] as num).toInt(),
      id: (json['id'] as num).toInt(),
      attribute: (json['attribute'] as num).toInt(),
      x: (json['x'] as num).toInt(),
    );

Map<String, dynamic> _$SpriteScanlineEntryToJson(
  SpriteScanlineEntry instance,
) => <String, dynamic>{
  'y': instance.y,
  'id': instance.id,
  'attribute': instance.attribute,
  'x': instance.x,
};

APUState _$APUStateFromJson(Map<String, dynamic> json) => APUState(
  globalTime: (json['globalTime'] as num).toInt(),
  frameCounterMode: json['frameCounterMode'] as bool,
  irqDisable: json['irqDisable'] as bool,
  frameIrq: json['frameIrq'] as bool,
  frameStep: (json['frameStep'] as num).toInt(),
  pulse1State: PulseWaveState.fromJson(
    json['pulse1State'] as Map<String, dynamic>,
  ),
  pulse2State: PulseWaveState.fromJson(
    json['pulse2State'] as Map<String, dynamic>,
  ),
  triangleState: TriangleWaveState.fromJson(
    json['triangleState'] as Map<String, dynamic>,
  ),
  noiseState: NoiseWaveState.fromJson(
    json['noiseState'] as Map<String, dynamic>,
  ),
  dmcState: DMCState.fromJson(json['dmcState'] as Map<String, dynamic>),
);

Map<String, dynamic> _$APUStateToJson(APUState instance) => <String, dynamic>{
  'globalTime': instance.globalTime,
  'frameCounterMode': instance.frameCounterMode,
  'irqDisable': instance.irqDisable,
  'frameIrq': instance.frameIrq,
  'frameStep': instance.frameStep,
  'pulse1State': instance.pulse1State.toJson(),
  'pulse2State': instance.pulse2State.toJson(),
  'triangleState': instance.triangleState.toJson(),
  'noiseState': instance.noiseState.toJson(),
  'dmcState': instance.dmcState.toJson(),
};

PulseWaveState _$PulseWaveStateFromJson(Map<String, dynamic> json) =>
    PulseWaveState(
      enable: json['enable'] as bool,
      dutycycle: (json['dutycycle'] as num).toDouble(),
      timer: (json['timer'] as num).toInt(),
      reload: (json['reload'] as num).toInt(),
      phase: (json['phase'] as num).toInt(),
      envelopeState: EnvelopeState.fromJson(
        json['envelopeState'] as Map<String, dynamic>,
      ),
      lengthCounterState: LengthCounterState.fromJson(
        json['lengthCounterState'] as Map<String, dynamic>,
      ),
      sweeperState: SweeperState.fromJson(
        json['sweeperState'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PulseWaveStateToJson(PulseWaveState instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'dutycycle': instance.dutycycle,
      'timer': instance.timer,
      'reload': instance.reload,
      'phase': instance.phase,
      'envelopeState': instance.envelopeState.toJson(),
      'lengthCounterState': instance.lengthCounterState.toJson(),
      'sweeperState': instance.sweeperState.toJson(),
    };

TriangleWaveState _$TriangleWaveStateFromJson(Map<String, dynamic> json) =>
    TriangleWaveState(
      enable: json['enable'] as bool,
      timer: (json['timer'] as num).toInt(),
      reload: (json['reload'] as num).toInt(),
      phase: (json['phase'] as num).toInt(),
      lengthCounterState: LengthCounterState.fromJson(
        json['lengthCounterState'] as Map<String, dynamic>,
      ),
      linearCounterState: LinearCounterState.fromJson(
        json['linearCounterState'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$TriangleWaveStateToJson(TriangleWaveState instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'timer': instance.timer,
      'reload': instance.reload,
      'phase': instance.phase,
      'lengthCounterState': instance.lengthCounterState.toJson(),
      'linearCounterState': instance.linearCounterState.toJson(),
    };

NoiseWaveState _$NoiseWaveStateFromJson(Map<String, dynamic> json) =>
    NoiseWaveState(
      enable: json['enable'] as bool,
      mode: json['mode'] as bool,
      timer: (json['timer'] as num).toInt(),
      reload: (json['reload'] as num).toInt(),
      shiftRegister: (json['shiftRegister'] as num).toInt(),
      envelopeState: EnvelopeState.fromJson(
        json['envelopeState'] as Map<String, dynamic>,
      ),
      lengthCounterState: LengthCounterState.fromJson(
        json['lengthCounterState'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$NoiseWaveStateToJson(NoiseWaveState instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'mode': instance.mode,
      'timer': instance.timer,
      'reload': instance.reload,
      'shiftRegister': instance.shiftRegister,
      'envelopeState': instance.envelopeState.toJson(),
      'lengthCounterState': instance.lengthCounterState.toJson(),
    };

DMCState _$DMCStateFromJson(Map<String, dynamic> json) => DMCState(
  enable: json['enable'] as bool,
  irqEnabled: json['irqEnabled'] as bool,
  loop: json['loop'] as bool,
  timerLoad: (json['timerLoad'] as num).toInt(),
  timer: (json['timer'] as num).toInt(),
  dmcOutput: (json['dmcOutput'] as num).toInt(),
  sampleAddress: (json['sampleAddress'] as num).toInt(),
  currentAddress: (json['currentAddress'] as num).toInt(),
  bytesRemaining: (json['bytesRemaining'] as num).toInt(),
  sampleBuffer: (json['sampleBuffer'] as num).toInt(),
  sampleBufferEmpty: json['sampleBufferEmpty'] as bool,
  shiftRegister: (json['shiftRegister'] as num).toInt(),
  bitsRemaining: (json['bitsRemaining'] as num).toInt(),
  silenceFlag: json['silenceFlag'] as bool,
);

Map<String, dynamic> _$DMCStateToJson(DMCState instance) => <String, dynamic>{
  'enable': instance.enable,
  'irqEnabled': instance.irqEnabled,
  'loop': instance.loop,
  'timerLoad': instance.timerLoad,
  'timer': instance.timer,
  'dmcOutput': instance.dmcOutput,
  'sampleAddress': instance.sampleAddress,
  'currentAddress': instance.currentAddress,
  'bytesRemaining': instance.bytesRemaining,
  'sampleBuffer': instance.sampleBuffer,
  'sampleBufferEmpty': instance.sampleBufferEmpty,
  'shiftRegister': instance.shiftRegister,
  'bitsRemaining': instance.bitsRemaining,
  'silenceFlag': instance.silenceFlag,
};

EnvelopeState _$EnvelopeStateFromJson(Map<String, dynamic> json) =>
    EnvelopeState(
      start: json['start'] as bool,
      disable: json['disable'] as bool,
      dividerCount: (json['dividerCount'] as num).toInt(),
      volume: (json['volume'] as num).toInt(),
      output: (json['output'] as num).toInt(),
      decayCount: (json['decayCount'] as num).toInt(),
      loop: json['loop'] as bool,
    );

Map<String, dynamic> _$EnvelopeStateToJson(EnvelopeState instance) =>
    <String, dynamic>{
      'start': instance.start,
      'disable': instance.disable,
      'dividerCount': instance.dividerCount,
      'volume': instance.volume,
      'output': instance.output,
      'decayCount': instance.decayCount,
      'loop': instance.loop,
    };

LengthCounterState _$LengthCounterStateFromJson(Map<String, dynamic> json) =>
    LengthCounterState(
      counter: (json['counter'] as num).toInt(),
      halt: json['halt'] as bool,
    );

Map<String, dynamic> _$LengthCounterStateToJson(LengthCounterState instance) =>
    <String, dynamic>{'counter': instance.counter, 'halt': instance.halt};

SweeperState _$SweeperStateFromJson(Map<String, dynamic> json) => SweeperState(
  enabled: json['enabled'] as bool,
  down: json['down'] as bool,
  reload: json['reload'] as bool,
  shift: (json['shift'] as num).toInt(),
  timer: (json['timer'] as num).toInt(),
  period: (json['period'] as num).toInt(),
  mute: json['mute'] as bool,
);

Map<String, dynamic> _$SweeperStateToJson(SweeperState instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'down': instance.down,
      'reload': instance.reload,
      'shift': instance.shift,
      'timer': instance.timer,
      'period': instance.period,
      'mute': instance.mute,
    };

LinearCounterState _$LinearCounterStateFromJson(Map<String, dynamic> json) =>
    LinearCounterState(
      counter: (json['counter'] as num).toInt(),
      reload: (json['reload'] as num).toInt(),
      controlFlag: json['controlFlag'] as bool,
      reloadFlag: json['reloadFlag'] as bool,
    );

Map<String, dynamic> _$LinearCounterStateToJson(LinearCounterState instance) =>
    <String, dynamic>{
      'counter': instance.counter,
      'reload': instance.reload,
      'controlFlag': instance.controlFlag,
      'reloadFlag': instance.reloadFlag,
    };

BusState _$BusStateFromJson(Map<String, dynamic> json) => BusState(
  cpuRam: const Uint8ListConverter().fromJson(json['cpuRam'] as String),
  controller: const Uint8ListDirectConverter().fromJson(
    json['controller'] as List,
  ),
  controllerState: const Uint8ListDirectConverter().fromJson(
    json['controllerState'] as List,
  ),
  systemClockCounter: (json['systemClockCounter'] as num).toInt(),
  dmaPage: (json['dmaPage'] as num).toInt(),
  dmaAddress: (json['dmaAddress'] as num).toInt(),
  dmaData: (json['dmaData'] as num).toInt(),
  dmaDummy: json['dmaDummy'] as bool,
  dmaTransfer: json['dmaTransfer'] as bool,
  zapperEnabled: json['zapperEnabled'] as bool,
  zapperTriggerPressed: json['zapperTriggerPressed'] as bool,
  zapperPointerOnScreen: json['zapperPointerOnScreen'] as bool,
  zapperX: (json['zapperX'] as num).toDouble(),
  zapperY: (json['zapperY'] as num).toDouble(),
);

Map<String, dynamic> _$BusStateToJson(BusState instance) => <String, dynamic>{
  'cpuRam': const Uint8ListConverter().toJson(instance.cpuRam),
  'controller': const Uint8ListDirectConverter().toJson(instance.controller),
  'controllerState': const Uint8ListDirectConverter().toJson(
    instance.controllerState,
  ),
  'systemClockCounter': instance.systemClockCounter,
  'dmaPage': instance.dmaPage,
  'dmaAddress': instance.dmaAddress,
  'dmaData': instance.dmaData,
  'dmaDummy': instance.dmaDummy,
  'dmaTransfer': instance.dmaTransfer,
  'zapperEnabled': instance.zapperEnabled,
  'zapperTriggerPressed': instance.zapperTriggerPressed,
  'zapperPointerOnScreen': instance.zapperPointerOnScreen,
  'zapperX': instance.zapperX,
  'zapperY': instance.zapperY,
};
